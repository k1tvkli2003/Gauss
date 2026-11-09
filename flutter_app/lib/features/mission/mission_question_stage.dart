part of 'mission_screen.dart';

class _QuestionStage extends StatelessWidget {
  const _QuestionStage({
    required this.question,
    required this.chapterLabel,
    required this.index,
    required this.total,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.covered,
    required this.errorTag,
    required this.operationError,
    required this.ink,
    required this.onSelect,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
    required this.onRevealChoices,
    required this.onTagError,
    required this.onReportIssue,
    required this.onClearInk,
    required this.onRestoreInk,
    required this.onScratchpad,
    required this.onClose,
  });
  final Question question;
  final String chapterLabel;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final bool covered;
  final String? errorTag;
  final Object? operationError;
  final ScratchInkController ink;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onRevealChoices;
  final ValueChanged<MissReason> onTagError;
  final VoidCallback onReportIssue;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;
  final VoidCallback onScratchpad;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final wrongPick =
        checked &&
        selectedChoice != null &&
        selectedChoice != question.correctChoiceIndex;
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MissionBackdrop(),
        SafeArea(
          child: Column(
            children: [
              _MissionTopBar(
                index: index,
                total: total,
                chapterLabel: chapterLabel,
                busy: busy,
                onClose: onClose,
                onScratchpad: onScratchpad,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Pane capability belongs to the Android window, not the
                    // remaining height inside this Column. The top progress
                    // instrument, action dock, and system safe areas reduce
                    // [constraints.maxHeight] after the window has already
                    // qualified as a landscape tablet. Basing the decision on
                    // that remainder made the solution pane disappear on a
                    // real 1280x800 Pixel Tablet even though the same surface
                    // passed a padding-free widget test.
                    final viewport = GaussViewport.fromSize(
                      Size(
                        constraints.maxWidth,
                        MediaQuery.sizeOf(context).height,
                      ),
                    );
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final hasReadablePaneHeight =
                        constraints.maxHeight >= GaussBreakpoints.mediumHeight;
                    final showReviewWorkspace =
                        checked &&
                        viewport.supportsThreePane &&
                        hasReadablePaneHeight &&
                        textScale < 1.35;
                    if (!showReviewWorkspace) {
                      return _QuestionScroll(
                        question: question,
                        ink: ink,
                        index: index,
                        selectedChoice: selectedChoice,
                        checked: checked,
                        busy: busy,
                        covered: covered,
                        errorTag: errorTag,
                        showSolution: checked,
                        onSelect: onSelect,
                        onRevealChoices: onRevealChoices,
                        onTagError: onTagError,
                        onReportIssue: onReportIssue,
                        onClearInk: onClearInk,
                        onRestoreInk: onRestoreInk,
                      );
                    }
                    return Padding(
                      key: const ValueKey('mission-adaptive-review-workspace'),
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _QuestionScroll(
                              question: question,
                              ink: ink,
                              index: index,
                              selectedChoice: selectedChoice,
                              checked: checked,
                              busy: busy,
                              covered: covered,
                              errorTag: errorTag,
                              showSolution: false,
                              onSelect: onSelect,
                              onRevealChoices: onRevealChoices,
                              onTagError: onTagError,
                              onReportIssue: onReportIssue,
                              onClearInk: onClearInk,
                              onRestoreInk: onRestoreInk,
                              inset: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            key: const ValueKey('mission-solution-pane'),
                            width: constraints.maxWidth >= 1250 ? 350 : 310,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (wrongPick) ...[
                                    _MissTagBar(
                                      selected: errorTag,
                                      onSelect: onTagError,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  _SolutionPanel(question: question),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _MissionActionBar(
                question: question,
                index: index,
                total: total,
                selectedChoice: selectedChoice,
                checked: checked,
                busy: busy,
                operationError: operationError,
                onCheck: onCheck,
                onSkip: onSkip,
                onNext: onNext,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionBackdrop extends StatelessWidget {
  const _MissionBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image(
        image: GaussImages.atmosphere,
        opacity: const AlwaysStoppedAnimation(.42),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xD907151C), Color(0xF2050B0D)],
          ),
        ),
      ),
    ],
  );
}

class _MissionTopBar extends StatelessWidget {
  const _MissionTopBar({
    required this.index,
    required this.total,
    required this.chapterLabel,
    required this.busy,
    required this.onClose,
    required this.onScratchpad,
  });

  final int index;
  final int total;
  final String chapterLabel;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onScratchpad;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
    child: Column(
      key: const ValueKey('mission-question-header'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: GaussMetrics.minTouchTarget,
          child: Stack(
            key: const ValueKey('mission-question-header-axis'),
            fit: StackFit.expand,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  key: const ValueKey('mission-close-action'),
                  onPressed: busy ? null : onClose,
                  tooltip: 'Leave mission',
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Align(
                alignment: Alignment.center,
                child: GaussWordmark(
                  key: ValueKey('mission-centered-wordmark'),
                  width: 82,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  key: const ValueKey('mission-scratchpad-action'),
                  onPressed: busy ? null : onScratchpad,
                  tooltip: 'Open full scratchpad',
                  icon: const GaussScratchGlyph(color: GaussColors.brassLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: GaussSpacing.space8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: QuestionProgressRail(
            key: const ValueKey('mission-question-progress'),
            index: index,
            total: total,
            label: chapterLabel,
            valueKey: const ValueKey('mission-question-position'),
          ),
        ),
      ],
    ),
  );
}

class _QuestionScroll extends StatefulWidget {
  const _QuestionScroll({
    required this.question,
    required this.ink,
    required this.index,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.covered,
    required this.errorTag,
    required this.showSolution,
    required this.onSelect,
    required this.onRevealChoices,
    required this.onTagError,
    required this.onReportIssue,
    required this.onClearInk,
    required this.onRestoreInk,
    this.inset = const EdgeInsets.fromLTRB(16, 8, 16, 18),
  });

  final Question question;
  final ScratchInkController ink;
  final int index;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final bool covered;
  final String? errorTag;
  final bool showSolution;
  final ValueChanged<int> onSelect;
  final VoidCallback onRevealChoices;
  final ValueChanged<MissReason> onTagError;
  final VoidCallback onReportIssue;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;
  final EdgeInsets inset;

  @override
  State<_QuestionScroll> createState() => _QuestionScrollState();
}

class _QuestionScrollState extends State<_QuestionScroll> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewAnchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.checked && widget.showSolution) _scheduleReviewReveal();
  }

  @override
  void didUpdateWidget(covariant _QuestionScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    final questionChanged = oldWidget.question.id != widget.question.id;
    if (questionChanged && !(widget.checked && widget.showSolution)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
    }
    if (widget.checked &&
        widget.showSolution &&
        (!oldWidget.checked || !oldWidget.showSolution || questionChanged)) {
      _scheduleReviewReveal();
    }
  }

  void _scheduleReviewReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final anchor = _reviewAnchorKey.currentContext;
      if (anchor == null) return;
      Scrollable.ensureVisible(
        anchor,
        alignment: .34,
        duration: GaussMotion.resolve(
          context,
          const Duration(milliseconds: 420),
        ),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final ink = widget.ink;
    final index = widget.index;
    final selectedChoice = widget.selectedChoice;
    final checked = widget.checked;
    final busy = widget.busy;
    final covered = widget.covered;
    final errorTag = widget.errorTag;
    final showSolution = widget.showSolution;
    final onSelect = widget.onSelect;
    final onRevealChoices = widget.onRevealChoices;
    final onTagError = widget.onTagError;
    final onReportIssue = widget.onReportIssue;
    final onClearInk = widget.onClearInk;
    final onRestoreInk = widget.onRestoreInk;
    final textScale = MediaQuery.textScalerOf(context).scale(12);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final manuscriptInset = compact
        ? (textScale >= 18
              ? const EdgeInsets.fromLTRB(8, 6, 8, 22)
              : const EdgeInsets.fromLTRB(12, 6, 12, 22))
        : widget.inset;
    final review = showSolution && checked
        ? Column(
            key: const ValueKey('mission-manuscript-review'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(key: _reviewAnchorKey, height: 1),
              if (selectedChoice != null &&
                  selectedChoice != question.correctChoiceIndex) ...[
                _MissTagBar(
                  selected: errorTag,
                  onSelect: onTagError,
                  manuscript: true,
                ),
                const SizedBox(height: 14),
              ],
              _SolutionPanel(question: question, manuscript: true),
            ],
          )
        : null;
    return SingleChildScrollView(
      key: const ValueKey('mission-question-scroll'),
      controller: _scrollController,
      padding: manuscriptInset,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                explicitChildNodes: true,
                label:
                    'Question ${index + 1}. '
                    '${_blocksSemanticLabel(question.stem)}',
                child: QuestionManuscript(
                  key: const ValueKey('mission-question-paper'),
                  ink: ink,
                  questionNumber: index + 1,
                  difficulty: question.difficulty.label,
                  onExpandInk: () => showScratchpad(context, controller: ink),
                  onClearInk: onClearInk,
                  onRestoreInk: onRestoreInk,
                  reviewing: checked,
                  prompt: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ContentBlocksView(
                      blocks: question.stem,
                      textColor: GaussColors.parchmentInk,
                      textStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            color: GaussColors.parchmentInk,
                            fontFamily: 'Vazirmatn',
                            fontSize: 18,
                            height: 1.65,
                          ),
                    ),
                  ),
                  answers: covered && !checked
                      ? _CoveredChoicesPanel(
                          onReveal: busy ? null : onRevealChoices,
                          manuscript: true,
                        )
                      : ManuscriptAnswerGrid(
                          key: const ValueKey('mission-answer-manuscript'),
                          children: [
                            for (
                              var choice = 0;
                              choice < question.options.length;
                              choice++
                            )
                              _AnswerChoice(
                                blocks: question.options[choice],
                                choice: choice,
                                selected: selectedChoice == choice,
                                checked: checked,
                                correctChoice: question.correctChoiceIndex,
                                onTap: checked || busy
                                    ? null
                                    : () => onSelect(choice),
                                manuscript: true,
                              ),
                          ],
                        ),
                  review: review,
                ),
              ),
              const SizedBox(height: GaussSpacing.space8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OrbitalActionControl(
                  key: const ValueKey('mission-report-question-action'),
                  semanticLabel: 'Report a problem with this question',
                  onPressed: busy ? null : onReportIssue,
                  icon: Icons.flag_outlined,
                  dimension: 48,
                  accent: GaussColors.fog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoveredChoicesPanel extends StatelessWidget {
  const _CoveredChoicesPanel({required this.onReveal, this.manuscript = false});

  final VoidCallback? onReveal;
  final bool manuscript;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label:
        'Answer-first mode. The four choices are covered. Derive your answer, then uncover them to commit.',
    child: Container(
      key: const ValueKey('mission-covered-choices'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: manuscript
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GaussColors.panelHigh.withValues(alpha: .94),
                  GaussColors.ink.withValues(alpha: .96),
                ],
              ),
        color: manuscript ? const Color(0x12FFFFFF) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GaussColors.brass.withValues(alpha: .4)),
      ),
      child: Column(
        children: [
          const GaussScratchGlyph(color: GaussColors.brassLight, size: 34),
          const SizedBox(height: 12),
          const Text(
            'Choices are covered',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Derive the answer first, on paper or the scratchpad, so the options cannot steer you. Uncover them when your result is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GaussColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          OrbitalActionControl(
            key: const ValueKey('mission-reveal-choices-action'),
            semanticLabel: 'Uncover answer choices',
            caption: 'Uncover choices',
            onPressed: onReveal,
            icon: Icons.visibility_outlined,
            dimension: 56,
            accent: GaussColors.brassLight,
          ),
        ],
      ),
    ),
  );
}

class _MissTagBar extends StatelessWidget {
  const _MissTagBar({
    required this.selected,
    required this.onSelect,
    this.manuscript = false,
  });

  final String? selected;
  final ValueChanged<MissReason> onSelect;
  final bool manuscript;

  @override
  Widget build(BuildContext context) {
    final inkColor = manuscript
        ? GaussColors.parchmentInk
        : GaussColors.warning;
    return Semantics(
      container: true,
      label:
          'Why did this one slip? Optional private note; scoring never changes.',
      child: Container(
        key: manuscript
            ? const ValueKey('mission-manuscript-reflection')
            : null,
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        decoration: BoxDecoration(
          color: manuscript
              ? GaussParchmentInk.negativeWash
              : GaussColors.warning.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: manuscript
                ? GaussParchmentInk.negativeEdge
                : GaussColors.warning.withValues(alpha: .3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHY DID IT SLIP?',
              style: TextStyle(
                color: inkColor,
                fontSize: GaussTypeScale.caption,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final reason in MissReason.values)
                  _MissTagChip(
                    reason: reason,
                    selected: selected == reason.key,
                    onTap: () => onSelect(reason),
                    manuscript: manuscript,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A private note to your future self. Scoring never changes.',
              style: TextStyle(
                color: manuscript
                    ? GaussColors.parchmentInk.withValues(alpha: .62)
                    : GaussColors.fog,
                fontSize: GaussTypeScale.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissTagChip extends StatelessWidget {
  const _MissTagChip({
    required this.reason,
    required this.selected,
    required this.onTap,
    required this.manuscript,
  });

  final MissReason reason;
  final bool selected;
  final VoidCallback onTap;
  final bool manuscript;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: reason.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? manuscript
                    ? GaussParchmentInk.negativeTint
                    : GaussColors.warning.withValues(alpha: .16)
              : manuscript
              ? const Color(0x0D17120B)
              : GaussColors.deepInk,
          borderRadius: BorderRadius.circular(GaussRadii.pill),
          border: Border.all(
            color: selected ? GaussColors.warning : GaussColors.hairline,
          ),
        ),
        child: Text(
          reason.label,
          style: TextStyle(
            color: manuscript
                ? selected
                      ? GaussParchmentInk.negativeDeep
                      : GaussColors.parchmentInk.withValues(alpha: .76)
                : selected
                ? GaussColors.warning
                : GaussColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
