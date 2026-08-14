import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/question_reference.dart';
import 'feedback_controller.dart';
import 'feedback_models.dart';
import 'feedback_repository.dart';

typedef GaussFeedbackScreenshotProvider =
    Future<GaussFeedbackScreenshot> Function();

/// Target-owned adaptation of `flutter.private-feedback-capture` 1.2.2.
///
/// Unlike the canonical component, Gauss intentionally exposes no export or
/// share path. Reports remain a bounded local-first outbox until authenticated
/// Supabase sync is connected and explicitly verified.
class GaussFeedbackCapture extends StatefulWidget {
  const GaussFeedbackCapture({
    required this.controller,
    required this.routeName,
    required this.child,
    this.navigatorKey,
    this.screenshotProvider,
    super.key,
  });

  final GaussFeedbackController controller;
  final String Function() routeName;
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GaussFeedbackScreenshotProvider? screenshotProvider;

  /// Captures the app surface under the caller without the floating lens.
  ///
  /// Returns null in isolated widget tests or host surfaces that are not
  /// wrapped by [GaussFeedbackCapture].
  static Future<GaussFeedbackScreenshot?> captureFrom(
    BuildContext context,
  ) async {
    final state = context.findAncestorStateOfType<_GaussFeedbackCaptureState>();
    return state?.captureScreenshot();
  }

  @override
  State<GaussFeedbackCapture> createState() => _GaussFeedbackCaptureState();
}

class _GaussFeedbackCaptureState extends State<GaussFeedbackCapture> {
  final GlobalKey _captureBoundaryKey = GlobalKey();
  Offset? _position;
  bool _capturing = false;
  bool _feedbackFlowActive = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      const extent = 52.0;
      final fallback = Offset(
        constraints.maxWidth - extent - 12 - media.padding.right,
        constraints.maxHeight * .42,
      );
      final position = _clampPosition(
        _position ?? fallback,
        constraints.biggest,
        media.padding,
        extent,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(key: _captureBoundaryKey, child: widget.child),
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              if (!widget.controller.initialized ||
                  !widget.controller.enabled ||
                  _capturing ||
                  _feedbackFlowActive) {
                return const SizedBox.shrink();
              }
              return Positioned(
                key: const ValueKey('feedback-capture-position'),
                left: position.dx,
                top: position.dy,
                width: extent,
                height: extent,
                child: Semantics(
                  button: true,
                  label: 'Open private feedback capture',
                  hint: 'Drag to move this control',
                  child: GestureDetector(
                    onPanUpdate: (details) => setState(() {
                      _position = _clampPosition(
                        position + details.delta,
                        constraints.biggest,
                        media.padding,
                        extent,
                      );
                    }),
                    child: Material(
                      key: const ValueKey('feedback-capture-action'),
                      color: GaussColors.deepInk.withValues(alpha: .94),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: GaussColors.signalBright.withValues(
                            alpha: .68,
                          ),
                        ),
                      ),
                      elevation: 10,
                      shadowColor: GaussColors.signal.withValues(alpha: .5),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.controller.busy ? null : _openCapture,
                        child: const Center(
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: GaussColors.signalBright,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );

  Future<void> _openCapture() async {
    if (_feedbackFlowActive) return;
    setState(() => _feedbackFlowActive = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final action = await _FeedbackCaptureMenu.show(_sheetContext);
      if (!mounted || action == null) return;
      if (action == _FeedbackCaptureAction.review) {
        await GaussFeedbackEntriesSheet.show(_sheetContext, widget.controller);
        return;
      }

      GaussFeedbackScreenshot? screenshot;
      if (action == _FeedbackCaptureAction.screenshot) {
        try {
          // The modal future completes when pop begins. Wait until its
          // reverse transition has actually left the capture boundary so the
          // feedback UI can never photograph itself on Android.
          final dismissDelay = GaussMotion.resolve(
            context,
            const Duration(milliseconds: 360),
          );
          if (dismissDelay > Duration.zero) {
            await Future<void>.delayed(dismissDelay);
          }
          if (!mounted) return;
          await WidgetsBinding.instance.endOfFrame;
          screenshot = await captureScreenshot();
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The preview could not be captured. Nothing was saved.',
              ),
            ),
          );
          return;
        }
      }
      if (!mounted) return;
      await GaussFeedbackComposer.show(
        _sheetContext,
        controller: widget.controller,
        route: widget.routeName(),
        screenshot: screenshot,
      );
    } finally {
      if (mounted) setState(() => _feedbackFlowActive = false);
    }
  }

  BuildContext get _sheetContext =>
      widget.navigatorKey?.currentState?.overlay?.context ?? context;

  Future<GaussFeedbackScreenshot> captureScreenshot() async {
    if (_capturing) throw StateError('A feedback capture is already running.');
    final ratio = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(1.0, GaussFeedbackRepository.maxScreenshotPixelRatio).toDouble();
    setState(() => _capturing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final provided = widget.screenshotProvider;
      if (provided != null) return provided();
      final boundary = _captureBoundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('The feedback capture surface is unavailable.');
      }
      final image = await boundary.toImage(pixelRatio: ratio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Screenshot encoding failed.');
        return GaussFeedbackScreenshot(
          bytes: Uint8List.fromList(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
          pixelRatio: ratio,
        );
      } finally {
        image.dispose();
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Offset _clampPosition(
    Offset value,
    Size size,
    EdgeInsets padding,
    double extent,
  ) {
    final minX = padding.left + 8;
    final maxX = size.width - extent - padding.right - 8;
    final minY = padding.top + 8;
    final maxY = size.height - extent - padding.bottom - 8;
    return Offset(
      _clampAxis(value.dx, minX, maxX, size.width - extent),
      _clampAxis(value.dy, minY, maxY, size.height - extent),
    );
  }

  double _clampAxis(
    double value,
    double minimum,
    double maximum,
    double available,
  ) {
    if (maximum < minimum) return available > 0 ? available / 2 : 0;
    return value.clamp(minimum, maximum).toDouble();
  }
}

enum _FeedbackCaptureAction { screenshot, note, review }

class _FeedbackCaptureMenu extends StatelessWidget {
  const _FeedbackCaptureMenu();

  static Future<_FeedbackCaptureAction?> show(BuildContext context) =>
      showModalBottomSheet<_FeedbackCaptureAction>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _FeedbackCaptureMenu(),
      );

  @override
  Widget build(BuildContext context) => _FeedbackSheetFrame(
    key: const ValueKey('feedback-capture-menu'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeedbackSheetHeading(
          eyebrow: 'PRIVATE FEEDBACK LENS',
          title: 'Mark what needs attention',
          detail:
              'Saved on this device as a private outbox. Nothing is shared or uploaded.',
        ),
        const SizedBox(height: 18),
        _FeedbackOrbitAction(
          key: const ValueKey('feedback-screenshot-action'),
          icon: Icons.center_focus_strong_rounded,
          title: 'Capture this surface',
          detail: 'Preview the exact screen, then add a note.',
          onTap: () =>
              Navigator.pop(context, _FeedbackCaptureAction.screenshot),
        ),
        _FeedbackOrbitAction(
          key: const ValueKey('feedback-note-action'),
          icon: Icons.edit_note_rounded,
          title: 'Add a note only',
          detail: 'Record an error, idea, criticism, or observation.',
          onTap: () => Navigator.pop(context, _FeedbackCaptureAction.note),
        ),
        _FeedbackOrbitAction(
          key: const ValueKey('feedback-review-action'),
          icon: Icons.inbox_outlined,
          title: 'Review the outbox',
          detail: 'Inspect or remove reports kept on this device.',
          onTap: () => Navigator.pop(context, _FeedbackCaptureAction.review),
        ),
      ],
    ),
  );
}

class GaussFeedbackComposer extends StatefulWidget {
  const GaussFeedbackComposer({
    required this.controller,
    required this.route,
    this.screenshot,
    super.key,
  });

  final GaussFeedbackController controller;
  final String route;
  final GaussFeedbackScreenshot? screenshot;

  static Future<bool> show(
    BuildContext context, {
    required GaussFeedbackController controller,
    required String route,
    GaussFeedbackScreenshot? screenshot,
  }) async =>
      (await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GaussFeedbackComposer(
          controller: controller,
          route: route,
          screenshot: screenshot,
        ),
      )) ??
      false;

  @override
  State<GaussFeedbackComposer> createState() => _GaussFeedbackComposerState();
}

class _GaussFeedbackComposerState extends State<GaussFeedbackComposer> {
  final _note = TextEditingController();
  var _kind = GaussFeedbackKind.error;
  GaussFeedbackScreenshot? _screenshot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _screenshot = widget.screenshot;
    _note.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _note
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || (_note.text.trim().isEmpty && _screenshot == null)) return;
    setState(() => _saving = true);
    try {
      await widget.controller.addEntry(
        route: widget.route,
        note: _note.text,
        kind: _kind,
        screenshot: _screenshot,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Private feedback saved to the outbox.'),
          action: SnackBarAction(
            label: 'Review',
            onPressed: () =>
                GaussFeedbackEntriesSheet.show(context, widget.controller),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The feedback could not be saved. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return _FeedbackSheetFrame(
      key: const ValueKey('feedback-composer-sheet'),
      bottomPadding: 20 + keyboard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedbackSheetHeading(
            eyebrow: 'CAPTURE NOTE',
            title: 'Leave a precise signal',
            detail:
                'Common credentials in typed text are redacted before storage.',
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in GaussFeedbackKind.values)
                if (kind != GaussFeedbackKind.questionIssue)
                  ChoiceChip(
                    key: ValueKey('feedback-kind-${kind.name}'),
                    label: Text(kind.label),
                    selected: _kind == kind,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _kind = kind),
                  ),
            ],
          ),
          if (_screenshot != null) ...[
            const SizedBox(height: 16),
            _FeedbackPreview(
              key: const ValueKey('feedback-screenshot-preview'),
              bytes: _screenshot!.bytes,
              onRemove: _saving
                  ? null
                  : () => setState(() => _screenshot = null),
            ),
            const SizedBox(height: 8),
            const Text(
              'Screenshot pixels are stored exactly as shown and are not redacted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GaussColors.warning,
                fontSize: GaussTypeScale.caption,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('feedback-note-field'),
            controller: _note,
            enabled: !_saving,
            minLines: 3,
            maxLines: 7,
            maxLength: 4000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Private note',
              hintText: 'What happened, and what would make it better?',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('feedback-save-action'),
            onPressed:
                _saving || (_note.text.trim().isEmpty && _screenshot == null)
                ? null
                : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline_rounded),
            label: Text(_saving ? 'Saving privately…' : 'Save privately'),
          ),
        ],
      ),
    );
  }
}

class GaussFeedbackEntriesSheet extends StatelessWidget {
  const GaussFeedbackEntriesSheet({required this.controller, super.key});

  final GaussFeedbackController controller;

  static Future<void> show(
    BuildContext context,
    GaussFeedbackController controller,
  ) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GaussFeedbackEntriesSheet(controller: controller),
  );

  Future<void> _confirmClear(BuildContext context) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('Clear private feedback?'),
        content: const Text(
          'This permanently removes every saved note and screenshot from this device. Learning progress and questions are not touched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep reports'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear reports'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      await controller.clearAll();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The outbox could not be cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _FeedbackSheetFrame(
    key: const ValueKey('feedback-entries-sheet'),
    maxHeightFactor: .9,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final entries = controller.entries;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeedbackSheetHeading(
              eyebrow: 'PRIVATE OUTBOX',
              title: entries.isEmpty
                  ? 'Nothing waiting'
                  : '${entries.length} saved ${entries.length == 1 ? 'signal' : 'signals'}',
              detail: entries.isEmpty
                  ? 'Capture a surface or leave a note whenever something needs attention.'
                  : 'Reports stay local until the verified account sync lane is connected.',
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Icon(
                  Icons.inbox_outlined,
                  color: GaussColors.fog,
                  size: 46,
                ),
              )
            else
              ListView.separated(
                key: const ValueKey('feedback-entry-list'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _FeedbackEntryTile(
                  entry: entries[index],
                  controller: controller,
                ),
              ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('feedback-clear-action'),
                onPressed: controller.busy
                    ? null
                    : () => _confirmClear(context),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear private outbox'),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _FeedbackEntryTile extends StatelessWidget {
  const _FeedbackEntryTile({required this.entry, required this.controller});

  final GaussFeedbackEntry entry;
  final GaussFeedbackController controller;

  Future<void> _delete(BuildContext context) async {
    try {
      await controller.deleteEntry(entry);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The report could not be removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextLine = entry.questionId == null
        ? entry.route
        : questionDisplayReference(entry.questionId!);
    return Material(
      color: GaussColors.deepInk.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('feedback-entry-${entry.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => _FeedbackEntryDetail.show(context, controller, entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeedbackKindGlyph(kind: entry.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.kind.label,
                      style: const TextStyle(
                        color: GaussColors.ivory,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contextLine,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: GaussColors.fog,
                        fontSize: GaussTypeScale.caption,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.hasScreenshot
                          ? 'Screenshot attached · waiting locally'
                          : 'Text report · waiting locally',
                      style: const TextStyle(
                        color: GaussColors.signalBright,
                        fontSize: GaussTypeScale.caption,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: GaussMetrics.minTouchTarget,
                child: IconButton(
                  tooltip: 'Delete this report',
                  onPressed: controller.busy ? null : () => _delete(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackEntryDetail extends StatelessWidget {
  const _FeedbackEntryDetail({required this.controller, required this.entry});

  final GaussFeedbackController controller;
  final GaussFeedbackEntry entry;

  static Future<void> show(
    BuildContext context,
    GaussFeedbackController controller,
    GaussFeedbackEntry entry,
  ) => showDialog<void>(
    context: context,
    builder: (_) => _FeedbackEntryDetail(controller: controller, entry: entry),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: _FeedbackKindGlyph(kind: entry.kind),
    title: Text(entry.kind.label, textAlign: TextAlign.center),
    content: SizedBox(
      width: 680,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .66,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entry.questionId == null
                    ? entry.route
                    : questionDisplayReference(entry.questionId!),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.caption,
                ),
              ),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 14),
                SelectableText(entry.note),
              ],
              if (entry.hasScreenshot) ...[
                const SizedBox(height: 16),
                FutureBuilder<Uint8List?>(
                  future: controller.readScreenshot(entry),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'The saved screenshot could not be decoded.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return _FeedbackPreview(bytes: bytes);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Screenshot pixels are stored exactly as captured and are not redacted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GaussColors.warning,
                    fontSize: GaussTypeScale.caption,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ],
  );
}

class GaussFeedbackToolsSheet extends StatelessWidget {
  const GaussFeedbackToolsSheet({
    required this.controller,
    this.onOpenVault,
    super.key,
  });

  final GaussFeedbackController controller;
  final VoidCallback? onOpenVault;

  static Future<void> show(
    BuildContext context, {
    required GaussFeedbackController controller,
    VoidCallback? onOpenVault,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GaussFeedbackToolsSheet(
      controller: controller,
      onOpenVault: onOpenVault,
    ),
  );

  @override
  Widget build(BuildContext context) => _FeedbackSheetFrame(
    key: const ValueKey('feedback-tools-sheet'),
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedbackSheetHeading(
            eyebrow: 'PRIVATE TOOLS',
            title: 'Feedback lens',
            detail:
                'Capture visual bugs or ideas without interrupting your learning path.',
          ),
          const SizedBox(height: 16),
          _FeedbackToggleInstrument(controller: controller),
          const SizedBox(height: 10),
          _FeedbackOrbitAction(
            key: const ValueKey('feedback-tools-compose'),
            icon: Icons.edit_note_rounded,
            title: 'Add a private note',
            detail: 'Write feedback without attaching a screenshot.',
            onTap: controller.busy
                ? null
                : () {
                    Navigator.pop(context);
                    GaussFeedbackComposer.show(
                      context,
                      controller: controller,
                      route: 'Feedback tools',
                    );
                  },
          ),
          _FeedbackOrbitAction(
            key: const ValueKey('feedback-tools-review'),
            icon: Icons.inbox_outlined,
            title: 'Review private outbox',
            detail:
                '${controller.entryCount} ${controller.entryCount == 1 ? 'report' : 'reports'} saved on this device.',
            onTap: controller.initialized
                ? () {
                    Navigator.pop(context);
                    GaussFeedbackEntriesSheet.show(context, controller);
                  }
                : null,
          ),
          if (onOpenVault != null)
            _FeedbackOrbitAction(
              key: const ValueKey('feedback-tools-vault'),
              icon: Icons.inventory_2_outlined,
              title: 'Progress vault',
              detail: 'Create or restore a private on-device progress copy.',
              onTap: () {
                Navigator.pop(context);
                onOpenVault!();
              },
            ),
        ],
      ),
    ),
  );
}

class _FeedbackToggleInstrument extends StatelessWidget {
  const _FeedbackToggleInstrument({required this.controller});

  final GaussFeedbackController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: GaussColors.deepInk.withValues(alpha: .72),
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeedbackKindGlyph(kind: GaussFeedbackKind.suggestion),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Floating capture lens',
                  style: TextStyle(
                    color: GaussColors.ivory,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'A draggable 52 dp control for quick screen capture.',
                  style: TextStyle(
                    color: GaussColors.fog,
                    fontSize: GaussTypeScale.caption,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 54,
            height: GaussMetrics.minTouchTarget,
            child: Switch.adaptive(
              key: const ValueKey('feedback-capture-toggle'),
              value: controller.enabled,
              onChanged: controller.initialized && !controller.busy
                  ? (value) async {
                      try {
                        await controller.setEnabled(value);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The capture setting could not be saved.',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeedbackSheetFrame extends StatelessWidget {
  const _FeedbackSheetFrame({
    required this.child,
    this.bottomPadding = 20,
    this.maxHeightFactor = .88,
    super.key,
  });

  final Widget child;
  final double bottomPadding;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const ValueKey('feedback-sheet-surface'),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: GaussColors.raised,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .34)),
            boxShadow: const [
              BoxShadow(color: Color(0xAA000000), blurRadius: 32),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _FeedbackSheetHeading extends StatelessWidget {
  const _FeedbackSheetHeading({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: GaussColors.fog.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        eyebrow,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GaussColors.brassLight,
          fontSize: GaussTypeScale.insignia,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        detail,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GaussColors.fog,
          fontSize: GaussTypeScale.metadata,
          height: 1.45,
        ),
      ),
    ],
  );
}

class _FeedbackOrbitAction extends StatelessWidget {
  const _FeedbackOrbitAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: GaussColors.deepInk.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: GaussColors.brass.withValues(alpha: .45),
                      ),
                    ),
                    child: Icon(icon, color: GaussColors.brassLight, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: GaussTypeScale.caption,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: GaussColors.fog,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FeedbackPreview extends StatelessWidget {
  const _FeedbackPreview({required this.bytes, this.onRemove, super.key});

  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      alignment: Alignment.topRight,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: Image.memory(
            bytes,
            width: double.infinity,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox(
              height: 120,
              child: Center(child: Text('Preview unavailable')),
            ),
          ),
        ),
        if (onRemove != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: GaussColors.abyss.withValues(alpha: .86),
              shape: const CircleBorder(),
              child: SizedBox.square(
                dimension: GaussMetrics.minTouchTarget,
                child: IconButton(
                  key: const ValueKey('feedback-remove-screenshot'),
                  tooltip: 'Remove screenshot',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FeedbackKindGlyph extends StatelessWidget {
  const _FeedbackKindGlyph({required this.kind});

  final GaussFeedbackKind kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      GaussFeedbackKind.error => Icons.error_outline_rounded,
      GaussFeedbackKind.suggestion => Icons.lightbulb_outline_rounded,
      GaussFeedbackKind.criticism => Icons.rate_review_outlined,
      GaussFeedbackKind.note => Icons.sticky_note_2_outlined,
      GaussFeedbackKind.questionIssue => Icons.flag_outlined,
    };
    return SizedBox.square(
      dimension: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GaussColors.signal.withValues(alpha: .11),
          border: Border.all(
            color: GaussColors.signalBright.withValues(alpha: .38),
          ),
        ),
        child: Icon(icon, color: GaussColors.signalBright, size: 22),
      ),
    );
  }
}
