part of 'mission_screen.dart';

/// The answer dock. Before checking it offers one plain decision (Check),
/// with Skip as the quiet alternative. After checking, a result strip rises
/// from the dock (SonusKt contextual bar: slide up + fade) and the dock takes
/// the result's tint, so the outcome reads before any text is parsed.
class _MissionActionBar extends StatelessWidget {
  const _MissionActionBar({
    required this.question,
    required this.index,
    required this.total,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.operationError,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
  });

  final Question question;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final Object? operationError;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  VoidCallback? get primaryAction {
    if (busy) return null;
    if (operationError != null) {
      if (checked) return onNext;
      return selectedChoice == null ? onSkip : onCheck;
    }
    if (checked) return onNext;
    return selectedChoice == null ? null : onCheck;
  }

  String get primaryLabel {
    if (busy) return 'Saving…';
    if (operationError != null) return 'Try again';
    if (!checked) return 'Check answer';
    return index == total - 1 ? 'Finish mission' : 'Next question';
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedChoice == question.correctChoiceIndex;
    final answerNumber = question.correctChoiceIndex + 1;
    final _DockResult? result = operationError != null
        ? const _DockResult(
            title: 'Save interrupted',
            detail: 'This answer is not recorded yet. Try again.',
            icon: Icons.refresh_rounded,
            color: GaussColors.error,
          )
        : !checked
        ? null
        : isCorrect
        ? const _DockResult(
            title: 'Correct',
            detail: 'The proof holds.',
            icon: Icons.check_rounded,
            color: GaussColors.signalBright,
          )
        : _DockResult(
            title: selectedChoice == null ? 'Skipped' : 'Not this one',
            detail: question.solutionVerified
                ? 'The answer is choice $answerNumber. The solution is below.'
                : 'The source marks choice $answerNumber. Its solution is below.',
            icon: selectedChoice == null
                ? Icons.fast_forward_rounded
                : Icons.close_rounded,
            color: GaussColors.error,
          );
    final reading = result == null
        ? (selectedChoice == null ? 'Select an answer' : 'Ready to check')
        : '${result.title}. ${result.detail}';
    final safeBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    // The stage-level SafeArea normally consumes Android's navigation inset.
    // Only own a bottom inset here when this dock is embedded without that
    // ancestor (for example in a focused widget harness). This prevents the
    // navigation clearance from being counted twice on real devices.
    final stageAlreadyInset = MediaQuery.paddingOf(context).bottom == 0;
    final dockBottom = stageAlreadyInset
        ? 8.0
        : math.max(10.0, safeBottom + 8.0);
    final motion = GaussMotion.resolve(
      context,
      const Duration(milliseconds: 260),
    );
    final tint = result?.color;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, dockBottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedContainer(
            key: const ValueKey('mission-question-action-dock'),
            duration: motion,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(GaussSpacing.space8),
            decoration: BoxDecoration(
              // Opaque fill, no backdrop blur: the dock sits over a static
              // backdrop, and a blur would re-rasterize on every ink frame.
              color: tint == null
                  ? GaussColors.deepInk
                  : Color.alphaBlend(
                      tint.withValues(alpha: .14),
                      GaussColors.deepInk,
                    ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: tint?.withValues(alpha: .5) ?? GaussColors.hairline,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  key: const ValueKey('mission-readiness-signal'),
                  liveRegion: result != null,
                  label: reading,
                  excludeSemantics: true,
                  child: AnimatedSwitcher(
                    duration: motion,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.bottomCenter,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, .35),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                    ),
                    child: result == null
                        ? const SizedBox(
                            key: ValueKey('mission-dock-idle'),
                            width: double.infinity,
                          )
                        : _DockResultStrip(
                            key: ValueKey('mission-dock-${result.title}'),
                            result: result,
                            // At large text the detail would take a third of
                            // the screen from the solution; the title stays,
                            // and the full sentence remains in semantics.
                            showDetail:
                                MediaQuery.textScalerOf(context).scale(1) < 1.5,
                          ),
                  ),
                ),
                Row(
                  children: [
                    if (!checked && !busy && operationError == null) ...[
                      TextButton(
                        key: const ValueKey('mission-skip-action'),
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: GaussColors.fog,
                          minimumSize: const Size(64, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: GaussSpacing.space8),
                    ],
                    Expanded(
                      child: _MissionPrimaryButton(
                        busy: busy,
                        label: primaryLabel,
                        tint: result?.color,
                        icon: operationError != null
                            ? Icons.refresh_rounded
                            : checked
                            ? index == total - 1
                                  ? Icons.flag_rounded
                                  : Icons.arrow_forward_rounded
                            : null,
                        onPressed: primaryAction,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockResult {
  const _DockResult({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}

class _DockResultStrip extends StatelessWidget {
  const _DockResultStrip({
    required this.result,
    required this.showDetail,
    super.key,
  });

  final _DockResult result;
  final bool showDetail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: result.color,
            shape: BoxShape.circle,
          ),
          child: Icon(result.icon, size: 22, color: GaussColors.deepInk),
        ),
        const SizedBox(width: GaussSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                result.title,
                key: ValueKey('mission-action-reading-${result.title}'),
                softWrap: true,
                style: TextStyle(
                  color: result.color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              if (showDetail) ...[
                const SizedBox(height: 2),
                Text(
                  result.detail,
                  softWrap: true,
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: GaussTypeScale.body,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _MissionPrimaryButton extends StatelessWidget {
  const _MissionPrimaryButton({
    required this.busy,
    required this.label,
    required this.tint,
    required this.icon,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final Color? tint;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fill = tint ?? GaussColors.brass;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      softWrap: true,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
    );
    return FilledButton(
      key: const ValueKey('mission-primary-action'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: GaussColors.deepInk,
        disabledBackgroundColor: GaussColors.ivory.withValues(alpha: .08),
        disabledForegroundColor: GaussColors.fog,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ),
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: GaussSpacing.space8),
                Flexible(child: text),
              ],
            )
          : icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: text),
                const SizedBox(width: GaussSpacing.space8),
                Icon(icon, size: 20),
              ],
            ),
    );
  }
}

String _blocksSemanticLabel(List<ContentBlock> blocks) => blocks
    .map(
      (block) => switch (block) {
        TextBlock(:final text) => normalizeLearningDigits(text),
        ImageBlock(:final alt) =>
          alt.isEmpty ? 'Question image' : normalizeLearningDigits(alt),
      },
    )
    .where((text) => text.trim().isNotEmpty)
    .join('. ');
