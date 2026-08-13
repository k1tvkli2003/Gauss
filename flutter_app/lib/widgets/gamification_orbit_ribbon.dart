import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/gamification_catalog.dart';
import '../domain/models.dart';

/// A compact, private progress instrument for map and mission overlays.
///
/// The ribbon is presentation-only: [summary] remains the single source of
/// truth and the optional callbacks let a parent route own navigation. It has
/// no timers, reward mutations, network assumptions, or social comparison.
class GamificationOrbitRibbon extends StatelessWidget {
  const GamificationOrbitRibbon({
    super.key,
    required this.summary,
    this.onQuestPressed,
    this.onMilestonePressed,
  });

  final GamificationSummary summary;
  final VoidCallback? onQuestPressed;
  final VoidCallback? onMilestonePressed;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final questProgress = summary.quest.completed
        ? 1.0
        : _safeProgress(summary.quest.progress, summary.quest.target);
    final milestone = _MilestoneView.from(summary.achievements);

    return Semantics(
      key: const ValueKey('gamification-orbit-ribbon'),
      container: true,
      label:
          'Private offline progress. ${summary.streak} day daily streak. '
          '${summary.todayXp} experience today. Level ${summary.level}.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GaussRadii.large),
        child: CustomPaint(
          painter: const _OrbitRibbonPainter(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GaussColors.panelHigh.withValues(alpha: .97),
                  GaussColors.deepInk.withValues(alpha: .98),
                  GaussColors.ink.withValues(alpha: .99),
                ],
                stops: const [0, .52, 1],
              ),
              borderRadius: BorderRadius.circular(GaussRadii.large),
              border: Border.all(color: GaussColors.line),
              boxShadow: [
                BoxShadow(
                  color: GaussColors.brassDeep.withValues(alpha: .16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(GaussSpacing.space16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useWideRibbon =
                      constraints.maxWidth >= 760 && textScale <= 1.2;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RibbonHeader(todayXp: summary.todayXp),
                      const SizedBox(height: GaussSpacing.space12),
                      if (useWideRibbon)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 154,
                              child: _RhythmSegment(
                                streak: summary.streak,
                                graceUsed: summary.streakGraceUsed,
                              ),
                            ),
                            const SizedBox(width: GaussSpacing.space12),
                            Expanded(
                              flex: 3,
                              child: _QuestSegment(
                                quest: summary.quest,
                                todayXp: summary.todayXp,
                                progress: questProgress,
                                onPressed: onQuestPressed,
                              ),
                            ),
                            const SizedBox(width: GaussSpacing.space12),
                            SizedBox(
                              width: 170,
                              child: _LevelSegment(
                                level: summary.level,
                                progress: summary.levelProgress,
                              ),
                            ),
                            const SizedBox(width: GaussSpacing.space12),
                            Expanded(
                              flex: 2,
                              child: _MilestoneSegment(
                                milestone: milestone,
                                onPressed: onMilestonePressed,
                              ),
                            ),
                          ],
                        )
                      else
                        _CompactRibbon(
                          summary: summary,
                          questProgress: questProgress,
                          milestone: milestone,
                          onQuestPressed: onQuestPressed,
                          onMilestonePressed: onMilestonePressed,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactRibbon extends StatelessWidget {
  const _CompactRibbon({
    required this.summary,
    required this.questProgress,
    required this.milestone,
    required this.onQuestPressed,
    required this.onMilestonePressed,
  });

  final GamificationSummary summary;
  final double questProgress;
  final _MilestoneView milestone;
  final VoidCallback? onQuestPressed;
  final VoidCallback? onMilestonePressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _QuestSegment(
        quest: summary.quest,
        todayXp: summary.todayXp,
        progress: questProgress,
        onPressed: onQuestPressed,
      ),
      const SizedBox(height: GaussSpacing.space12),
      LayoutBuilder(
        builder: (context, constraints) {
          const gap = GaussSpacing.space12;
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final canShareRow = constraints.maxWidth >= 280 && textScale <= 1.35;
          if (!canShareRow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RhythmSegment(
                  streak: summary.streak,
                  graceUsed: summary.streakGraceUsed,
                ),
                const SizedBox(height: gap),
                _LevelSegment(
                  level: summary.level,
                  progress: summary.levelProgress,
                ),
              ],
            );
          }
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: width,
                child: _RhythmSegment(
                  streak: summary.streak,
                  graceUsed: summary.streakGraceUsed,
                ),
              ),
              SizedBox(
                width: width,
                child: _LevelSegment(
                  level: summary.level,
                  progress: summary.levelProgress,
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: GaussSpacing.space12),
      _MilestoneSegment(milestone: milestone, onPressed: onMilestonePressed),
    ],
  );
}

class _RibbonHeader extends StatelessWidget {
  const _RibbonHeader({required this.todayXp});

  final int todayXp;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final identity = const Row(
        children: [
          Icon(Icons.radar_rounded, size: 18, color: GaussColors.brassLight),
          SizedBox(width: GaussSpacing.space8),
          Expanded(
            child: Text(
              'PRIVATE ORBIT',
              style: TextStyle(
                color: GaussColors.brassLight,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.25,
              ),
            ),
          ),
        ],
      );
      final status = Semantics(
        label: 'Saved on this device. $todayXp experience today.',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GaussSpacing.space12,
            vertical: GaussSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: GaussColors.signal.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(GaussRadii.pill),
            border: Border.all(
              color: GaussColors.signalBright.withValues(alpha: .28),
            ),
          ),
          child: Text(
            'ON DEVICE  •  $todayXp XP TODAY',
            style: const TextStyle(
              color: GaussColors.signalBright,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
            ),
          ),
        ),
      );
      final reflow =
          constraints.maxWidth < 520 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      if (reflow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            identity,
            const SizedBox(height: GaussSpacing.space8),
            Align(alignment: AlignmentDirectional.centerStart, child: status),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: identity),
          const SizedBox(width: GaussSpacing.space12),
          status,
        ],
      );
    },
  );
}

class _QuestSegment extends StatelessWidget {
  const _QuestSegment({
    required this.quest,
    required this.todayXp,
    required this.progress,
    required this.onPressed,
  });

  final DailyQuest quest;
  final int todayXp;
  final double progress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final remaining = math.max(0, quest.target - quest.progress);
    final status = quest.completed
        ? 'Complete · reward safely recorded'
        : remaining == 1
        ? '1 reflection remains · no rush'
        : '$remaining reflections remain · no rush';
    return _InstrumentSegment(
      key: const ValueKey('gamification-quest-segment'),
      semanticsLabel:
          'Today quest. ${quest.title}. ${quest.progress} of ${quest.target}. '
          '$todayXp experience today. $status.',
      onPressed: onPressed,
      accent: quest.completed
          ? GaussColors.signalBright
          : GaussColors.brassLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                quest.completed
                    ? Icons.task_alt_rounded
                    : Icons.auto_stories_outlined,
                size: 22,
                color: quest.completed
                    ? GaussColors.signalBright
                    : GaussColors.brassLight,
              ),
              const SizedBox(width: GaussSpacing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.completed ? 'TODAY · CHARTED' : 'TODAY · QUEST',
                      style: TextStyle(
                        color: quest.completed
                            ? GaussColors.signalBright
                            : GaussColors.brassLight,
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: GaussSpacing.space4),
                    Text(
                      quest.title,
                      style: const TextStyle(
                        color: GaussColors.ivory,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GaussSpacing.space12),
          _OrbitProgressTrack(
            key: const ValueKey('gamification-quest-progress'),
            value: progress,
            color: quest.completed
                ? GaussColors.signalBright
                : GaussColors.brassLight,
            semanticsLabel:
                '${quest.progress} of ${quest.target} daily reflections recorded',
          ),
          const SizedBox(height: GaussSpacing.space8),
          Wrap(
            spacing: GaussSpacing.space8,
            runSpacing: GaussSpacing.space4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                status,
                style: const TextStyle(
                  color: GaussColors.muted,
                  fontSize: GaussTypeScale.caption,
                  height: 1.35,
                ),
              ),
              Text(
                '${quest.progress}/${quest.target}',
                style: const TextStyle(
                  color: GaussColors.ivory,
                  fontSize: GaussTypeScale.metadata,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RhythmSegment extends StatelessWidget {
  const _RhythmSegment({required this.streak, required this.graceUsed});

  final int streak;
  final bool graceUsed;

  @override
  Widget build(BuildContext context) {
    final detail = streak == 0
        ? 'Begin whenever you are ready'
        : graceUsed
        ? 'Grace day active · earned XP stays safe'
        : streak == 1
        ? 'One real study day logged'
        : 'Keep your learning orbit alive';
    return _InstrumentSegment(
      semanticsLabel:
          'Daily streak. $streak active study days. '
          '${graceUsed ? 'A calm grace day is bridging the orbit. ' : ''}'
          'Earned experience never disappears.',
      accent: GaussColors.signalBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.waves_rounded,
            size: 21,
            color: GaussColors.signalBright,
          ),
          const SizedBox(height: GaussSpacing.space8),
          Text(
            '$streak DAY${streak == 1 ? '' : 'S'}',
            key: const ValueKey('gamification-streak-value'),
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: GaussSpacing.space4),
          const Text(
            'DAILY STREAK',
            style: TextStyle(
              color: GaussColors.signalBright,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: .65,
            ),
          ),
          const SizedBox(height: GaussSpacing.space4),
          Text(
            detail,
            style: const TextStyle(
              color: GaussColors.muted,
              fontSize: GaussTypeScale.caption,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSegment extends StatelessWidget {
  const _LevelSegment({required this.level, required this.progress});

  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final percent = (safeProgress * 100).round();
    return _InstrumentSegment(
      semanticsLabel:
          'Observer level $level. $percent percent toward level ${level + 1}.',
      accent: GaussColors.ice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.explore_outlined,
                size: 21,
                color: GaussColors.ice,
              ),
              const SizedBox(width: GaussSpacing.space8),
              Expanded(
                child: Text(
                  'LEVEL $level',
                  key: const ValueKey('gamification-level-value'),
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GaussSpacing.space12),
          _OrbitProgressTrack(
            key: const ValueKey('gamification-level-progress'),
            value: safeProgress,
            color: GaussColors.ice,
            semanticsLabel: '$percent percent toward level ${level + 1}',
          ),
          const SizedBox(height: GaussSpacing.space8),
          Text(
            '$percent% TO LEVEL ${level + 1}',
            style: const TextStyle(
              color: GaussColors.muted,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneSegment extends StatelessWidget {
  const _MilestoneSegment({required this.milestone, required this.onPressed});

  final _MilestoneView milestone;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _InstrumentSegment(
    key: const ValueKey('gamification-milestone-segment'),
    semanticsLabel: milestone.semanticsLabel,
    onPressed: onPressed,
    accent: milestone.color,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: milestone.color.withValues(alpha: .11),
            border: Border.all(color: milestone.color.withValues(alpha: .46)),
          ),
          child: Icon(milestone.icon, color: milestone.color, size: 22),
        ),
        const SizedBox(width: GaussSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                milestone.eyebrow,
                key: const ValueKey('gamification-milestone-state'),
                style: TextStyle(
                  color: milestone.color,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .75,
                ),
              ),
              const SizedBox(height: GaussSpacing.space4),
              Text(
                milestone.title,
                style: const TextStyle(
                  color: GaussColors.ivory,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: GaussSpacing.space4),
              Text(
                milestone.detail,
                style: const TextStyle(
                  color: GaussColors.muted,
                  fontSize: GaussTypeScale.caption,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (onPressed != null) ...[
          const SizedBox(width: GaussSpacing.space8),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            size: 22,
            color: GaussColors.fog,
          ),
        ],
      ],
    ),
  );
}

class _InstrumentSegment extends StatelessWidget {
  const _InstrumentSegment({
    super.key,
    required this.semanticsLabel,
    required this.accent,
    required this.child,
    this.onPressed,
  });

  final String semanticsLabel;
  final Color accent;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GaussMetrics.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.all(GaussSpacing.space12),
        child: child,
      ),
    );
    return Semantics(
      container: true,
      button: onPressed != null,
      enabled: onPressed != null ? true : null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: GaussColors.abyss.withValues(alpha: .38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GaussRadii.medium),
          side: BorderSide(color: accent.withValues(alpha: .22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: onPressed == null
            ? content
            : InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(GaussRadii.medium),
                child: content,
              ),
      ),
    );
  }
}

class _OrbitProgressTrack extends StatelessWidget {
  const _OrbitProgressTrack({
    super.key,
    required this.value,
    required this.color,
    required this.semanticsLabel,
  });

  final double value;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: '${(target * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: GaussMotion.resolve(context, GaussMotion.spatial),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) => Container(
          height: 7,
          decoration: BoxDecoration(
            color: GaussColors.hairline,
            borderRadius: BorderRadius.circular(GaussRadii.pill),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: animatedValue,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(GaussRadii.pill),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: .3), blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneView {
  const _MilestoneView({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.semanticsLabel,
    required this.icon,
    required this.color,
  });

  factory _MilestoneView.from(List<AchievementSnapshot> achievements) {
    if (achievements.isEmpty) {
      return const _MilestoneView(
        eyebrow: 'MILESTONE CHART',
        title: 'Your first seal is ahead',
        detail: 'A real reflection will begin the private chart.',
        semanticsLabel:
            'No milestone seals yet. A real reflection will begin the private chart.',
        icon: Icons.brightness_2_outlined,
        color: GaussColors.fog,
      );
    }

    AchievementSnapshot? earned;
    var earnedScore = -1;
    for (final snapshot in achievements) {
      final level = snapshot.earnedLevel;
      if (level == null) continue;
      final score = level.rarity.index * 100000 + level.threshold;
      if (score > earnedScore) {
        earned = snapshot;
        earnedScore = score;
      }
    }

    final chosen =
        earned ??
        achievements.reduce(
          (best, candidate) =>
              candidate.progress > best.progress ? candidate : best,
        );
    final earnedLevel = chosen.earnedLevel;
    final next = chosen.nextLevel;
    final family = chosen.definition.family;
    final rarity =
        earnedLevel?.rarity ?? next?.rarity ?? AchievementRarity.common;
    final color = _rarityColor(rarity);

    if (earnedLevel != null) {
      final detail = next == null
          ? '${chosen.definition.title} · every tier charted'
          : 'Next: ${next.title} · ${chosen.current}/${next.threshold}';
      return _MilestoneView(
        eyebrow: 'EARNED SEAL · ${earnedLevel.rarity.label.toUpperCase()}',
        title: earnedLevel.title,
        detail: detail,
        semanticsLabel:
            'Earned milestone. ${chosen.definition.title}, ${earnedLevel.title}, '
            '${earnedLevel.rarity.label}. $detail.',
        icon: _familyIcon(family),
        color: color,
      );
    }

    return _MilestoneView(
      eyebrow: 'NEXT SEAL · ${rarity.label.toUpperCase()}',
      title: next?.title ?? chosen.definition.title,
      detail:
          '${chosen.definition.title} · ${chosen.current}/${next?.threshold ?? chosen.current}',
      semanticsLabel:
          'Next milestone. ${chosen.definition.title}, ${next?.title ?? ''}. '
          '${chosen.current} of ${next?.threshold ?? chosen.current}.',
      icon: _familyIcon(family),
      color: color,
    );
  }

  final String eyebrow;
  final String title;
  final String detail;
  final String semanticsLabel;
  final IconData icon;
  final Color color;
}

IconData _familyIcon(AchievementFamily family) => switch (family) {
  AchievementFamily.mastery => Icons.auto_awesome_rounded,
  AchievementFamily.correction => Icons.explore_rounded,
  AchievementFamily.exploration => Icons.public_rounded,
  AchievementFamily.challenge => Icons.wb_sunny_outlined,
  AchievementFamily.consistency => Icons.graphic_eq_rounded,
};

Color _rarityColor(AchievementRarity rarity) => switch (rarity) {
  AchievementRarity.common => GaussColors.muted,
  AchievementRarity.uncommon => GaussColors.signalBright,
  AchievementRarity.rare => GaussColors.ice,
  AchievementRarity.epic => GaussColors.violet,
  AchievementRarity.legendary => GaussColors.brassLight,
};

double _safeProgress(int current, int target) {
  if (target <= 0) return 0;
  return (current / target).clamp(0.0, 1.0);
}

/// A low-cost astrolabe engraving. It is decorative only; all live values and
/// state meaning remain semantic widgets above it.
class _OrbitRibbonPainter extends CustomPainter {
  const _OrbitRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final brass = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GaussColors.brassLight.withValues(alpha: .07);
    final signal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GaussColors.signalBright.withValues(alpha: .045);
    final center = Offset(size.width * .88, size.height * .12);
    final baseRadius = math.min(size.width, size.height) * .36;
    for (var index = 0; index < 4; index++) {
      final radius = baseRadius + index * 22;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * .42,
        math.pi * .98,
        false,
        index.isEven ? brass : signal,
      );
    }
    final horizon = size.height * .72;
    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon - size.width * .035),
      brass,
    );
    final star = Paint()..color = GaussColors.ivory.withValues(alpha: .11);
    for (final point in const [
      Offset(.08, .18),
      Offset(.22, .1),
      Offset(.52, .19),
      Offset(.72, .08),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        1.25,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRibbonPainter oldDelegate) => false;
}
