import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';

Future<void> showScratchpad(
  BuildContext context, {
  ScratchInkController? controller,
  double initialStrokeWidth = 2.8,
  ValueChanged<double>? onStrokeWidthChanged,
}) {
  final window = GaussWindowClass.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: window.isCompact
        ? null
        : BoxConstraints(maxWidth: window.isWide ? 960 : 820),
    builder: (context) => _ScratchpadSheet(
      controller: controller,
      initialStrokeWidth: initialStrokeWidth,
      onStrokeWidthChanged: onStrokeWidthChanged,
    ),
  );
}

/// Android sends an explicit signal when a pointer was rejected as a palm.
///
/// Flutter's regular [PointerCancelEvent] remains the first line of defense.
/// The channel covers Android 13+ `FLAG_CANCELED` pointer-up events as well,
/// allowing a just-finished touch stroke to be rolled back without affecting a
/// simultaneous Focus Pen stroke.
class ScratchStylusSignals {
  ScratchStylusSignals._();

  static const _channel = MethodChannel('com.gauss.app/stylus_input');
  static final ValueNotifier<PalmRejectionSignal?> palmRejections =
      ValueNotifier<PalmRejectionSignal?>(null);
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'palmRejected') {
        final arguments = call.arguments;
        if (arguments is! Map) return;
        final pointerId = arguments['pointerId'];
        final eventTime = arguments['eventTime'];
        if (pointerId is! num || eventTime is! num) return;
        palmRejections.value = PalmRejectionSignal(
          androidPointerId: pointerId.toInt(),
          eventTimeMillis: eventTime.toInt(),
        );
      }
    });
  }

  @visibleForTesting
  static void debugSimulatePalmRejection({
    int androidPointerId = 1,
    int? eventTimeMillis,
  }) {
    palmRejections.value = PalmRejectionSignal(
      androidPointerId: androidPointerId,
      eventTimeMillis: eventTimeMillis,
    );
  }
}

@immutable
class PalmRejectionSignal {
  const PalmRejectionSignal({
    required this.androidPointerId,
    required this.eventTimeMillis,
  });

  /// AndroidTouchProcessor maps MotionEvent.pointerId to PointerEvent.device.
  final int androidPointerId;

  /// Android MotionEvent eventTime, using the uptime-millisecond time base.
  final int? eventTimeMillis;
}

/// The deliberate finger-input mode for a question manuscript.
///
/// Hardware stylus input remains available in every mode. [pan] leaves touch
/// to scrolling and answer controls, [pen] lets a finger write, and [eraser]
/// removes the nearest complete ink gesture without raster smudging.
enum QuestionInkMode { pan, pen, eraser }

/// A non-destructive ink layer that sits directly on a question plate.
///
/// A hardware stylus writes immediately without enabling a mode, so the
/// learner's other hand can keep scrolling. Finger/mouse drawing is an
/// explicit mode. Ink remains session-local and never mutates the source
/// corpus or learner progress.
class InlineQuestionScratch extends StatefulWidget {
  const InlineQuestionScratch({
    required this.child,
    this.active = true,
    this.showInlineControls = true,
    this.onDrawingChanged,
    this.controller,
    this.inputMode = QuestionInkMode.pan,
    super.key,
  });

  final Widget child;

  /// False for off-screen PageView children. It guarantees that a question
  /// never keeps intercepting gestures after the learner moves away.
  final bool active;
  final bool showInlineControls;
  final ValueChanged<bool>? onDrawingChanged;

  /// Optional for deterministic tests or a future persisted working layer.
  /// When omitted, this widget owns a session-local controller.
  final ScratchInkController? controller;
  final QuestionInkMode inputMode;

  @override
  State<InlineQuestionScratch> createState() => _InlineQuestionScratchState();
}

class _InlineQuestionScratchState extends State<InlineQuestionScratch> {
  late ScratchInkController _ink;
  late bool _ownsInk;
  bool _pointerContact = false;
  bool _reportedGestureOwnership = false;
  double _strokeWidth = _PenWidth.medium.width;
  Timer? _clearHistoryTimer;

  @override
  void initState() {
    super.initState();
    _adoptController();
  }

  void _adoptController() {
    _ownsInk = widget.controller == null;
    _ink = widget.controller ?? ScratchInkController();
  }

  @override
  void didUpdateWidget(covariant InlineQuestionScratch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final hadPendingClear = _clearHistoryTimer != null;
      _clearHistoryTimer?.cancel();
      _clearHistoryTimer = null;
      final previousInk = _ink;
      final disposePrevious = _ownsInk;
      if (hadPendingClear && !disposePrevious) {
        previousInk.discardLastClear();
      }
      _adoptController();
      if (disposePrevious) {
        // The child input surface must cancel its old live session before the
        // parent-owned controller is disposed.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          previousInk.dispose();
        });
      }
    }
    if (!widget.active && _pointerContact) {
      _pointerContact = false;
      _reportGestureOwnership();
    }
  }

  void _setPointerContact(bool contact) {
    if (_pointerContact == contact) return;
    setState(() => _pointerContact = contact);
    _reportGestureOwnership();
  }

  void _reportGestureOwnership() {
    final ownsGesture = widget.active && _pointerContact;
    if (_reportedGestureOwnership == ownsGesture) return;
    _reportedGestureOwnership = ownsGesture;
    widget.onDrawingChanged?.call(ownsGesture);
  }

  void _setStrokeWidth(double value) {
    if (_strokeWidth == value || !mounted) return;
    setState(() => _strokeWidth = value);
  }

  void _expandInkWorkspace() {
    showScratchpad(
      context,
      controller: _ink,
      initialStrokeWidth: _strokeWidth,
      onStrokeWidthChanged: _setStrokeWidth,
    );
  }

  void _clearInlineInk() {
    if (_ink.isEmpty) return;
    _ink.clear();
    _clearHistoryTimer?.cancel();
    _clearHistoryTimer = Timer(const Duration(seconds: 4), () {
      _clearHistoryTimer = null;
      if (mounted) _ink.discardLastClear();
    });
  }

  void _restoreInlineInk() {
    _clearHistoryTimer?.cancel();
    _clearHistoryTimer = null;
    _ink.restoreLastClear();
  }

  @override
  void dispose() {
    final hadPendingClear = _clearHistoryTimer != null;
    _clearHistoryTimer?.cancel();
    _clearHistoryTimer = null;
    if (hadPendingClear && !_ownsInk) {
      _ink.discardLastClear();
    }
    if (_reportedGestureOwnership) widget.onDrawingChanged?.call(false);
    if (_ownsInk) _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ink,
    builder: (context, _) {
      final hasInk = !_ink.isEmpty;
      final canRestoreClear = _ink.canRestoreClearedInk;
      final inkSurface = ClipRect(
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label:
              'Question ink surface. A stylus writes directly; touch remains available for scrolling and answers.',
          child: _ScratchInputSurface(
            ink: _ink,
            baseWidth: _strokeWidth,
            allowTouch: widget.inputMode != QuestionInkMode.pan,
            erase: widget.inputMode == QuestionInkMode.eraser,
            active: widget.active,
            onContactChanged: _setPointerContact,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey('inline-ink-canvas'),
                      painter: _ScratchPainter(ink: _ink, drawGrid: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!widget.showInlineControls) return inkSurface;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          inkSurface,
          AnimatedSwitcher(
            duration: GaussMotion.resolve(context, GaussMotion.standard),
            reverseDuration: GaussMotion.resolve(context, GaussMotion.micro),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: AlignmentDirectional.topCenter,
                child: child,
              ),
            ),
            child: hasInk || canRestoreClear
                ? Padding(
                    key: const ValueKey('inline-pen-halo-slot'),
                    padding: const EdgeInsets.only(top: GaussSpacing.space8),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: canRestoreClear
                          ? _ClearInkUndoHalo(onRestore: _restoreInlineInk)
                          : _PenHalo(
                              ink: _ink,
                              strokeWidth: _strokeWidth,
                              onStrokeWidthChanged: _setStrokeWidth,
                              onExpand: _expandInkWorkspace,
                              onClear: _clearInlineInk,
                            ),
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey('inline-pen-halo-hidden'),
                  ),
          ),
        ],
      );
    },
  );
}

class _PenHalo extends StatelessWidget {
  const _PenHalo({
    required this.ink,
    required this.strokeWidth,
    required this.onStrokeWidthChanged,
    required this.onExpand,
    required this.onClear,
  });

  final ScratchInkController ink;
  final double strokeWidth;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onExpand;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final actionStyle = IconButton.styleFrom(
      foregroundColor: GaussColors.ivory,
      disabledForegroundColor: GaussColors.muted.withValues(alpha: .45),
      minimumSize: const Size.square(GaussMetrics.minTouchTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Pen controls',
      child: Container(
        key: const ValueKey('inline-pen-halo'),
        constraints: const BoxConstraints(
          minHeight: GaussMetrics.minTouchTarget,
        ),
        decoration: BoxDecoration(
          color: GaussColors.deepInk.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(GaussRadii.pill),
          border: Border.all(
            color: GaussColors.brassLight.withValues(alpha: .42),
          ),
          boxShadow: [
            BoxShadow(
              color: GaussColors.deepInk.withValues(alpha: .28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: GaussSpacing.space4),
        child: Wrap(
          alignment: WrapAlignment.end,
          runAlignment: WrapAlignment.center,
          children: [
            Tooltip(
              message: 'Undo last stroke',
              child: Semantics(
                label: 'Undo last stroke',
                button: true,
                enabled: ink.canUndo,
                child: IconButton(
                  key: const ValueKey('inline-ink-undo'),
                  onPressed: ink.canUndo ? ink.undo : null,
                  style: actionStyle,
                  icon: const Icon(Icons.undo_rounded),
                ),
              ),
            ),
            _PenWidthMenu(
              color: GaussColors.brassLight,
              value: strokeWidth,
              onSelected: onStrokeWidthChanged,
            ),
            Tooltip(
              message: 'Expand ink workspace',
              child: Semantics(
                label: 'Expand ink workspace',
                button: true,
                child: IconButton(
                  key: const ValueKey('inline-ink-expand'),
                  onPressed: onExpand,
                  style: actionStyle,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
              ),
            ),
            Tooltip(
              message: 'Clear question ink',
              child: Semantics(
                label: 'Clear question ink',
                button: true,
                enabled: !ink.isEmpty,
                child: IconButton(
                  key: const ValueKey('inline-ink-clear'),
                  onPressed: ink.isEmpty ? null : onClear,
                  style: actionStyle.copyWith(
                    foregroundColor: const WidgetStatePropertyAll(
                      GaussColors.error,
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearInkUndoHalo extends StatelessWidget {
  const _ClearInkUndoHalo({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: 'Question ink cleared',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: GaussColors.deepInk.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        border: Border.all(
          color: GaussColors.brassLight.withValues(alpha: .42),
        ),
        boxShadow: [
          BoxShadow(
            color: GaussColors.deepInk.withValues(alpha: .24),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextButton.icon(
        key: const ValueKey('inline-ink-restore'),
        onPressed: onRestore,
        style: TextButton.styleFrom(
          foregroundColor: GaussColors.ivory,
          minimumSize: const Size(
            GaussMetrics.minTouchTarget,
            GaussMetrics.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GaussSpacing.space16,
            vertical: GaussSpacing.space8,
          ),
        ),
        icon: const Icon(Icons.undo_rounded, color: GaussColors.brassLight),
        label: const Text('Restore ink'),
      ),
    ),
  );
}

class _ScratchpadSheet extends StatefulWidget {
  const _ScratchpadSheet({
    this.controller,
    required this.initialStrokeWidth,
    this.onStrokeWidthChanged,
  });

  final ScratchInkController? controller;
  final double initialStrokeWidth;
  final ValueChanged<double>? onStrokeWidthChanged;

  @override
  State<_ScratchpadSheet> createState() => _ScratchpadSheetState();
}

class _ScratchpadSheetState extends State<_ScratchpadSheet> {
  late final ScratchInkController _ink;
  late final bool _ownsInk;
  late double _strokeWidth;

  @override
  void initState() {
    super.initState();
    _ownsInk = widget.controller == null;
    _ink = widget.controller ?? ScratchInkController();
    _strokeWidth = widget.initialStrokeWidth;
  }

  void _setStrokeWidth(double value) {
    if (_strokeWidth == value) return;
    setState(() => _strokeWidth = value);
    widget.onStrokeWidthChanged?.call(value);
  }

  void _clearInk() {
    _ink.clear();
  }

  @override
  void dispose() {
    if (_ownsInk) _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final window = GaussWindowClass.of(context);
    return FractionallySizedBox(
      widthFactor: 1,
      heightFactor: window.isCompact ? .9 : .84,
      child: Material(
        key: const ValueKey('scratchpad-sheet'),
        color: GaussColors.ink,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _ink,
              builder: (context, _) => LayoutBuilder(
                builder: (context, constraints) {
                  final reflow =
                      constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(14) > 19;
                  final widthMenu = _PenWidthMenu(
                    color: GaussColors.brassLight,
                    value: _strokeWidth,
                    onSelected: _setStrokeWidth,
                  );
                  final undoLabel = _ink.canRestoreClearedInk
                      ? 'Restore cleared ink'
                      : 'Undo last stroke';
                  final undo = IconButton(
                    onPressed: _ink.canUndo ? _ink.undo : null,
                    tooltip: undoLabel,
                    icon: const Icon(Icons.undo_rounded),
                  );
                  final clear = IconButton(
                    onPressed: _ink.isEmpty ? null : _clearInk,
                    tooltip: 'Clear scratchpad',
                    color: GaussColors.error,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  );
                  final close = IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close scratchpad',
                    icon: const Icon(Icons.close),
                  );
                  final title = Expanded(
                    child: Text(
                      'Scratchpad',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );

                  return Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      12,
                      8,
                      10,
                    ),
                    child: reflow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_note,
                                    color: GaussColors.brassLight,
                                  ),
                                  const SizedBox(width: GaussSpacing.space8),
                                  title,
                                  close,
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [widthMenu, undo, clear],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.edit_note,
                                color: GaussColors.brassLight,
                              ),
                              const SizedBox(width: GaussSpacing.space8),
                              title,
                              widthMenu,
                              undo,
                              clear,
                              close,
                            ],
                          ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GaussColors.parchment,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: _ScratchInputSurface(
                    ink: _ink,
                    baseWidth: _strokeWidth,
                    allowTouch: true,
                    erase: false,
                    child: CustomPaint(
                      key: const ValueKey('scratchpad-ink-canvas'),
                      painter: _ScratchPainter(ink: _ink, drawGrid: true),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                kIsWeb
                    ? 'Pen pressure is used when the browser reports it. Touch and mouse drawing remain available on this dedicated sheet.'
                    : defaultTargetPlatform == TargetPlatform.android
                    ? 'Android stylus events provide pressure and palm-rejection signals when the device reports them. Touch drawing is available only in this expanded workspace.'
                    : 'Stylus pressure is supported when the platform reports it. Touch and mouse drawing remain available.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: GaussColors.muted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PenWidth {
  fine(1.8, 'Fine'),
  medium(2.8, 'Medium'),
  bold(4.2, 'Bold');

  const _PenWidth(this.width, this.label);
  final double width;
  final String label;
}

class _PenWidthMenu extends StatelessWidget {
  const _PenWidthMenu({
    required this.color,
    required this.value,
    required this.onSelected,
  });

  final Color color;
  final double value;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Pen thickness',
    child: Semantics(
      label: 'Pen thickness',
      button: true,
      child: SizedBox.square(
        dimension: GaussMetrics.minTouchTarget,
        child: PopupMenuButton<double>(
          tooltip: null,
          initialValue: value,
          onSelected: onSelected,
          icon: Icon(Icons.line_weight_rounded, color: color, size: 20),
          itemBuilder: (context) => [
            for (final width in _PenWidth.values)
              PopupMenuItem<double>(
                value: width.width,
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Divider(
                        color: GaussColors.brassLight,
                        thickness: width.width,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(width.label),
                    const Spacer(),
                    if (value == width.width)
                      const Icon(Icons.check_rounded, size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ScratchInputSurface extends StatefulWidget {
  const _ScratchInputSurface({
    required this.ink,
    required this.baseWidth,
    required this.allowTouch,
    required this.erase,
    required this.child,
    this.active = true,
    this.onContactChanged,
  });

  final ScratchInkController ink;
  final double baseWidth;
  final bool allowTouch;
  final bool erase;
  final bool active;
  final ValueChanged<bool>? onContactChanged;
  final Widget child;

  @override
  State<_ScratchInputSurface> createState() => _ScratchInputSurfaceState();
}

class _ScratchInputSurfaceState extends State<_ScratchInputSurface> {
  final GlobalKey _surfaceKey = GlobalKey();
  late _ScratchInputSession _session;

  @override
  void initState() {
    super.initState();
    _session = _ScratchInputSession(widget.ink);
    ScratchStylusSignals.ensureInitialized();
    ScratchStylusSignals.palmRejections.addListener(_rejectPalm);
  }

  @override
  void didUpdateWidget(covariant _ScratchInputSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ink != widget.ink) {
      _session.cancel();
      _session = _ScratchInputSession(widget.ink);
    }
    if (!widget.active && _session.cancel()) {
      widget.onContactChanged?.call(false);
    }
  }

  @override
  void dispose() {
    ScratchStylusSignals.palmRejections.removeListener(_rejectPalm);
    _session.cancel();
    super.dispose();
  }

  void _rejectPalm() {
    if (!widget.active) return;
    final signal = ScratchStylusSignals.palmRejections.value;
    if (signal == null) return;
    final contactEnded = _session.rejectPalm(signal);
    if (contactEnded) widget.onContactChanged?.call(false);
  }

  Size get _surfaceSize {
    final renderObject = _surfaceKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.size;
    }
    return const Size(1, 1);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.active) return;
    final result = _session.begin(
      event,
      _surfaceSize,
      widget.baseWidth,
      allowTouch: widget.allowTouch,
      erase: widget.erase,
    );
    switch (result) {
      case _ScratchBeginResult.accepted:
        widget.onContactChanged?.call(true);
      case _ScratchBeginResult.canceledActive:
        widget.onContactChanged?.call(false);
      case _ScratchBeginResult.ignored:
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _session.extend(event, _surfaceSize, widget.baseWidth, erase: widget.erase);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_session.end(event)) widget.onContactChanged?.call(false);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_session.cancel(event.pointer)) widget.onContactChanged?.call(false);
  }

  bool _shouldClaimPointer(PointerDownEvent event) {
    if (!widget.active) return false;
    if (_ScratchInputSession._isStylus(event.kind)) return true;
    if (widget.allowTouch &&
        (event.kind == PointerDeviceKind.touch ||
            event.kind == PointerDeviceKind.mouse ||
            event.kind == PointerDeviceKind.unknown)) {
      return true;
    }
    // A palm that lands after the pen must not enter the parent scroll/page
    // arena. It is claimed here, while the input session below deliberately
    // ignores it so the live stylus stroke remains the sole ink owner.
    return _session.hasActiveStylus && event.kind == PointerDeviceKind.touch;
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _ScratchGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_ScratchGestureRecognizer>(
              () => _ScratchGestureRecognizer(shouldClaim: _shouldClaimPointer),
              (recognizer) => recognizer.shouldClaim = _shouldClaimPointer,
            ),
      },
      child: Listener(
        key: _surfaceKey,
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: widget.child,
      ),
    );
  }
}

/// Claims only pointers that belong to ink, plus palm contacts that arrive
/// while a stylus is already down. Unlike a pan recognizer this wins on
/// pointer-down, so the first pen point is both visible and gesture-owned
/// immediately while ordinary finger scrolling stays untouched.
class _ScratchGestureRecognizer extends OneSequenceGestureRecognizer {
  _ScratchGestureRecognizer({required this.shouldClaim});

  bool Function(PointerDownEvent event) shouldClaim;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(
      shouldClaim(event)
          ? GestureDisposition.accepted
          : GestureDisposition.rejected,
    );
    stopTrackingPointer(event.pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {}

  @override
  String get debugDescription => 'scratch input claim';
}

class _ScratchInputSession {
  _ScratchInputSession(this.ink);

  final ScratchInkController ink;
  int? _activePointer;
  int? _activeAndroidPointerId;
  int? _activeGesture;
  PointerDeviceKind? _activeKind;
  double? _smoothedWidth;
  int? _recentTouchAndroidPointerId;
  int? _recentTouchGesture;
  int? _recentTouchEventTimeMillis;
  bool _erasing = false;

  bool get hasActiveStylus => _activePointer != null && _isStylus(_activeKind!);

  _ScratchBeginResult begin(
    PointerDownEvent event,
    Size size,
    double baseWidth, {
    required bool allowTouch,
    required bool erase,
  }) {
    final stylus = _isStylus(event.kind);
    final accepted =
        stylus ||
        (allowTouch &&
            (event.kind == PointerDeviceKind.touch ||
                event.kind == PointerDeviceKind.mouse ||
                event.kind == PointerDeviceKind.unknown));
    if (!accepted) return _ScratchBeginResult.ignored;

    if (_activePointer != null) {
      if (_activeKind == PointerDeviceKind.touch && stylus) {
        ink.cancelActive();
        _reset();
      } else {
        if (_activeKind == PointerDeviceKind.touch &&
            event.kind == PointerDeviceKind.touch) {
          ink.cancelActive();
          _reset();
          return _ScratchBeginResult.canceledActive;
        }
        return _ScratchBeginResult.ignored;
      }
    }

    _activePointer = event.pointer;
    _activeAndroidPointerId = event.device;
    _activeKind = event.kind;
    _smoothedWidth = _effectiveWidth(event, baseWidth);
    if (erase) {
      _erasing = true;
      ink.eraseNearest(event.localPosition, size);
      return _ScratchBeginResult.accepted;
    }
    _activeGesture = ink.begin(
      event.localPosition,
      size,
      _smoothedWidth!,
      kind: event.kind,
    );
    if (_activeGesture == null) {
      _reset();
      return _ScratchBeginResult.ignored;
    }
    return _ScratchBeginResult.accepted;
  }

  void extend(
    PointerMoveEvent event,
    Size size,
    double baseWidth, {
    required bool erase,
  }) {
    if (event.pointer != _activePointer) return;
    if (_erasing || erase) {
      ink.eraseNearest(event.localPosition, size);
      return;
    }
    final target = _effectiveWidth(event, baseWidth);
    _smoothedWidth = _smoothedWidth == null
        ? target
        : (_smoothedWidth! * .58) + (target * .42);
    ink.extend(event.localPosition, size, _smoothedWidth!);
  }

  bool end(PointerUpEvent event) {
    if (event.pointer != _activePointer) return false;
    if (_activeKind == PointerDeviceKind.touch) {
      _recentTouchAndroidPointerId = event.device;
      _recentTouchGesture = _activeGesture;
      _recentTouchEventTimeMillis = event.timeStamp.inMilliseconds;
    }
    if (!_erasing) ink.end();
    _reset();
    return true;
  }

  bool cancel([int? pointer]) {
    if (_activePointer == null ||
        (pointer != null && pointer != _activePointer)) {
      return false;
    }
    if (!_erasing) ink.cancelActive();
    _reset();
    return true;
  }

  bool rejectPalm(PalmRejectionSignal signal) {
    if (_activeKind == PointerDeviceKind.touch &&
        _activeAndroidPointerId == signal.androidPointerId) {
      return cancel();
    }
    if (_recentTouchAndroidPointerId == signal.androidPointerId &&
        _recentTouchGesture != null &&
        _eventTimesMatch(_recentTouchEventTimeMillis, signal.eventTimeMillis)) {
      ink.removeGesture(_recentTouchGesture!);
      _recentTouchAndroidPointerId = null;
      _recentTouchGesture = null;
      _recentTouchEventTimeMillis = null;
    }
    return false;
  }

  void _reset() {
    _activePointer = null;
    _activeAndroidPointerId = null;
    _activeGesture = null;
    _activeKind = null;
    _smoothedWidth = null;
    _erasing = false;
  }

  static bool _eventTimesMatch(int? flutterMillis, int? androidMillis) {
    if (androidMillis == null) return true;
    if (flutterMillis == null) return false;
    return (flutterMillis - androidMillis).abs() <= 250;
  }

  static bool _isStylus(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  static double _effectiveWidth(PointerEvent event, double baseWidth) {
    const minInkWidth = .8;
    const maxInkWidth = 7.0;
    final boundedBaseWidth = baseWidth.isFinite
        ? baseWidth.clamp(minInkWidth, maxInkWidth).toDouble()
        : _PenWidth.medium.width;
    if (!_isStylus(event.kind) ||
        !event.pressure.isFinite ||
        !event.pressureMin.isFinite ||
        !event.pressureMax.isFinite ||
        event.pressureMax - event.pressureMin <= .0001) {
      return boundedBaseWidth;
    }
    final pressure =
        ((event.pressure - event.pressureMin) /
                (event.pressureMax - event.pressureMin))
            .clamp(0.0, 1.0);
    final response = .52 + math.pow(pressure, .68) * 1.02;
    return (boundedBaseWidth * response)
        .clamp(minInkWidth, maxInkWidth)
        .toDouble();
  }
}

enum _ScratchBeginResult { ignored, accepted, canceledActive }

/// Session-local ink history with stroke-level rollback for palm rejection.
class ScratchInkController extends ChangeNotifier {
  static const _maxRetainedPoints = 12000;
  static const _maxPointsPerStroke = 2000;

  final List<_InkStroke> _strokes = [];
  final List<_InkStroke> _activeGestureStrokes = [];
  _InkStroke? _activeStroke;
  int _pointCount = 0;
  int _nextGesture = 0;
  int _committedRevision = 0;
  List<_InkStroke>? _clearedStrokes;
  int? _clearedNextGesture;

  bool get isEmpty => _strokes.isEmpty;
  bool get canUndo => _strokes.isNotEmpty || canRestoreClearedInk;
  bool get canRestoreClearedInk => _strokes.isEmpty && _clearedStrokes != null;

  @visibleForTesting
  int get strokeCount =>
      _strokes.map((stroke) => stroke.gesture).toSet().length;

  @visibleForTesting
  List<double> get recordedWidths => [
    for (final stroke in _strokes)
      for (final point in stroke.points) point.width,
  ];

  int? begin(
    Offset point,
    Size size,
    double width, {
    required PointerDeviceKind kind,
  }) {
    if (!_drawable(size)) return null;
    _discardClearHistory();
    final stroke = _InkStroke(kind: kind, gesture: _nextGesture++)
      ..points.add(_InkPoint(_normalize(point, size), width));
    _strokes.add(stroke);
    _activeGestureStrokes
      ..clear()
      ..add(stroke);
    _activeStroke = stroke;
    _pointCount++;
    notifyListeners();
    return stroke.gesture;
  }

  void extend(Offset point, Size size, double width) {
    if (!_drawable(size)) return;
    var stroke = _activeStroke;
    if (stroke == null) return;
    final normalized = _normalize(point, size);
    final last = stroke.points.last;
    final dx = (normalized.dx - last.position.dx) * size.width;
    final dy = (normalized.dy - last.position.dy) * size.height;
    if ((dx * dx) + (dy * dy) < .16 && (width - last.width).abs() < .04) {
      return;
    }
    if (stroke.points.length >= _maxPointsPerStroke) {
      stroke = _InkStroke(kind: stroke.kind, gesture: stroke.gesture)
        ..points.add(last);
      _strokes.add(stroke);
      _activeGestureStrokes.add(stroke);
      _activeStroke = stroke;
      _pointCount++;
    }
    stroke.points.add(_InkPoint(normalized, width));
    _pointCount++;
    while (_pointCount > _maxRetainedPoints && _strokes.length > 1) {
      final removed = _strokes.removeAt(0);
      _activeGestureStrokes.remove(removed);
      _pointCount -= removed.points.length;
      _committedRevision++;
    }
    notifyListeners();
  }

  void end() {
    final now = DateTime.now();
    for (final stroke in _activeGestureStrokes) {
      stroke.committedAt = now;
    }
    _activeStroke = null;
    _activeGestureStrokes.clear();
    _committedRevision++;
  }

  void cancelActive() {
    if (_activeGestureStrokes.isEmpty) return;
    for (final stroke in _activeGestureStrokes) {
      if (_strokes.remove(stroke)) _pointCount -= stroke.points.length;
    }
    _activeStroke = null;
    _activeGestureStrokes.clear();
    notifyListeners();
  }

  bool removeGesture(int gesture) {
    final removed = _strokes
        .where((stroke) => stroke.gesture == gesture)
        .toList(growable: false);
    if (removed.isEmpty) return false;
    for (final stroke in removed) {
      _strokes.remove(stroke);
      _activeGestureStrokes.remove(stroke);
      _pointCount -= stroke.points.length;
    }
    if (_activeStroke?.gesture == gesture) _activeStroke = null;
    _committedRevision++;
    notifyListeners();
    return true;
  }

  /// Erases the nearest whole gesture within a touch-friendly logical radius.
  /// Whole-stroke erasure keeps vector ink deterministic and fully undoable.
  bool eraseNearest(Offset point, Size size, {double radius = 22}) {
    if (!_drawable(size) || _strokes.isEmpty) return false;
    int? nearestGesture;
    var nearestDistanceSquared = radius * radius;
    for (final stroke in _strokes) {
      for (final inkPoint in stroke.points) {
        final dx = inkPoint.position.dx * size.width - point.dx;
        final dy = inkPoint.position.dy * size.height - point.dy;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared <= nearestDistanceSquared) {
          nearestDistanceSquared = distanceSquared;
          nearestGesture = stroke.gesture;
        }
      }
    }
    return nearestGesture != null && removeGesture(nearestGesture);
  }

  void undo() {
    if (_strokes.isEmpty) {
      restoreLastClear();
      return;
    }
    removeGesture(_strokes.last.gesture);
  }

  void clear() {
    if (_strokes.isEmpty) return;
    _clearedStrokes = _strokes.map(_cloneStroke).toList(growable: false);
    _clearedNextGesture = _nextGesture;
    _strokes.clear();
    _activeStroke = null;
    _activeGestureStrokes.clear();
    _pointCount = 0;
    _committedRevision++;
    notifyListeners();
  }

  bool restoreLastClear() {
    final cleared = _clearedStrokes;
    if (_strokes.isNotEmpty || cleared == null) return false;
    _strokes.addAll(cleared.map(_cloneStroke));
    _pointCount = _strokes.fold<int>(
      0,
      (total, stroke) => total + stroke.points.length,
    );
    _nextGesture = math.max(_nextGesture, _clearedNextGesture ?? _nextGesture);
    _discardClearHistory();
    _committedRevision++;
    notifyListeners();
    return true;
  }

  void discardLastClear() {
    if (_clearedStrokes == null) return;
    _discardClearHistory();
    notifyListeners();
  }

  void _discardClearHistory() {
    _clearedStrokes = null;
    _clearedNextGesture = null;
  }

  static _InkStroke _cloneStroke(_InkStroke source) =>
      _InkStroke(kind: source.kind, gesture: source.gesture)
        ..points.addAll(source.points)
        ..committedAt = source.committedAt;

  static bool _drawable(Size size) => size.width > 0 && size.height > 0;

  static Offset _normalize(Offset point, Size size) => Offset(
    (point.dx / size.width).clamp(0, 1),
    (point.dy / size.height).clamp(0, 1),
  );
}

class _InkStroke {
  _InkStroke({required this.kind, required this.gesture});

  final PointerDeviceKind kind;
  final int gesture;
  final List<_InkPoint> points = [];
  DateTime? committedAt;
}

class _InkPoint {
  const _InkPoint(this.position, this.width);

  final Offset position;
  final double width;
}

class _ScratchPainter extends CustomPainter {
  _ScratchPainter({required this.ink, required this.drawGrid})
    : super(repaint: ink);

  final ScratchInkController ink;
  final bool drawGrid;
  ui.Picture? _committedPicture;
  Size? _committedSize;
  int _pictureRevision = -1;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawGrid) {
      final grid = Paint()
        ..color = const Color(0xFFBCA778).withValues(alpha: .22)
        ..strokeWidth = .7;
      for (var x = 24.0; x < size.width; x += 24) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var y = 24.0; y < size.height; y += 24) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    if (_pictureRevision != ink._committedRevision || _committedSize != size) {
      _committedPicture?.dispose();
      final recorder = ui.PictureRecorder();
      final committedCanvas = Canvas(recorder);
      _drawStrokes(
        committedCanvas,
        size,
        ink._strokes.where((stroke) => stroke.committedAt != null),
      );
      _committedPicture = recorder.endRecording();
      _committedSize = size;
      _pictureRevision = ink._committedRevision;
    }
    final picture = _committedPicture;
    if (picture != null) canvas.drawPicture(picture);
    _drawStrokes(
      canvas,
      size,
      ink._strokes.where((stroke) => stroke.committedAt == null),
    );
  }

  static void _drawStrokes(
    Canvas canvas,
    Size size,
    Iterable<_InkStroke> strokes,
  ) {
    final inkPaint = Paint()
      ..color = GaussColors.parchmentInk
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final first = stroke.points.first;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          _denormalize(first.position, size),
          first.width / 2,
          Paint()
            ..color = GaussColors.parchmentInk
            ..isAntiAlias = true,
        );
        continue;
      }
      for (var index = 1; index < stroke.points.length; index++) {
        final before = stroke.points[index - 1];
        final current = stroke.points[index];
        inkPaint.strokeWidth = (before.width + current.width) / 2;
        canvas.drawLine(
          _denormalize(before.position, size),
          _denormalize(current.position, size),
          inkPaint,
        );
      }
    }
  }

  static Offset _denormalize(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.drawGrid != drawGrid;
}
