import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import 'gauss_brand.dart';
import 'scratchpad.dart';
import 'theorem_lens.dart';

/// The accepted Gauss question composition: one continuous, writable
/// manuscript rather than a question card followed by unrelated answer cards.
///
/// The parchment texture is visual material only. Question content, options,
/// ink, controls, feedback, and semantics remain live Flutter widgets.
class QuestionManuscript extends StatefulWidget {
  const QuestionManuscript({
    required this.ink,
    required this.questionNumber,
    required this.difficulty,
    required this.prompt,
    required this.answers,
    required this.onExpandInk,
    required this.onClearInk,
    required this.onRestoreInk,
    this.active = true,
    this.onDrawingChanged,
    super.key,
  });

  final ScratchInkController ink;
  final int questionNumber;
  final String difficulty;
  final Widget prompt;
  final Widget answers;
  final bool active;
  final ValueChanged<bool>? onDrawingChanged;
  final VoidCallback onExpandInk;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;

  @override
  State<QuestionManuscript> createState() => _QuestionManuscriptState();
}

class _QuestionManuscriptState extends State<QuestionManuscript> {
  QuestionInkMode _mode = QuestionInkMode.pan;

  void _selectMode(QuestionInkMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<ScratchInkStatus>(
    valueListenable: widget.ink.status,
    builder: (context, inkStatus, _) {
      final accent = inkStatus.isEmpty
          ? GaussColors.brass
          : GaussColors.signalBright;
      return RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x9A000000),
                blurRadius: 38,
                offset: Offset(0, 18),
              ),
              BoxShadow(
                color: Color(0x2639D4D1),
                blurRadius: 18,
                spreadRadius: -6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/visual/question/manuscript_parchment_v1.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    cacheWidth: 1500,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x0D8D601F)),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ManuscriptFramePainter(accent: accent),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(12);
                      // A normal phone manuscript is intentionally a narrow
                      // writing folio with its tools bound to the left edge.
                      // Only genuinely compact or large-text compositions
                      // move the tools above the page. Basing this boundary
                      // on the manuscript width (rather than the viewport)
                      // keeps Study and Mission visually identical even when
                      // their outer gutters differ.
                      final verticalTools =
                          constraints.maxWidth >= 330 && textScale < 18;
                      final content = _ManuscriptContent(
                        ink: widget.ink,
                        inkStatus: inkStatus,
                        mode: _mode,
                        questionNumber: widget.questionNumber,
                        difficulty: widget.difficulty,
                        prompt: widget.prompt,
                        answers: widget.answers,
                        active: widget.active,
                        onDrawingChanged: widget.onDrawingChanged,
                      );
                      final tools = _ManuscriptToolRail(
                        ink: widget.ink,
                        inkStatus: inkStatus,
                        mode: _mode,
                        vertical: verticalTools,
                        onMode: _selectMode,
                        onExpand: widget.onExpandInk,
                        onClear: widget.onClearInk,
                        onRestore: widget.onRestoreInk,
                      );
                      if (!verticalTools) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            tools,
                            const SizedBox(height: GaussSpacing.space8),
                            const _EngravedRule(),
                            const SizedBox(height: GaussSpacing.space8),
                            content,
                          ],
                        );
                      }
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 60),
                            child: content,
                          ),
                          Positioned(left: 0, top: 0, child: tools),
                          const Positioned(
                            left: 54,
                            top: 0,
                            bottom: 0,
                            child: _VerticalEngravedRule(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ManuscriptContent extends StatelessWidget {
  const _ManuscriptContent({
    required this.ink,
    required this.inkStatus,
    required this.mode,
    required this.questionNumber,
    required this.difficulty,
    required this.prompt,
    required this.answers,
    required this.active,
    required this.onDrawingChanged,
  });

  final ScratchInkController ink;
  final ScratchInkStatus inkStatus;
  final QuestionInkMode mode;
  final int questionNumber;
  final String difficulty;
  final Widget prompt;
  final Widget answers;
  final bool active;
  final ValueChanged<bool>? onDrawingChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ManuscriptQuestionHeader(
        difficulty: difficulty,
        questionNumber: questionNumber,
      ),
      const SizedBox(height: GaussSpacing.space16),
      InlineQuestionScratch(
        key: ValueKey('study-ink-surface-$questionNumber'),
        controller: ink,
        active: active,
        inputMode: mode,
        showInlineControls: false,
        onDrawingChanged: onDrawingChanged,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            prompt,
            const SizedBox(height: GaussSpacing.space16),
            Semantics(
              label:
                  'Writable reasoning space. A hardware stylus writes immediately.',
              child: AnimatedContainer(
                key: const ValueKey('question-manuscript-writing-space'),
                duration: GaussMotion.resolve(context, GaussMotion.standard),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minHeight: inkStatus.isEmpty ? 112 : 176,
                ),
                alignment: AlignmentDirectional.topStart,
                padding: const EdgeInsets.all(GaussSpacing.space8),
                child: inkStatus.isEmpty
                    ? ExcludeSemantics(child: _WritingSpaceSignal(mode: mode))
                    : null,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: GaussSpacing.space12),
      const _EngravedRule(ornament: true),
      const SizedBox(height: GaussSpacing.space16),
      answers,
    ],
  );
}

class _WritingSpaceSignal extends StatelessWidget {
  const _WritingSpaceSignal({required this.mode});

  final QuestionInkMode mode;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      QuestionInkMode.pan => 'STYLUS READY · TOUCH SCROLLS',
      QuestionInkMode.pen => 'FINGER INK ACTIVE',
      QuestionInkMode.eraser => 'STROKE ERASER ACTIVE',
    };
    final accent = mode == QuestionInkMode.pan
        ? GaussColors.parchmentInk
        : const Color(0xFF237E83);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          mode == QuestionInkMode.pan
              ? Icons.draw_outlined
              : mode == QuestionInkMode.pen
              ? Icons.gesture_rounded
              : Icons.cleaning_services_outlined,
          size: 15,
          color: accent.withValues(alpha: .34),
        ),
        const SizedBox(width: GaussSpacing.space8),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(
              color: accent.withValues(alpha: .34),
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w800,
              letterSpacing: .85,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManuscriptQuestionHeader extends StatelessWidget {
  const _ManuscriptQuestionHeader({
    required this.difficulty,
    required this.questionNumber,
  });

  final String difficulty;
  final int questionNumber;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScaler = MediaQuery.textScalerOf(context);
      final difficultyText = difficulty.toUpperCase();
      final questionText = 'QUESTION $questionNumber';
      const difficultyStyle = TextStyle(
        fontFamily: 'Manrope',
        fontSize: GaussTypeScale.insignia,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      );
      const questionStyle = TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      );
      double measuredWidth(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        return painter.width;
      }

      final inlineWidth =
          measuredWidth(difficultyText, difficultyStyle) +
          GaussSpacing.space16 +
          measuredWidth(questionText, questionStyle) +
          GaussSpacing.space8 +
          17;
      final stacked =
          textScaler.scale(12) >= 18 ||
          constraints.maxWidth < inlineWidth.ceilToDouble();
      final difficultyLabel = Text(
        difficultyText,
        key: const ValueKey('question-manuscript-difficulty'),
        textAlign: stacked ? TextAlign.center : TextAlign.start,
        softWrap: true,
        style: difficultyStyle.copyWith(
          color: GaussColors.parchmentInk.withValues(alpha: .58),
        ),
      );
      final questionLabel = Text(
        questionText,
        key: const ValueKey('question-manuscript-number'),
        textAlign: stacked ? TextAlign.center : TextAlign.start,
        textDirection: TextDirection.ltr,
        softWrap: true,
        style: questionStyle.copyWith(color: GaussColors.parchmentInk),
      );

      if (stacked) {
        return Column(
          key: const ValueKey('question-manuscript-header-stacked'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            difficultyLabel,
            const SizedBox(height: GaussSpacing.space4),
            questionLabel,
            const SizedBox(height: GaussSpacing.space4),
            const Center(child: TheoremStarMark(size: 17, darkInk: true)),
          ],
        );
      }

      return Row(
        key: const ValueKey('question-manuscript-header-inline'),
        children: [
          difficultyLabel,
          const Spacer(),
          questionLabel,
          const SizedBox(width: GaussSpacing.space8),
          const TheoremStarMark(size: 17, darkInk: true),
        ],
      );
    },
  );
}

class _ManuscriptToolRail extends StatelessWidget {
  const _ManuscriptToolRail({
    required this.ink,
    required this.inkStatus,
    required this.mode,
    required this.vertical,
    required this.onMode,
    required this.onExpand,
    required this.onClear,
    required this.onRestore,
  });

  final ScratchInkController ink;
  final ScratchInkStatus inkStatus;
  final QuestionInkMode mode;
  final bool vertical;
  final ValueChanged<QuestionInkMode> onMode;
  final VoidCallback onExpand;
  final VoidCallback onClear;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final returnToScroll = mode != QuestionInkMode.pan;
    final buttons = <Widget>[
      _ManuscriptToolButton(
        key: ValueKey(
          returnToScroll ? 'manuscript-pan-tool' : 'manuscript-pen-tool',
        ),
        icon: returnToScroll
            ? Icons.pan_tool_alt_outlined
            : Icons.draw_outlined,
        label: returnToScroll ? 'Touch scroll' : 'Finger pen',
        selected: returnToScroll,
        onPressed: () =>
            onMode(returnToScroll ? QuestionInkMode.pan : QuestionInkMode.pen),
      ),
      if (inkStatus.canUndo && !inkStatus.canRestoreClearedInk)
        _ManuscriptToolButton(
          key: const ValueKey('manuscript-undo-tool'),
          icon: Icons.undo_rounded,
          label: 'Undo last stroke',
          onPressed: ink.undo,
        ),
      _ManuscriptToolButton(
        key: const ValueKey('manuscript-expand-tool'),
        icon: Icons.open_in_full_rounded,
        label: 'Open full scratchpad',
        onPressed: onExpand,
      ),
      if (!inkStatus.isEmpty && !inkStatus.canRestoreClearedInk)
        _ManuscriptToolButton(
          key: const ValueKey('manuscript-eraser-tool'),
          icon: Icons.cleaning_services_outlined,
          label: 'Stroke eraser',
          selected: mode == QuestionInkMode.eraser,
          onPressed: () => onMode(QuestionInkMode.eraser),
        ),
      if (!inkStatus.isEmpty || inkStatus.canRestoreClearedInk)
        _ManuscriptToolButton(
          key: ValueKey(
            inkStatus.canRestoreClearedInk
                ? 'manuscript-restore-tool'
                : 'manuscript-clear-tool',
          ),
          icon: inkStatus.canRestoreClearedInk
              ? Icons.restore_rounded
              : Icons.delete_outline_rounded,
          label: inkStatus.canRestoreClearedInk
              ? 'Restore cleared ink'
              : 'Clear ink',
          danger: !inkStatus.canRestoreClearedInk,
          onPressed: inkStatus.canRestoreClearedInk ? onRestore : onClear,
        ),
    ];
    return Semantics(
      container: true,
      label: 'Manuscript tools',
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  buttons[index],
                  if (index != buttons.length - 1)
                    const SizedBox(height: GaussSpacing.space8),
                ],
              ],
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: GaussSpacing.space8,
              runSpacing: GaussSpacing.space8,
              children: buttons,
            ),
    );
  }
}

class _ManuscriptToolButton extends StatelessWidget {
  const _ManuscriptToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF2D9BA1)
        : danger
        ? const Color(0xFF7B3A32)
        : GaussColors.parchmentInk;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: SizedBox.square(
          dimension: GaussMetrics.minTouchTarget,
          child: Material(
            color: selected ? const Color(0x2D2D9BA1) : const Color(0x12FFFFFF),
            shape: CircleBorder(
              side: BorderSide(
                color: color.withValues(alpha: onPressed == null ? .18 : .5),
                width: selected ? 1.8 : 1,
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(
                icon,
                color: color.withValues(alpha: onPressed == null ? .24 : .9),
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single engraved answer row inside [QuestionManuscript].
class ManuscriptChoiceShell extends StatelessWidget {
  const ManuscriptChoiceShell({
    required this.tone,
    required this.emblem,
    required this.child,
    required this.onTap,
    super.key,
  });

  final TheoremChoiceTone tone;
  final Widget emblem;
  final Widget child;
  final VoidCallback? onTap;

  Color get _accent => switch (tone) {
    TheoremChoiceTone.neutral => const Color(0xFF846B43),
    TheoremChoiceTone.selected => const Color(0xFF237E83),
    TheoremChoiceTone.positive => const Color(0xFF27745F),
    TheoremChoiceTone.negative => const Color(0xFF9A493E),
    TheoremChoiceTone.source => const Color(0xFF9D691D),
  };

  @override
  Widget build(BuildContext context) {
    final active = tone != TheoremChoiceTone.neutral;
    return Padding(
      padding: const EdgeInsets.only(bottom: GaussSpacing.space8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: _accent.withValues(alpha: .1),
            highlightColor: _accent.withValues(alpha: .05),
            child: AnimatedContainer(
              duration: GaussMotion.resolve(context, GaussMotion.micro),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: active
                    ? _accent.withValues(alpha: .1)
                    : const Color(0x18FFFFFF),
              ),
              child: CustomPaint(
                painter: _ChoiceEngravingPainter(
                  accent: _accent,
                  active: active,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 50,
                        child: CustomPaint(
                          painter: _ChoiceSealPainter(
                            accent: _accent,
                            active: active,
                          ),
                          child: Center(child: emblem),
                        ),
                      ),
                      const SizedBox(width: GaussSpacing.space12),
                      Expanded(child: child),
                      const SizedBox(width: GaussSpacing.space8),
                      Icon(
                        active ? Icons.auto_awesome : Icons.star_border_rounded,
                        size: 14,
                        color: _accent.withValues(alpha: active ? .9 : .38),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EngravedRule extends StatelessWidget {
  const _EngravedRule({this.ornament = false});
  final bool ornament;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: Color(0x4A735C37), height: 1)),
      if (ornament) ...[
        const SizedBox(width: GaussSpacing.space8),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x9A735C37)),
            ),
          ),
        ),
        const SizedBox(width: GaussSpacing.space8),
        const Expanded(child: Divider(color: Color(0x4A735C37), height: 1)),
      ],
    ],
  );
}

class _VerticalEngravedRule extends StatelessWidget {
  const _VerticalEngravedRule();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0x7A735C37), Colors.transparent],
      ),
    ),
  );
}

class _ManuscriptFramePainter extends CustomPainter {
  const _ManuscriptFramePainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.5),
      const Radius.circular(23),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = GaussColors.brass.withValues(alpha: .72),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(7),
        const Radius.circular(18),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = GaussColors.parchmentInk.withValues(alpha: .22),
    );
    final glow = Paint()
      ..color = accent.withValues(alpha: .44)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.width / 2, size.height - 2), 3, glow);
  }

  @override
  bool shouldRepaint(covariant _ManuscriptFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _ChoiceEngravingPainter extends CustomPainter {
  const _ChoiceEngravingPainter({required this.accent, required this.active});
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const notch = 7.0;
    final path = Path()
      ..moveTo(notch, .8)
      ..lineTo(size.width - notch, .8)
      ..lineTo(size.width - .8, notch)
      ..lineTo(size.width - .8, size.height - notch)
      ..lineTo(size.width - notch, size.height - .8)
      ..lineTo(notch, size.height - .8)
      ..lineTo(.8, size.height - notch)
      ..lineTo(.8, notch)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.5 : 1
        ..color = accent.withValues(alpha: active ? .9 : .56),
    );
    canvas.drawLine(
      const Offset(61, 7),
      Offset(61, size.height - 7),
      Paint()
        ..strokeWidth = .7
        ..color = accent.withValues(alpha: .34),
    );
  }

  @override
  bool shouldRepaint(covariant _ChoiceEngravingPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.active != active;
}

class _ChoiceSealPainter extends CustomPainter {
  const _ChoiceSealPainter({required this.accent, required this.active});
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 1.7 : 1
      ..color = accent.withValues(alpha: active ? .94 : .58);
    canvas.drawCircle(center, 22, ring);
    canvas.drawCircle(center, 17, ring..strokeWidth = .65);
    for (var index = 0; index < 4; index++) {
      final angle = index * math.pi / 2;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 19;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * 23;
      canvas.drawLine(start, end, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _ChoiceSealPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.active != active;
}
