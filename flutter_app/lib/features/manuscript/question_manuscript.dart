import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gauss/domain/models.dart';
import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/features/manuscript/scratchpad.dart';
import 'package:gauss/features/manuscript/theorem_lens.dart';

/// The accepted Gauss question composition: one continuous, writable
/// manuscript rather than a question card followed by unrelated answer cards.
///
/// The parchment texture is visual material only. Question content, options,
/// ink, controls, feedback, and semantics remain live Flutter widgets.
class QuestionManuscript extends StatefulWidget {
  /// Phones keep a compact writing band and scroll; a tablet gives the pen
  /// room in proportion to the screen instead of leaving half of it empty
  /// below a short manuscript.
  ///
  /// Gated on the manuscript's own width, not the device: a phone-width
  /// split-screen pane on a tablet keeps the compact band.
  static double writingSpaceFor({
    required double manuscriptWidth,
    required double screenHeight,
  }) =>
      manuscriptWidth >= 560 ? (screenHeight * .32).clamp(112.0, 420.0) : 112.0;

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
    this.reviewing = false,
    this.review,
    this.onDrawingChanged,
    super.key,
  });

  final ScratchInkController ink;
  final int questionNumber;
  final String difficulty;
  final Widget prompt;
  final Widget answers;
  final bool active;
  final bool reviewing;
  final Widget? review;
  final ValueChanged<bool>? onDrawingChanged;
  final VoidCallback onExpandInk;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;

  @override
  State<QuestionManuscript> createState() => _QuestionManuscriptState();
}

class _QuestionManuscriptState extends State<QuestionManuscript> {
  QuestionInkMode _mode = QuestionInkMode.pan;

  @override
  void didUpdateWidget(covariant QuestionManuscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionNumber != widget.questionNumber ||
        (!oldWidget.reviewing && widget.reviewing)) {
      // A new question and the review transition both begin with native touch
      // scrolling. This prevents a previously selected finger-ink mode from
      // trapping the user above the answer explanation.
      _mode = QuestionInkMode.pan;
    }
  }

  void _selectMode(QuestionInkMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<ScratchInkStatus>(
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
                    color: Color(0x80000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
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
                        // Decode near the paper's real size on a phone; the
                        // texture is soft, so a tablet upscale stays clean.
                        cacheWidth: 1080,
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ManuscriptFramePainter(accent: accent),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ManuscriptHeaderBar(
                            meta: _ManuscriptQuestionHeader(
                              difficulty: widget.difficulty,
                              questionNumber: widget.questionNumber,
                            ),
                            tools: _ManuscriptToolRail(
                              ink: widget.ink,
                              inkStatus: inkStatus,
                              mode: _mode,
                              onMode: _selectMode,
                              onExpand: widget.onExpandInk,
                              onClear: widget.onClearInk,
                              onRestore: widget.onRestoreInk,
                            ),
                          ),
                          const SizedBox(height: GaussSpacing.space12),
                          const _EngravedRule(),
                          const SizedBox(height: GaussSpacing.space16),
                          _ManuscriptContent(
                            ink: widget.ink,
                            inkStatus: inkStatus,
                            mode: _mode,
                            questionNumber: widget.questionNumber,
                            prompt: widget.prompt,
                            answers: widget.answers,
                            review: widget.review,
                            active: widget.active,
                            onDrawingChanged: widget.onDrawingChanged,
                            inkTools: _ManuscriptToolRail(
                              ink: widget.ink,
                              inkStatus: inkStatus,
                              mode: _mode,
                              editing: true,
                              onMode: _selectMode,
                              onExpand: widget.onExpandInk,
                              onClear: widget.onClearInk,
                              onRestore: widget.onRestoreInk,
                            ),
                          ),
                        ],
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

/// Question identity on the start side, ink tools on the end side. When the
/// row cannot hold both at the current width and text size, the tools drop
/// below the identity instead of squeezing it.
class _ManuscriptHeaderBar extends StatelessWidget {
  const _ManuscriptHeaderBar({required this.meta, required this.tools});

  final Widget meta;
  final Widget tools;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final inline = constraints.maxWidth >= 300 && textScale < 1.5;
      if (inline) {
        return Row(
          key: const ValueKey('question-manuscript-header-inline'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: meta),
            const SizedBox(width: GaussSpacing.space8),
            tools,
          ],
        );
      }
      return Column(
        key: const ValueKey('question-manuscript-header-stacked'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          meta,
          const SizedBox(height: GaussSpacing.space12),
          Align(alignment: AlignmentDirectional.centerStart, child: tools),
        ],
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
    required this.prompt,
    required this.answers,
    required this.review,
    required this.active,
    required this.onDrawingChanged,
    required this.inkTools,
  });

  final ScratchInkController ink;
  final ScratchInkStatus inkStatus;
  final QuestionInkMode mode;
  final int questionNumber;
  final Widget inkTools;
  final Widget prompt;
  final Widget answers;
  final Widget? review;
  final bool active;
  final ValueChanged<bool>? onDrawingChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Stack(
        children: [
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
                  child: LayoutBuilder(
                    builder: (context, constraints) => AnimatedContainer(
                      key: const ValueKey('question-manuscript-writing-space'),
                      duration: GaussMotion.resolve(
                        context,
                        GaussMotion.standard,
                      ),
                      curve: Curves.easeOutCubic,
                      constraints: BoxConstraints(
                        minHeight: QuestionManuscript.writingSpaceFor(
                          manuscriptWidth: constraints.maxWidth,
                          screenHeight: MediaQuery.sizeOf(context).height,
                        ),
                      ),
                      alignment: AlignmentDirectional.topStart,
                      padding: const EdgeInsets.all(GaussSpacing.space8),
                      // Faint notebook ruling marks the writable band, so the
                      // empty space reads as paper to work on, not a gap.
                      foregroundDecoration: const _RuledPaperDecoration(),
                      child: inkStatus.isEmpty
                          ? ExcludeSemantics(
                              child: _WritingSpaceSignal(mode: mode),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Painted above the ink surface, so taps reach the tools and never
          // start a stroke.
          PositionedDirectional(end: 0, bottom: 0, child: inkTools),
        ],
      ),
      const SizedBox(height: GaussSpacing.space12),
      const _EngravedRule(ornament: true),
      const SizedBox(height: GaussSpacing.space16),
      answers,
      if (review case final review?) ...[
        const SizedBox(height: GaussSpacing.space20),
        const _EngravedRule(ornament: true),
        const SizedBox(height: GaussSpacing.space16),
        review,
      ],
    ],
  );
}

class _WritingSpaceSignal extends StatelessWidget {
  const _WritingSpaceSignal({required this.mode});

  final QuestionInkMode mode;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      QuestionInkMode.pan =>
        'Work it out here. A stylus writes; a finger scrolls.',
      QuestionInkMode.pen => 'Finger pen on. Write anywhere on the page.',
      QuestionInkMode.eraser => 'Eraser on. Touch a stroke to remove it.',
    };
    final accent = mode == QuestionInkMode.pan
        ? GaussColors.parchmentInk
        : GaussParchmentInk.teal;
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
          color: accent.withValues(alpha: .5),
        ),
        const SizedBox(width: GaussSpacing.space8),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(
              color: accent.withValues(alpha: .62),
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w700,
              height: 1.3,
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

  /// Difficulty as a level out of four, so it reads by shape as well.
  int get _level {
    final index = Difficulty.values.indexWhere(
      (item) => item.label.toLowerCase() == difficulty.toLowerCase(),
    );
    return index < 0 ? 0 : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final difficultyText = difficulty.isEmpty
        ? difficulty
        : '${difficulty[0].toUpperCase()}${difficulty.substring(1).toLowerCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Question $questionNumber',
          key: const ValueKey('question-manuscript-number'),
          textDirection: TextDirection.ltr,
          softWrap: true,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: GaussColors.parchmentInk,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        if (difficultyText.isNotEmpty) ...[
          const SizedBox(height: GaussSpacing.space4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_level > 0) ...[
                _DifficultyBars(level: _level),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  difficultyText,
                  key: const ValueKey('question-manuscript-difficulty'),
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: GaussColors.parchmentInk.withValues(alpha: .72),
                    fontSize: GaussTypeScale.caption,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DifficultyBars extends StatelessWidget {
  const _DifficultyBars({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var bar = 1; bar <= 4; bar++) ...[
        if (bar > 1) const SizedBox(width: 2),
        Container(
          width: 3,
          height: 4.0 + bar * 2,
          decoration: BoxDecoration(
            color: bar <= level
                ? GaussParchmentInk.sepia
                : GaussColors.parchmentInk.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ],
    ],
  );
}

/// Paints two faint ruled lines across the writing band.
class _RuledPaperDecoration extends Decoration {
  const _RuledPaperDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      const _RuledPaperPainter();
}

class _RuledPaperPainter extends BoxPainter {
  const _RuledPaperPainter();

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final paint = Paint()
      ..color = GaussColors.parchmentInk.withValues(alpha: .1)
      ..strokeWidth = 1;
    const spacing = 34.0;
    for (var y = spacing + 8; y < size.height - 4; y += spacing) {
      canvas.drawLine(
        offset + Offset(4, y),
        offset + Offset(size.width - 4, y),
        paint,
      );
    }
  }
}

class _ManuscriptToolRail extends StatelessWidget {
  const _ManuscriptToolRail({
    required this.ink,
    required this.inkStatus,
    required this.mode,
    required this.onMode,
    required this.onExpand,
    required this.onClear,
    required this.onRestore,
    this.editing = false,
  });

  final ScratchInkController ink;
  final ScratchInkStatus inkStatus;
  final QuestionInkMode mode;
  final ValueChanged<QuestionInkMode> onMode;
  final VoidCallback onExpand;
  final VoidCallback onClear;
  final VoidCallback onRestore;

  /// The header carries the two standing tools (pen mode, full pad). The
  /// tools that only exist once ink exists (undo, eraser, clear or restore)
  /// float over the writing band's corner instead, so ink appearing never
  /// resizes the paper under the pen.
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final returnToScroll = mode != QuestionInkMode.pan;
    final buttons = <Widget>[
      if (!editing)
        _ManuscriptToolButton(
          key: ValueKey(
            returnToScroll ? 'manuscript-pan-tool' : 'manuscript-pen-tool',
          ),
          icon: returnToScroll
              ? Icons.pan_tool_alt_outlined
              : Icons.draw_outlined,
          label: returnToScroll ? 'Touch scroll' : 'Finger pen',
          selected: returnToScroll,
          onPressed: () => onMode(
            returnToScroll ? QuestionInkMode.pan : QuestionInkMode.pen,
          ),
        ),
      if (editing && inkStatus.canUndo && !inkStatus.canRestoreClearedInk)
        _ManuscriptToolButton(
          key: const ValueKey('manuscript-undo-tool'),
          icon: Icons.undo_rounded,
          label: 'Undo last stroke',
          onPressed: ink.undo,
        ),
      if (!editing)
        _ManuscriptToolButton(
          key: const ValueKey('manuscript-expand-tool'),
          icon: Icons.open_in_full_rounded,
          label: 'Open full scratchpad',
          onPressed: onExpand,
        ),
      if (editing && !inkStatus.isEmpty && !inkStatus.canRestoreClearedInk)
        _ManuscriptToolButton(
          key: const ValueKey('manuscript-eraser-tool'),
          icon: Icons.cleaning_services_outlined,
          label: 'Stroke eraser',
          selected: mode == QuestionInkMode.eraser,
          onPressed: () => onMode(QuestionInkMode.eraser),
        ),
      if (editing && (!inkStatus.isEmpty || inkStatus.canRestoreClearedInk))
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
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: editing ? 'Ink tools' : 'Manuscript tools',
      child: Wrap(
        spacing: GaussSpacing.space4,
        runSpacing: GaussSpacing.space4,
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
        ? GaussParchmentInk.tealBright
        : danger
        ? GaussParchmentInk.negativeDeep
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
            // Near-opaque paper, so a tool floating over ink stays legible.
            color: selected
                ? Color.alphaBlend(
                    GaussParchmentInk.selectedWash,
                    GaussColors.parchment,
                  )
                : GaussColors.parchment.withValues(alpha: .94),
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

/// One answer row inside [QuestionManuscript].
///
/// The row follows the content's reading direction (right-to-left for the
/// Persian source), so the choice number sits where the eye starts, as on a
/// printed test sheet. State is carried by the badge shape and fill as well
/// as color: a number while open, a check or a cross once checked. Fill and
/// edge colors animate (SonusKt selection grammar); a checked result gives
/// the badge one short settle so the outcome registers.
class ManuscriptChoiceShell extends StatelessWidget {
  const ManuscriptChoiceShell({
    required this.tone,
    required this.emblem,
    required this.child,
    required this.onTap,
    this.textDirection = TextDirection.rtl,
    super.key,
  });

  final TheoremChoiceTone tone;
  final Widget emblem;
  final Widget child;
  final VoidCallback? onTap;
  final TextDirection textDirection;

  Color get _accent => switch (tone) {
    TheoremChoiceTone.neutral => GaussParchmentInk.sepia,
    TheoremChoiceTone.selected => GaussParchmentInk.teal,
    TheoremChoiceTone.positive => GaussParchmentInk.positive,
    TheoremChoiceTone.negative => GaussParchmentInk.negative,
    TheoremChoiceTone.source => GaussParchmentInk.brass,
  };

  @override
  Widget build(BuildContext context) {
    final active = tone != TheoremChoiceTone.neutral;
    final accent = _accent;
    final duration = GaussMotion.resolve(
      context,
      const Duration(milliseconds: 220),
    );
    final settles =
        tone == TheoremChoiceTone.positive ||
        tone == TheoremChoiceTone.negative;
    final badge = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? accent : accent.withValues(alpha: .55),
          width: 1.5,
        ),
      ),
      child: IconTheme.merge(
        data: IconThemeData(
          color: active ? GaussColors.parchment : GaussColors.parchmentInk,
          size: 22,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: 'Manrope',
            color: active ? GaussColors.parchment : GaussColors.parchmentInk,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
          child: emblem,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: GaussSpacing.space8),
      child: Directionality(
        textDirection: textDirection,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: accent.withValues(alpha: .12),
            highlightColor: accent.withValues(alpha: .06),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 14, 10),
              decoration: BoxDecoration(
                color: active
                    ? accent.withValues(alpha: .12)
                    : const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? accent : accent.withValues(alpha: .28),
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  settles
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey(tone),
                          tween: Tween(begin: 1.18, end: 1),
                          duration: GaussMotion.resolve(
                            context,
                            const Duration(milliseconds: 360),
                          ),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: badge,
                        )
                      : badge,
                  const SizedBox(width: GaussSpacing.space12),
                  Expanded(child: child),
                ],
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
      const Expanded(
        child: Divider(color: GaussParchmentInk.ruleFaint, height: 1),
      ),
      if (ornament) ...[
        const SizedBox(width: GaussSpacing.space8),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: GaussParchmentInk.ruleStrong),
            ),
          ),
        ),
        const SizedBox(width: GaussSpacing.space8),
        const Expanded(
          child: Divider(color: GaussParchmentInk.ruleFaint, height: 1),
        ),
      ],
    ],
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
        ..strokeWidth = 1
        ..color = GaussColors.brass.withValues(alpha: .5),
    );
  }

  @override
  bool shouldRepaint(covariant _ManuscriptFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// Answer rails: one column on phones; two columns once the manuscript is
/// wide enough (tablets), so short answers stop stretching across 1000dp
/// with the letter and the value at opposite edges. Row-major order keeps
/// the reading and traversal order A, B, C, D.
class ManuscriptAnswerGrid extends StatelessWidget {
  const ManuscriptAnswerGrid({required this.children, super.key});

  static const twoColumnMinWidth = 640.0;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final accessibleText =
          MediaQuery.textScalerOf(context).scale(1) >=
          GaussComposition.accessibilityTextScale;
      if (constraints.maxWidth < twoColumnMinWidth ||
          accessibleText ||
          children.length < 2) {
        return Column(children: children);
      }
      return Column(
        children: [
          for (var index = 0; index < children.length; index += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: children[index]),
                const SizedBox(width: GaussSpacing.space12),
                Expanded(
                  child: index + 1 < children.length
                      ? children[index + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      );
    },
  );
}
