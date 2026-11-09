part of 'study_room_screen.dart';

class _ArchivePage extends StatelessWidget {
  const _ArchivePage({
    required this.question,
    required this.revealed,
    required this.hypothesis,
    required this.record,
    required this.saving,
    required this.saveError,
    required this.active,
    required this.ink,
    required this.questionNumber,
    required this.onExpandInk,
    required this.onClearInk,
    required this.onRestoreInk,
    required this.onInkModeChanged,
    required this.onHypothesis,
    required this.onReveal,
    required this.onReflection,
    required this.onRetryReflection,
    super.key,
  });

  final Question question;
  final bool revealed;
  final int? hypothesis;
  final StudyRecord? record;
  final bool saving;
  final String? saveError;
  final bool active;
  final ScratchInkController ink;
  final int questionNumber;
  final VoidCallback onExpandInk;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;
  final ValueChanged<bool> onInkModeChanged;
  final ValueChanged<int> onHypothesis;
  final VoidCallback onReveal;
  final ValueChanged<StudyReflection> onReflection;
  final VoidCallback onRetryReflection;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = GaussViewport.fromSize(constraints.biggest);
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final split = viewport.supportsTwoPane && textScale < 1.6;
      if (!split) {
        return SingleChildScrollView(
          key: const ValueKey('study-room-single-pane'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _manuscript(context),
                  ..._postRevealContent(context),
                ],
              ),
            ),
          ),
        );
      }
      return Padding(
        key: const ValueKey('study-room-split-pane'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    key: const ValueKey('study-room-prompt-scroll'),
                    padding: const EdgeInsets.fromLTRB(2, 2, 10, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_manuscript(context)],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: GaussColors.deepInk.withValues(alpha: .76),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GaussColors.hairline),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      key: const ValueKey('study-room-response-scroll'),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _postRevealContent(
                          context,
                          includeHeading: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _manuscript(BuildContext context) => QuestionManuscript(
    key: const ValueKey('study-room-question-paper'),
    ink: ink,
    active: active,
    questionNumber: questionNumber,
    difficulty: question.difficulty.label,
    onDrawingChanged: onInkModeChanged,
    onExpandInk: onExpandInk,
    onClearInk: onClearInk,
    onRestoreInk: onRestoreInk,
    prompt: Directionality(
      key: ValueKey('study-ink-${question.id}'),
      textDirection: TextDirection.rtl,
      child: ContentBlocksView(
        blocks: question.stem,
        textColor: GaussColors.parchmentInk,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: GaussColors.parchmentInk,
          fontFamily: 'Vazirmatn',
          fontSize: 18,
          height: 1.65,
        ),
      ),
    ),
    answers: Column(
      key: const ValueKey('study-room-answer-manuscript'),
      children: [
        for (var choice = 0; choice < question.options.length; choice++)
          _ArchiveChoice(
            blocks: question.options[choice],
            choice: choice,
            selected: hypothesis == choice,
            enabled: !revealed,
            markedBySource: revealed && choice == question.correctChoiceIndex,
            onTap: () => onHypothesis(choice),
            manuscript: true,
          ),
        if (!revealed) ...[
          const SizedBox(height: GaussSpacing.space8),
          Center(
            child: OrbitalActionControl(
              key: const ValueKey('study-room-reveal-source-action'),
              semanticLabel: 'Reveal the unverified source answer',
              icon: Icons.visibility_outlined,
              dimension: 56,
              accent: GaussParchmentInk.brass,
              onPressed: onReveal,
            ),
          ),
        ],
      ],
    ),
  );

  List<Widget> _postRevealContent(
    BuildContext context, {
    bool includeHeading = false,
  }) => [
    if (includeHeading) ...[
      _WorkspaceHeading(revealed: revealed),
      const SizedBox(height: 16),
    ],
    if (revealed) ...[
      const SizedBox(height: 18),
      _HypothesisComparison(
        hypothesis: hypothesis,
        sourceKey: question.correctChoiceIndex,
      ),
      const SizedBox(height: 12),
      _SourceSolution(question: question),
      const SizedBox(height: 12),
      _ReflectionDeck(
        record: record,
        saving: saving,
        saveError: saveError,
        onReflection: onReflection,
        onRetry: onRetryReflection,
      ),
    ],
  ];
}

class _WorkspaceHeading extends StatelessWidget {
  const _WorkspaceHeading({required this.revealed});

  final bool revealed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: GaussMetrics.minTouchTarget,
        height: GaussMetrics.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GaussColors.brass.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(color: GaussColors.brass.withValues(alpha: .35)),
        ),
        child: Icon(
          revealed ? Icons.history_edu_outlined : Icons.edit_note_rounded,
          color: GaussColors.brassLight,
          size: 21,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESPONSE DECK',
              style: TextStyle(
                color: GaussColors.brassLight,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              revealed ? 'Source and reflection' : 'Make a private call',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ],
  );
}

/// One glance: what the learner committed to, beside what the source claims.
/// Agreement is stated as agreement — never as "correct".
class _HypothesisComparison extends StatelessWidget {
  const _HypothesisComparison({
    required this.hypothesis,
    required this.sourceKey,
  });

  final int? hypothesis;
  final int sourceKey;

  static String _letter(int choice) => String.fromCharCode(65 + choice);

  @override
  Widget build(BuildContext context) {
    final matched = hypothesis != null && hypothesis == sourceKey;
    final headline = hypothesis == null
        ? 'You revealed without committing'
        : matched
        ? 'Your call agrees with the source'
        : 'Your call differs from the source';
    final accent = hypothesis == null
        ? GaussColors.fog
        : matched
        ? GaussColors.signalBright
        : GaussColors.warning;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$headline. '
          '${hypothesis == null ? '' : 'Your call was choice ${_letter(hypothesis!)}. '}'
          'The unverified source names choice ${_letter(sourceKey)}.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: .32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ComparisonChip(
                    label: 'MY CALL',
                    value: hypothesis == null ? '—' : _letter(hypothesis!),
                    color: hypothesis == null
                        ? GaussColors.fog
                        : GaussColors.brassLight,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ComparisonChip(
                    label: 'SOURCE KEY',
                    value: _letter(sourceKey),
                    color: GaussColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Text(
              'Agreement is not proof: the source key itself was never verified. Trust your own reading of the solution.',
              style: TextStyle(
                color: GaussColors.fog,
                fontSize: GaussTypeScale.caption,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonChip extends StatelessWidget {
  const _ComparisonChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: GaussTypeScale.insignia,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ArchiveChoice extends StatelessWidget {
  const _ArchiveChoice({
    required this.blocks,
    required this.choice,
    required this.selected,
    required this.enabled,
    required this.markedBySource,
    required this.onTap,
    this.manuscript = false,
  });

  final List<ContentBlock> blocks;
  final int choice;
  final bool selected;
  final bool enabled;
  final bool markedBySource;
  final VoidCallback onTap;
  final bool manuscript;

  @override
  Widget build(BuildContext context) {
    final tone = markedBySource
        ? TheoremChoiceTone.source
        : selected
        ? TheoremChoiceTone.selected
        : TheoremChoiceTone.neutral;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      onTap: enabled ? onTap : null,
      label:
          'Choice ${choice + 1}.'
          '${selected ? ' Your private hypothesis.' : ''}'
          '${markedBySource ? ' Marked as the answer by the unverified source.' : ''}',
      child: manuscript
          ? ManuscriptChoiceShell(
              tone: tone,
              onTap: enabled ? onTap : null,
              emblem: markedBySource
                  ? const Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: GaussParchmentInk.brass,
                    )
                  : selected
                  ? const Icon(
                      Icons.edit_note_rounded,
                      size: 19,
                      color: GaussParchmentInk.teal,
                    )
                  : Text(
                      String.fromCharCode(65 + choice),
                      style: const TextStyle(
                        color: GaussColors.parchmentInk,
                        fontFamily: 'serif',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              child: ContentBlocksView(
                blocks: blocks,
                compact: true,
                textColor: GaussColors.parchmentInk,
              ),
            )
          : TheoremChoiceShell(
              tone: tone,
              onTap: enabled ? onTap : null,
              emblem: markedBySource
                  ? const Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: GaussColors.warning,
                    )
                  : selected
                  ? const Icon(
                      Icons.edit_note_rounded,
                      size: 19,
                      color: GaussColors.brassLight,
                    )
                  : Text(
                      String.fromCharCode(65 + choice),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
              child: ContentBlocksView(blocks: blocks, compact: true),
            ),
    );
  }
}

class _SourceSolution extends StatelessWidget {
  const _SourceSolution({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_edu_outlined,
                color: GaussColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source explanation — unverified',
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Preserved exactly as imported. Gauss has not confirmed that this reasoning matches the marked answer.',
            style: TextStyle(color: GaussColors.fog, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 14),
          ContentBlocksView(blocks: question.solution),
          if (question.shortcut case final shortcut?) ...[
            const Divider(height: 28),
            const Text(
              'Source shortcut',
              style: TextStyle(
                color: GaussColors.warning,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ContentBlocksView(blocks: shortcut),
          ],
        ],
      ),
    ),
  );
}
