part of 'mission_screen.dart';

class _MissionComplete extends StatelessWidget {
  const _MissionComplete({
    required this.correct,
    required this.total,
    required this.completion,
    required this.ritualComplete,
    required this.onSkipRitual,
    required this.onMap,
    required this.onRetry,
  });
  final int correct;
  final int total;
  final MissionCompletion completion;
  final bool ritualComplete;
  final VoidCallback onSkipRitual;
  final VoidCallback onMap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final rewards = <String, int>{};
    for (final line in completion.lines) {
      rewards.update(
        line.reason,
        (amount) => amount + line.amount,
        ifAbsent: () => line.amount,
      );
    }

    final accuracy = total == 0 ? 0.0 : correct / total;
    final headline = accuracy == 1
        ? 'Perfect orbit'
        : accuracy >= .8
        ? 'Orbit secured'
        : 'Mission charted';
    final detail = accuracy == 1
        ? 'Every proof aligned. This five-point orbit is now complete.'
        : accuracy >= .8
        ? 'A strong signal is recorded. The missed coordinate is ready for a calm revisit.'
        : 'Every miss is now a useful revisit coordinate. Your progress is safely recorded.';
    final semanticSummary = StringBuffer(
      '$headline. $correct of $total correct. '
      '${completion.xpEarned} XP earned. ${completion.totalXp} total XP.',
    );
    for (final reward in rewards.entries) {
      semanticSummary.write(' ${reward.key}, ${reward.value} XP.');
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MissionBackdrop(),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('mission-completion-scroll'),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Semantics(
                        key: const ValueKey('mission-completion-screen'),
                        container: true,
                        liveRegion: true,
                        label: semanticSummary.toString(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                GaussColors.deepInk.withValues(alpha: .82),
                                GaussColors.abyss.withValues(alpha: .94),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              GaussRadii.large,
                            ),
                            border: Border.all(
                              color: GaussColors.brass.withValues(alpha: .34),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(GaussSpacing.space16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final textHeight = MediaQuery.textScalerOf(
                                  context,
                                ).scale(14);
                                final wide =
                                    constraints.maxWidth >= 700 &&
                                    textHeight < 20;
                                final visual = _MissionCompletionVisual(
                                  accuracy: accuracy,
                                  correct: correct,
                                  total: total,
                                  compact: !wide,
                                  ritualComplete: ritualComplete,
                                  onSkipRitual: onSkipRitual,
                                );
                                final summary = _MissionCompletionSummary(
                                  total: total,
                                  headline: headline,
                                  detail: detail,
                                  completion: completion,
                                  rewards: rewards,
                                );
                                if (!wide) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      visual,
                                      const SizedBox(
                                        height: GaussSpacing.space12,
                                      ),
                                      summary,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 296, child: visual),
                                    const SizedBox(width: GaussSpacing.space24),
                                    Expanded(child: summary),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _MissionCompletionDock(onRetry: onRetry, onMap: onMap),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionCompletionVisual extends StatelessWidget {
  const _MissionCompletionVisual({
    required this.accuracy,
    required this.correct,
    required this.total,
    required this.compact,
    required this.ritualComplete,
    required this.onSkipRitual,
  });

  final double accuracy;
  final int correct;
  final int total;
  final bool compact;
  final bool ritualComplete;
  final VoidCallback onSkipRitual;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final showRitual = !reducedMotion && !ritualComplete;
    final ritual = showRitual
        ? Semantics(
            container: true,
            button: true,
            enabled: true,
            label: 'Skip celebration',
            onTap: onSkipRitual,
            child: IconButton.filledTonal(
              key: const ValueKey('mission-skip-ritual-action'),
              tooltip: null,
              onPressed: onSkipRitual,
              icon: const Icon(Icons.close_rounded),
              color: GaussColors.ivory,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            ),
          )
        : const SizedBox.shrink();

    Widget scene(double reveal) => Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _MissionCompletionOrbitPainter(reveal: reveal),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Transform.scale(
            scale: .94 + reveal * .06,
            child: Image.asset(
              opacity: AlwaysStoppedAnimation(reveal),
              accuracy >= .7
                  ? 'assets/visual/mascot/mira_correct.png'
                  : 'assets/visual/mascot/mira_thinking.png',
              height: compact ? 178 : 264,
              fit: BoxFit.contain,
              cacheHeight: compact ? 534 : 792,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Positioned(
          bottom: compact ? 0 : 8,
          child: _ScoreSeal(accuracy: accuracy, correct: correct, total: total),
        ),
      ],
    );

    final receipt = SizedBox(
      height: compact ? 218 : 330,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: showRitual
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: GaussMotion.ceremonial,
                      curve: Curves.easeOutCubic,
                      builder: (context, reveal, _) => scene(reveal),
                    )
                  : scene(1),
            ),
          ),
          if (showRitual) PositionedDirectional(top: 2, end: 2, child: ritual),
        ],
      ),
    );
    return receipt;
  }
}

class _MissionCompletionSummary extends StatelessWidget {
  const _MissionCompletionSummary({
    required this.total,
    required this.headline,
    required this.detail,
    required this.completion,
    required this.rewards,
  });

  final int total;
  final String headline;
  final String detail;
  final MissionCompletion completion;
  final Map<String, int> rewards;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: GaussWordmark(width: 118),
      ),
      const SizedBox(height: GaussSpacing.space12),
      Text(
        '$total-question mission',
        style: const TextStyle(
          color: GaussColors.brassLight,
          fontSize: GaussTypeScale.caption,
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
      const SizedBox(height: GaussSpacing.space4),
      Text(
        headline,
        key: const ValueKey('mission-completion-headline'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: GaussSpacing.space8),
      Text(
        detail,
        style: const TextStyle(color: GaussColors.muted, height: 1.5),
      ),
      const SizedBox(height: GaussSpacing.space16),
      _MissionCompletionMetrics(completion: completion),
      if (completion.levelAfter > completion.levelBefore) ...[
        const SizedBox(height: GaussSpacing.space12),
        Semantics(
          label: 'Level ${completion.levelAfter} reached',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GaussColors.brass.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(GaussRadii.medium),
              border: Border.all(
                color: GaussColors.brass.withValues(alpha: .42),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: GaussColors.brassLight,
                ),
                const SizedBox(width: GaussSpacing.space8),
                Expanded(
                  child: Text(
                    'Level ${completion.levelAfter} reached',
                    style: const TextStyle(
                      color: GaussColors.brassLight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: GaussSpacing.space12),
      _MissionRewardReceipt(rewards: rewards),
    ],
  );
}

class _MissionCompletionMetrics extends StatelessWidget {
  const _MissionCompletionMetrics({required this.completion});

  final MissionCompletion completion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final accessible =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) >= 20;
      final earned = _CompletionMetric(
        icon: Icons.bolt_rounded,
        label: 'This mission',
        value: completion.xpEarned > 0
            ? '+${completion.xpEarned} XP'
            : 'XP cap met',
        color: GaussColors.signalBright,
      );
      final total = _CompletionMetric(
        icon: Icons.explore_rounded,
        label: 'Private total',
        value: '${completion.totalXp} XP',
        color: GaussColors.brassLight,
      );
      if (accessible) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [earned, const SizedBox(height: 8), total],
        );
      }
      return Row(
        children: [
          Expanded(child: earned),
          const SizedBox(width: 8),
          Expanded(child: total),
        ],
      );
    },
  );
}

class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(GaussRadii.medium),
      border: Border.all(color: color.withValues(alpha: .34)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.caption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MissionRewardReceipt extends StatelessWidget {
  const _MissionRewardReceipt({required this.rewards});

  final Map<String, int> rewards;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Recorded XP receipt',
    child: Container(
      key: const ValueKey('mission-reward-receipt'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GaussColors.deepInk.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(GaussRadii.medium),
        border: Border.all(color: GaussColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Recorded XP',
            style: TextStyle(
              color: GaussColors.fog,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          if (rewards.isEmpty)
            const Text(
              'Mission recorded. Today’s reward cap was already met.',
              style: TextStyle(color: GaussColors.muted, height: 1.45),
            )
          else
            for (final reward in rewards.entries)
              _MissionRewardLine(reason: reward.key, amount: reward.value),
        ],
      ),
    ),
  );
}

class _MissionRewardLine extends StatelessWidget {
  const _MissionRewardLine({required this.reason, required this.amount});

  final String reason;
  final int amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 250 ||
            MediaQuery.textScalerOf(context).scale(14) >= 20;
        final reasonWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TheoremStarMark(size: 16),
            const SizedBox(width: 8),
            Flexible(child: Text(reason)),
          ],
        );
        final amountWidget = Text(
          '+$amount XP',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: GaussColors.signalBright,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              reasonWidget,
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 24),
                child: amountWidget,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: reasonWidget),
            const SizedBox(width: 12),
            amountWidget,
          ],
        );
      },
    ),
  );
}

class _MissionCompletionDock extends StatelessWidget {
  const _MissionCompletionDock({required this.onRetry, required this.onMap});

  final VoidCallback onRetry;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              key: const ValueKey('mission-completion-actions'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
              decoration: BoxDecoration(
                color: GaussColors.deepInk.withValues(alpha: .93),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: OrbitalActionControl(
                        key: const ValueKey('mission-retry-action'),
                        semanticLabel: 'Start another mission',
                        caption: 'New mission',
                        onPressed: onRetry,
                        icon: Icons.replay_rounded,
                        dimension: 52,
                        accent: GaussColors.ice,
                      ),
                    ),
                  ),
                  const SizedBox(width: GaussSpacing.space12),
                  Expanded(
                    child: Center(
                      child: OrbitalActionControl(
                        key: const ValueKey('mission-map-action'),
                        semanticLabel: 'Return to map',
                        caption: 'Return to map',
                        onPressed: onMap,
                        icon: Icons.map_outlined,
                        dimension: 58,
                        accent: GaussColors.signalBright,
                      ),
                    ),
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

class _ScoreSeal extends StatelessWidget {
  const _ScoreSeal({
    required this.accuracy,
    required this.correct,
    required this.total,
  });

  final double accuracy;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '$correct of $total correct, ${(accuracy * 100).round()} percent accuracy',
    excludeSemantics: true,
    child: Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GaussColors.deepInk.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        border: Border.all(color: GaussColors.brassLight),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 16)],
      ),
      child: Text(
        '$correct / $total · ${(accuracy * 100).round()}%',
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GaussColors.ivory,
          fontWeight: FontWeight.w900,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

class _MissionCompletionOrbitPainter extends CustomPainter {
  const _MissionCompletionOrbitPainter({required this.reveal});

  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .38;
    final glow = Paint()
      ..color = GaussColors.brass.withValues(alpha: .16 * reveal)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * .86, glow);

    for (final ratio in const [.62, .82, 1.0]) {
      canvas.drawCircle(
        center,
        radius * ratio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ratio == 1 ? 1.2 : .7
          ..color = GaussColors.brass.withValues(
            alpha: (ratio == 1 ? .38 : .2) * reveal,
          ),
      );
    }

    final route = Path();
    final points = <Offset>[];
    for (var index = 0; index < 5; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      points.add(point);
      if (index == 0) {
        route.moveTo(point.dx, point.dy);
      } else {
        route.lineTo(point.dx, point.dy);
      }
    }
    route.close();
    canvas.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GaussColors.brassLight.withValues(alpha: .2 * reveal),
    );

    for (var index = 0; index < points.length; index++) {
      final pointReveal = ((reveal * 6) - index).clamp(0.0, 1.0);
      canvas.drawCircle(
        points[index],
        8 * pointReveal,
        Paint()
          ..color = GaussColors.brassLight.withValues(alpha: .16 * pointReveal)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        points[index],
        3 + 1.7 * pointReveal,
        Paint()
          ..color = Color.lerp(
            GaussColors.line,
            GaussColors.signalBright,
            pointReveal,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(_MissionCompletionOrbitPainter oldDelegate) =>
      oldDelegate.reveal != reveal;
}
