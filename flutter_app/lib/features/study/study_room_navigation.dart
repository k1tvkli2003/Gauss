part of 'study_room_screen.dart';

/// Jump anywhere in the current set. Each tile carries its own state so the
/// learner can steer toward unread questions or back to a marked one.
class _JumpSheet extends StatelessWidget {
  const _JumpSheet({
    required this.shelf,
    required this.records,
    required this.encounteredSlotIds,
    required this.currentIndex,
  });

  final StudyShelf shelf;
  final Map<String, StudyRecord> records;
  final Set<String> encounteredSlotIds;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final firstUnread =
        List<int>.generate(shelf.questions.length, (index) => index).indexWhere(
          (index) {
            final slot = shelf.slots[index];
            return slot.planned
                ? !encounteredSlotIds.contains(slot.id)
                : !records.containsKey(shelf.questions[index].id);
          },
        );
    return DraggableScrollableSheet(
      initialChildSize: .62,
      minChildSize: .35,
      maxChildSize: .92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: GaussColors.ink,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: GaussColors.line)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'JUMP TO',
                          style: TextStyle(
                            color: GaussColors.brassLight,
                            fontSize: GaussTypeScale.insignia,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${shelf.questions.length} questions in this session',
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (firstUnread >= 0)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(firstUnread),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text('First unread'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 62,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 1,
                ),
                itemCount: shelf.questions.length,
                itemBuilder: (context, index) {
                  final slot = shelf.slots[index];
                  final encountered =
                      !slot.planned || encounteredSlotIds.contains(slot.id);
                  return _JumpTile(
                    number: index + 1,
                    current: index == currentIndex,
                    record: encountered
                        ? records[shelf.questions[index].id]
                        : null,
                    masteryReview: slot.kind == 'mastery_review',
                    encountered: encountered,
                    onTap: () => Navigator.of(context).pop(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpTile extends StatelessWidget {
  const _JumpTile({
    required this.number,
    required this.current,
    required this.record,
    required this.masteryReview,
    required this.encountered,
    required this.onTap,
  });

  final int number;
  final bool current;
  final StudyRecord? record;
  final bool masteryReview;
  final bool encountered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reflection = record?.reflection;
    final accent = switch (reflection) {
      null => GaussColors.line,
      StudyReflection.clear => GaussColors.signalBright,
      StudyReflection.revisit => GaussColors.warning,
      StudyReflection.gem => GaussColors.brassLight,
    };
    final stateLabel = switch (reflection) {
      null when masteryReview && !encountered => 'mastery review pending',
      null => 'not charted',
      StudyReflection.clear => 'clear',
      StudyReflection.revisit => 'revisit',
      StudyReflection.gem => 'gem',
    };
    return Semantics(
      button: true,
      selected: current,
      label: 'Question $number, $stateLabel',
      child: InkWell(
        key: ValueKey('study-room-jump-question-$number'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: reflection == null
                ? GaussColors.raised
                : accent.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: current ? GaussColors.ivory : accent,
              width: current ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  color: reflection == null ? GaussColors.muted : accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              if (reflection != null)
                Icon(
                  switch (reflection) {
                    StudyReflection.clear => Icons.check_rounded,
                    StudyReflection.revisit => Icons.loop_rounded,
                    StudyReflection.gem => Icons.auto_awesome_outlined,
                  },
                  size: 11,
                  color: accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveNavBar extends StatelessWidget {
  const _ArchiveNavBar({
    required this.index,
    required this.total,
    required this.reflected,
    required this.ink,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
    required this.onOpenInkWorkspace,
    required this.onClearInk,
    required this.onRestoreInk,
  });

  final int index;
  final int total;
  final bool reflected;
  final ScratchInkController ink;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onJump;
  final VoidCallback onOpenInkWorkspace;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              key: const ValueKey('study-room-navigation-dock'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: GaussColors.deepInk.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .24),
                ),
              ),
              child: AnimatedBuilder(
                animation: ink,
                builder: (context, _) => Row(
                  children: [
                    IconButton.outlined(
                      key: const ValueKey('study-room-previous-action'),
                      onPressed: onPrevious,
                      tooltip: 'Previous question',
                      icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    ),
                    const SizedBox(width: GaussSpacing.space8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.textScalerOf(context).scale(14) >= 20
                              ? 70
                              : 60,
                        ),
                        child: AnimatedSwitcher(
                          duration: GaussMotion.resolve(
                            context,
                            GaussMotion.standard,
                          ),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: ink.isEmpty || ink.canRestoreClearedInk
                              ? ink.canRestoreClearedInk
                                    ? _ArchiveInkRestore(
                                        onRestore: onRestoreInk,
                                      )
                                    : _ArchiveQuestionPosition(
                                        index: index,
                                        total: total,
                                        reflected: reflected,
                                        onJump: onJump,
                                      )
                              : _ArchiveInkControls(
                                  ink: ink,
                                  onExpand: onOpenInkWorkspace,
                                  onClear: onClearInk,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: GaussSpacing.space8),
                    OrbitalActionControl(
                      key: const ValueKey('study-room-next-action'),
                      semanticLabel: 'Next question',
                      onPressed: onNext,
                      icon: Icons.arrow_forward_rounded,
                      dimension: GaussMetrics.minTouchTarget,
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

class _ArchiveQuestionPosition extends StatelessWidget {
  const _ArchiveQuestionPosition({
    required this.index,
    required this.total,
    required this.reflected,
    required this.onJump,
  });

  final int index;
  final int total;
  final bool reflected;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) => Semantics(
    button: total > 1,
    label:
        'Question ${index + 1} of $total'
        '${reflected ? ', charted' : ''}. Jump to a question.',
    child: Tooltip(
      message: 'Jump to a question',
      child: InkWell(
        key: const ValueKey('study-room-jump-action'),
        onTap: total <= 1 ? null : onJump,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GaussSpacing.space4,
            vertical: GaussSpacing.space4,
          ),
          child: QuestionProgressRail(
            index: index,
            total: total,
            label: reflected ? 'CHARTED' : 'QUESTION',
            valueText: '${index + 1} of $total',
            valueKey: const ValueKey('study-room-navigation-position'),
          ),
        ),
      ),
    ),
  );
}

class _ArchiveInkControls extends StatelessWidget {
  const _ArchiveInkControls({
    required this.ink,
    required this.onExpand,
    required this.onClear,
  });

  final ScratchInkController ink;
  final VoidCallback onExpand;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Question ink controls',
    child: Row(
      key: const ValueKey('study-room-ink-controls'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          key: const ValueKey('study-room-ink-undo'),
          onPressed: ink.canUndo ? ink.undo : null,
          tooltip: 'Undo last ink stroke',
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton(
          key: const ValueKey('study-room-ink-expand'),
          onPressed: onExpand,
          tooltip: 'Open full scratchpad',
          icon: const Icon(Icons.open_in_full_rounded),
        ),
        IconButton(
          key: const ValueKey('study-room-ink-clear'),
          onPressed: onClear,
          tooltip: 'Clear question ink',
          color: GaussColors.error,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    ),
  );
}

class _ArchiveInkRestore extends StatelessWidget {
  const _ArchiveInkRestore({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Question ink cleared',
    child: Center(
      child: TextButton.icon(
        key: const ValueKey('study-room-ink-restore'),
        onPressed: onRestore,
        icon: const Icon(Icons.undo_rounded, color: GaussColors.brassLight),
        label: const Text('Restore ink'),
      ),
    ),
  );
}

class _ArchiveMessage extends StatelessWidget {
  const _ArchiveMessage({
    required this.title,
    required this.detail,
    required this.onLeave,
    this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback onLeave;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => GaussStatePanel(
    title: title,
    detail: detail,
    icon: onRetry == null
        ? Icons.auto_stories_outlined
        : Icons.error_outline_rounded,
    accent: onRetry == null ? GaussColors.brass : GaussColors.error,
    actions: Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton(onPressed: onLeave, child: const Text('Back')),
        if (onRetry != null)
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
      ],
    ),
  );
}
