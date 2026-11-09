part of 'study_room_screen.dart';

class _ReflectionDeck extends StatelessWidget {
  const _ReflectionDeck({
    required this.record,
    required this.saving,
    required this.saveError,
    required this.onReflection,
    required this.onRetry,
  });

  final StudyRecord? record;
  final bool saving;
  final String? saveError;
  final ValueChanged<StudyReflection> onReflection;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final current = record?.reflection;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GaussColors.signal.withValues(alpha: .09),
            GaussColors.deepInk.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: current == null
              ? GaussColors.line
              : GaussColors.signal.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MiraCompanion(reflection: current),
              const SizedBox(width: 11),
              Expanded(
                child: Text(switch (current) {
                  null => 'How does the concept feel now?',
                  StudyReflection.clear => 'Concept marked clear',
                  StudyReflection.revisit => 'Saved to your revisit orbit',
                  StudyReflection.gem => 'Kept on your gem shelf',
                }, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (saving)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'This is your own study signal. It does not grade the reference answer or create a score.',
            style: TextStyle(
              color: GaussColors.fog,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (saveError != null) ...[
            const SizedBox(height: 12),
            _ReflectionSaveFailure(
              message: saveError!,
              retrying: saving,
              onRetry: onRetry,
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;
              final clear = _ReflectionButton(
                icon: Icons.check_circle_outline_rounded,
                label: 'Concept feels clear',
                selected: current == StudyReflection.clear,
                onPressed: saving
                    ? null
                    : () => onReflection(StudyReflection.clear),
              );
              final revisit = _ReflectionButton(
                icon: Icons.loop_rounded,
                label: 'Revisit later',
                selected: current == StudyReflection.revisit,
                onPressed: saving
                    ? null
                    : () => onReflection(StudyReflection.revisit),
              );
              final gem = _ReflectionButton(
                icon: Icons.auto_awesome_outlined,
                label: 'Keep as gem',
                selected: current == StudyReflection.gem,
                onPressed: saving
                    ? null
                    : () => onReflection(StudyReflection.gem),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    clear,
                    const SizedBox(height: 9),
                    revisit,
                    const SizedBox(height: 9),
                    gem,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: clear),
                  const SizedBox(width: 10),
                  Expanded(child: revisit),
                  const SizedBox(width: 10),
                  Expanded(child: gem),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReflectionSaveFailure extends StatelessWidget {
  const _ReflectionSaveFailure({
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  final String message;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label:
        'Field note not saved. $message No new mark is shown until the local ledger confirms it.',
    child: Container(
      key: const ValueKey('study-reflection-save-failure'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: GaussColors.warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GaussColors.warning.withValues(alpha: .5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: GaussColors.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Field note not saved',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: retrying ? null : onRetry,
            icon: retrying
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

/// Mira sits with the learner while the concept settles. She reacts to the
/// learner's own signal, never to the unverified source key.
class _MiraCompanion extends StatelessWidget {
  const _MiraCompanion({required this.reflection});

  final StudyReflection? reflection;

  @override
  Widget build(BuildContext context) {
    final settled = reflection != null && !reflection!.needsAnotherPass;
    return SizedBox.square(
      dimension: 54,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        child: Image.asset(
          settled
              ? 'assets/visual/mascot/mira_correct.png'
              : 'assets/visual/mascot/mira_thinking.png',
          key: ValueKey(settled),
          fit: BoxFit.contain,
          cacheHeight: 180,
          filterQuality: FilterQuality.medium,
          semanticLabel: settled
              ? 'Mira marks the concept as settled with you'
              : 'Mira is thinking with you',
        ),
      ),
    );
  }
}

/// A quiet celebration when a session, a unit, or a level completes. It reports
/// what the ledger recorded — never a claim about the source answer.
enum _StudyRecapAction { continueStudy }

class _StudyRecapContinuation {
  const _StudyRecapContinuation({
    required this.label,
    required this.route,
    this.returnToMap = false,
  });

  final String label;
  final String route;
  final bool returnToMap;
}

class _ReflectionButton extends StatelessWidget {
  const _ReflectionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          ),
  );
}
