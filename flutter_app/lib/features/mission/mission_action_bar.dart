part of 'mission_screen.dart';

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
    final accessibleActionHeight =
        MediaQuery.textScalerOf(context).scale(14) >= 20;
    final isCorrect = selectedChoice == question.correctChoiceIndex;
    final feedback = operationError != null
        ? 'Save interrupted. Retry.'
        : checked
        ? isCorrect
              ? 'Correct. Proof holds.'
              : question.solutionVerified
              ? 'Review the proof, then continue.'
              : 'Source answer shown. Report anything that looks off.'
        : null;
    final feedbackColor = operationError != null
        ? GaussColors.error
        : isCorrect
        ? GaussColors.signalBright
        : GaussColors.brassLight;
    final reading =
        feedback ??
        (selectedChoice == null ? 'Select an answer' : 'Ready to check');
    final compactReading = operationError != null
        ? 'Retry'
        : checked
        ? isCorrect
              ? 'Proof holds'
              : 'Review'
        : selectedChoice == null
        ? 'Select'
        : 'Ready';
    final readingIcon = operationError != null
        ? Icons.refresh_rounded
        : checked
        ? isCorrect
              ? Icons.verified_rounded
              : Icons.lightbulb_outline_rounded
        : selectedChoice == null
        ? Icons.touch_app_outlined
        : Icons.adjust_rounded;
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
        ? 6.0
        : math.max(10.0, safeBottom + 6.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, dockBottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(31),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                key: const ValueKey('mission-question-action-dock'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: GaussColors.deepInk.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(
                    color: GaussColors.brass.withValues(alpha: .26),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: !checked && !busy && operationError == null
                          ? IconButton.outlined(
                              key: const ValueKey('mission-skip-action'),
                              onPressed: onSkip,
                              tooltip: 'Skip this question',
                              icon: const Icon(
                                Icons.fast_forward_rounded,
                                size: 20,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: GaussSpacing.space8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: accessibleActionHeight ? 70 : 52,
                        ),
                        child: _MissionReadinessSignal(
                          semanticLabel: reading,
                          label: compactReading,
                          icon: readingIcon,
                          color: feedback == null
                              ? GaussColors.fog
                              : feedbackColor,
                          live: feedback != null,
                        ),
                      ),
                    ),
                    const SizedBox(width: GaussSpacing.space8),
                    _MissionPrimaryOrbit(
                      busy: busy,
                      checked: checked,
                      finalQuestion: index == total - 1,
                      operationError: operationError != null,
                      semanticLabel: primaryLabel,
                      onPressed: primaryAction,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionReadinessSignal extends StatelessWidget {
  const _MissionReadinessSignal({
    required this.semanticLabel,
    required this.label,
    required this.icon,
    required this.color,
    required this.live,
  });

  final String semanticLabel;
  final String label;
  final IconData icon;
  final Color color;
  final bool live;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('mission-readiness-signal'),
    liveRegion: live,
    label: semanticLabel,
    excludeSemantics: true,
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GaussSpacing.space8,
        runSpacing: GaussSpacing.space4,
        children: [
          Icon(icon, size: 16, color: color),
          Text(
            label,
            key: ValueKey('mission-action-reading-$semanticLabel'),
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: color,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
              height: 1.15,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissionPrimaryOrbit extends StatelessWidget {
  const _MissionPrimaryOrbit({
    required this.busy,
    required this.checked,
    required this.finalQuestion,
    required this.operationError,
    required this.semanticLabel,
    required this.onPressed,
  });

  final bool busy;
  final bool checked;
  final bool finalQuestion;
  final bool operationError;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: 52,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return OrbitalActionControl(
      key: const ValueKey('mission-primary-action'),
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      icon: operationError
          ? Icons.refresh_rounded
          : checked
          ? finalQuestion
                ? Icons.flag_rounded
                : Icons.arrow_forward_rounded
          : Icons.check_rounded,
      accent: operationError
          ? GaussColors.error
          : checked
          ? GaussColors.signalBright
          : GaussColors.brassLight,
      dimension: 52,
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
