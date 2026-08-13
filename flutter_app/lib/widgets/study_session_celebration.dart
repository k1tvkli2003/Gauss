import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/models.dart';
import 'gauss_brand.dart';

/// The presentation-only receipt for a completed five-question study orbit.
///
/// [outcome] is authoritative and already persisted. This widget never grants,
/// retries, or derives rewards from animation state; it only explains the
/// receipt and exposes the caller-owned continuation actions.
class StudySessionCelebration extends StatefulWidget {
  const StudySessionCelebration({
    required this.outcome,
    required this.primaryLabel,
    required this.onPrimary,
    this.onStay,
    super.key,
  });

  final StudyReflectionOutcome outcome;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onStay;

  @override
  State<StudySessionCelebration> createState() =>
      _StudySessionCelebrationState();
}

class _StudySessionCelebrationState extends State<StudySessionCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1380),
  );
  bool _motionResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionResolved) return;
    _motionResolved = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final headline = outcome.unitCompleted
        ? 'Unit charted'
        : outcome.setCompleted
        ? 'Session complete'
        : outcome.dailyQuestCompleted
        ? 'Daily observation complete'
        : 'Level ${outcome.levelAfter} reached';
    final detail = outcome.unitCompleted
        ? 'The full unit orbit is recorded on this device.'
        : outcome.setCompleted
        ? 'Five questions charted. Your next micro-lesson is ready.'
        : outcome.dailyQuestCompleted
        ? 'Ten new reflections are safely recorded for today.'
        : 'Your private observatory advanced through steady study.';
    final eyebrow = outcome.setCompleted || outcome.unitCompleted
        ? 'FIVE-QUESTION MICRO-LESSON'
        : outcome.dailyQuestCompleted
        ? 'DAILY OBSERVATION'
        : 'PRIVATE OBSERVATORY';
    final sealLabel = outcome.setCompleted || outcome.unitCompleted
        ? '5 / 5  ·  ORBIT CHARTED'
        : outcome.dailyQuestCompleted
        ? 'TODAY  ·  CHARTED'
        : 'LEVEL ${outcome.levelAfter}  ·  ADVANCED';
    final milestones = _milestonesFor(outcome);
    final rewardTotals = <String, int>{};
    for (final line in outcome.lines) {
      rewardTotals.update(
        line.reason,
        (value) => value + line.amount,
        ifAbsent: () => line.amount,
      );
    }
    final semantics = StringBuffer(
      '$headline. $detail. ${outcome.xpEarned} XP earned. '
      '${outcome.totalXp} total XP.',
    );
    for (final milestone in milestones) {
      semantics.write(' ${milestone.title}. ${milestone.detail}.');
    }

    final size = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final maxHeight = math.max(
      240.0,
      size.height - safePadding.vertical - GaussSpacing.space16,
    );
    final compactInset = size.width < 360
        ? GaussSpacing.space8
        : GaussSpacing.space16;

    return Dialog(
      key: const ValueKey('study-session-celebration'),
      insetPadding: EdgeInsets.symmetric(
        horizontal: compactInset,
        vertical: GaussSpacing.space8,
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.transparent,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semantics.toString(),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 760, maxHeight: maxHeight),
          child: SizedBox(
            height: maxHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GaussColors.ink,
                borderRadius: BorderRadius.circular(GaussRadii.large),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .58),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB0000000),
                    blurRadius: 40,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Image.asset(
                        'assets/visual/map/orrery_atmosphere_portrait.png',
                        fit: BoxFit.cover,
                        cacheWidth: 900,
                        filterQuality: FilterQuality.low,
                        opacity: const AlwaysStoppedAnimation(.24),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xB807151C), Color(0xFB050B0D)],
                          stops: [0, .76],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey(
                            'study-session-celebration-scroll',
                          ),
                          padding: EdgeInsets.fromLTRB(
                            size.width < 360
                                ? GaussSpacing.space16
                                : GaussSpacing.space24,
                            GaussSpacing.space20,
                            size.width < 360
                                ? GaussSpacing.space16
                                : GaussSpacing.space24,
                            GaussSpacing.space16,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final textScale = MediaQuery.textScalerOf(
                                context,
                              ).scale(16);
                              final wide =
                                  constraints.maxWidth >= 620 && textScale < 24;
                              final visual = _CelebrationVisual(
                                animation: _controller,
                                compact: !wide,
                                sealLabel: sealLabel,
                              );
                              final summary = _CelebrationSummary(
                                eyebrow: eyebrow,
                                headline: headline,
                                detail: detail,
                                outcome: outcome,
                                rewardTotals: rewardTotals,
                                milestones: milestones,
                              );
                              if (!wide) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    visual,
                                    const SizedBox(height: 8),
                                    summary,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 270, child: visual),
                                  const SizedBox(width: GaussSpacing.space24),
                                  Expanded(child: summary),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: GaussColors.ink.withValues(alpha: .97),
                          border: const Border(
                            top: BorderSide(color: GaussColors.hairline),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          size.width < 360
                              ? GaussSpacing.space16
                              : GaussSpacing.space24,
                          GaussSpacing.space12,
                          size.width < 360
                              ? GaussSpacing.space16
                              : GaussSpacing.space24,
                          GaussSpacing.space12,
                        ),
                        child: _CelebrationActions(
                          primaryLabel: widget.primaryLabel,
                          onPrimary: widget.onPrimary,
                          onStay: widget.onStay,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationVisual extends StatelessWidget {
  const _CelebrationVisual({
    required this.animation,
    required this.compact,
    required this.sealLabel,
  });

  final Animation<double> animation;
  final bool compact;
  final String sealLabel;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final height = compact ? 178.0 : 310.0;
    return SizedBox(
      key: const ValueKey('five-star-orbit-visual'),
      height: height,
      child: RepaintBoundary(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final reveal = Curves.easeOutCubic.transform(animation.value);
              final mascotOpacity = Interval(
                0,
                .36,
                curve: Curves.easeOut,
              ).transform(animation.value);
              final mascotScale = reducedMotion
                  ? 1.0
                  : .92 + .08 * Curves.easeOutBack.transform(reveal);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FiveStarOrbitPainter(progress: reveal),
                    ),
                  ),
                  Opacity(
                    opacity: mascotOpacity,
                    child: Transform.scale(
                      scale: mascotScale,
                      child: Image.asset(
                        'assets/visual/mascot/mira_correct.png',
                        height: compact ? 154 : 248,
                        fit: BoxFit.contain,
                        cacheHeight: compact ? 460 : 740,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: compact ? 0 : 8,
                    child: Container(
                      key: const ValueKey('five-of-five-seal'),
                      constraints: const BoxConstraints(minHeight: 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: GaussColors.deepInk.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(GaussRadii.pill),
                        border: Border.all(color: GaussColors.brassLight),
                        boxShadow: [
                          BoxShadow(
                            color: GaussColors.brass.withValues(alpha: .2),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Text(
                        sealLabel,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontSize: GaussTypeScale.caption,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .65,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CelebrationSummary extends StatelessWidget {
  const _CelebrationSummary({
    required this.eyebrow,
    required this.headline,
    required this.detail,
    required this.outcome,
    required this.rewardTotals,
    required this.milestones,
  });

  final String eyebrow;
  final String headline;
  final String detail;
  final StudyReflectionOutcome outcome;
  final Map<String, int> rewardTotals;
  final List<_MilestoneFact> milestones;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(header: true, child: const GaussWordmark(width: 118)),
      ),
      const SizedBox(height: GaussSpacing.space12),
      Text(
        eyebrow,
        style: const TextStyle(
          color: GaussColors.brassLight,
          fontSize: GaussTypeScale.insignia,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.3,
        ),
      ),
      const SizedBox(height: GaussSpacing.space4),
      Text(
        headline,
        key: const ValueKey('study-celebration-headline'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: GaussSpacing.space8),
      Text(
        detail,
        style: const TextStyle(color: GaussColors.muted, height: 1.5),
      ),
      const SizedBox(height: GaussSpacing.space16),
      _XpReceiptSummary(outcome: outcome),
      if (milestones.isNotEmpty) ...[
        const SizedBox(height: GaussSpacing.space12),
        _MilestoneLedger(milestones: milestones),
      ],
      const SizedBox(height: GaussSpacing.space12),
      _RewardReceipt(totals: rewardTotals),
    ],
  );
}

class _XpReceiptSummary extends StatelessWidget {
  const _XpReceiptSummary({required this.outcome});

  final StudyReflectionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final earnedDetail = outcome.xpEarned > 0
        ? '+${outcome.xpEarned} XP'
        : 'XP cap met';
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) >= 21;
        final earned = _XpPlate(
          key: const ValueKey('study-xp-earned'),
          icon: Icons.auto_awesome_rounded,
          eyebrow: 'THIS RECEIPT',
          value: earnedDetail,
          accent: GaussColors.signalBright,
        );
        final total = _XpPlate(
          key: const ValueKey('study-xp-total'),
          icon: Icons.explore_rounded,
          eyebrow: 'PRIVATE TOTAL',
          value: '${outcome.totalXp} XP',
          accent: GaussColors.brassLight,
        );
        if (stack) {
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
}

class _XpPlate extends StatelessWidget {
  const _XpPlate({
    required this.icon,
    required this.eyebrow,
    required this.value,
    required this.accent,
    super.key,
  });

  final IconData icon;
  final String eyebrow;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(GaussRadii.medium),
      border: Border.all(color: accent.withValues(alpha: .36)),
    ),
    child: Row(
      children: [
        Icon(icon, color: accent, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .65,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MilestoneLedger extends StatelessWidget {
  const _MilestoneLedger({required this.milestones});

  final List<_MilestoneFact> milestones;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Milestones recorded',
    child: Container(
      key: const ValueKey('study-milestone-ledger'),
      decoration: BoxDecoration(
        color: GaussColors.raised.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(GaussRadii.medium),
        border: Border.all(color: GaussColors.line),
      ),
      child: Column(
        children: [
          for (var index = 0; index < milestones.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 48, endIndent: 12),
            _MilestoneRow(fact: milestones[index]),
          ],
        ],
      ),
    ),
  );
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.fact});

  final _MilestoneFact fact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${fact.title}. ${fact.detail}',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fact.accent.withValues(alpha: .13),
              border: Border.all(color: fact.accent.withValues(alpha: .5)),
            ),
            child: Icon(fact.icon, color: fact.accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fact.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  fact.detail,
                  style: const TextStyle(
                    color: GaussColors.muted,
                    fontSize: GaussTypeScale.metadata,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: fact.accent, size: 20),
        ],
      ),
    ),
  );
}

class _RewardReceipt extends StatelessWidget {
  const _RewardReceipt({required this.totals});

  final Map<String, int> totals;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'XP receipt',
    child: Container(
      key: const ValueKey('study-reward-receipt'),
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
            'RECORDED XP',
            style: TextStyle(
              color: GaussColors.fog,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 6),
          if (totals.isEmpty)
            const Text(
              'Milestone recorded. Today’s reward cap was already met.',
              style: TextStyle(color: GaussColors.muted, height: 1.45),
            )
          else
            for (final entry in totals.entries)
              _ReceiptLine(reason: entry.key, amount: entry.value),
        ],
      ),
    ),
  );
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.reason, required this.amount});

  final String reason;
  final int amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 250 ||
            MediaQuery.textScalerOf(context).scale(14) >= 21;
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

class _CelebrationActions extends StatelessWidget {
  const _CelebrationActions({
    required this.primaryLabel,
    required this.onPrimary,
    required this.onStay,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onStay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final accessible =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) >= 22;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            key: const ValueKey('study-celebration-primary'),
            constraints: const BoxConstraints(minHeight: 52),
            child: accessible
                ? FilledButton(
                    onPressed: onPrimary,
                    child: Text(primaryLabel, textAlign: TextAlign.center),
                  )
                : FilledButton.icon(
                    onPressed: onPrimary,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(primaryLabel, textAlign: TextAlign.center),
                  ),
          ),
          if (onStay != null) ...[
            const SizedBox(height: 4),
            ConstrainedBox(
              key: const ValueKey('study-celebration-stay'),
              constraints: const BoxConstraints(minHeight: 48),
              child: TextButton(
                onPressed: onStay,
                child: const Text('Stay here'),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _MilestoneFact {
  const _MilestoneFact({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
}

List<_MilestoneFact> _milestonesFor(StudyReflectionOutcome outcome) => [
  if (outcome.setCompleted)
    const _MilestoneFact(
      title: 'Five-question orbit complete',
      detail: '5 of 5 session coordinates are recorded.',
      icon: Icons.route_rounded,
      accent: GaussColors.signalBright,
    ),
  if (outcome.unitCompleted)
    const _MilestoneFact(
      title: 'Unit orbit complete',
      detail: 'Every planned and mastery-review coordinate is charted.',
      icon: Icons.public_rounded,
      accent: GaussColors.brassLight,
    ),
  if (outcome.dailyQuestCompleted)
    const _MilestoneFact(
      title: 'Today’s observation recorded',
      detail: 'Today’s goal was recorded automatically on this device.',
      icon: Icons.today_rounded,
      accent: GaussColors.ice,
    ),
  if (outcome.leveledUp)
    _MilestoneFact(
      title: 'Level ${outcome.levelAfter} reached',
      detail: 'Your private observatory advanced one level.',
      icon: Icons.workspace_premium_rounded,
      accent: GaussColors.brassLight,
    ),
];

class _FiveStarOrbitPainter extends CustomPainter {
  const _FiveStarOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 2);
    final radius = math.min(size.width, size.height) * .4;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = GaussColors.brass.withValues(alpha: .28);
    final faintRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = GaussColors.ice.withValues(alpha: .16);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * .72, faintRing);

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
        ..color = GaussColors.brassLight.withValues(alpha: .18),
    );

    for (var index = 0; index < points.length; index++) {
      final reveal = ((progress * 6) - index).clamp(0.0, 1.0);
      final glow = Paint()
        ..color = GaussColors.brassLight.withValues(alpha: .18 * reveal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      final fill = Paint()
        ..color = Color.lerp(GaussColors.line, GaussColors.brassLight, reveal)!;
      canvas.drawCircle(points[index], 9 * reveal, glow);
      canvas.drawCircle(points[index], 3.2 + 1.8 * reveal, fill);
      canvas.drawCircle(
        points[index],
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = GaussColors.brass.withValues(alpha: .56),
      );
    }
  }

  @override
  bool shouldRepaint(_FiveStarOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
