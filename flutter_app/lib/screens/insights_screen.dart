import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/gamification_catalog.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final analytics = controller.analytics;
    final gamification = controller.gamification;
    final topicLabels = {
      for (final topic in controller.topics) topic.key: topic.label,
    };
    final strongest =
        controller.topics
            .map(
              (topic) => (
                topic: topic,
                completed: controller.completedInTopic(topic.key),
              ),
            )
            .where((entry) => entry.completed > 0)
            .toList()
          ..sort((a, b) => b.completed.compareTo(a.completed));

    return Stack(
      fit: StackFit.expand,
      children: [
        const _ObservatoryBackdrop(),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ObservatoryHeader(controller: controller),
              ),
              SliverToBoxAdapter(
                child: _SignalLens(
                  analytics: analytics,
                  gamification: gamification,
                ),
              ),
              SliverToBoxAdapter(
                child: _DailyQuestInstrument(quest: gamification.quest),
              ),
              if (analytics.totalAnswered > 0)
                SliverToBoxAdapter(
                  child: _StarChartPanel(heatmap: analytics.heatmap),
                ),
              if (gamification.achievements.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: 'PRIVATE CONSTELLATION',
                    title: 'Theorem seals',
                    detail:
                        'Milestones engraved only from missions you have completed.',
                    trailing: '${gamification.achievements.length} seals',
                  ),
                ),
              if (gamification.achievements.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 960
                          ? 3
                          : constraints.crossAxisExtent >= 620
                          ? 2
                          : 1;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 11,
                          crossAxisSpacing: 11,
                          childAspectRatio: columns == 1 ? 2.55 : 1.62,
                        ),
                        itemCount: gamification.achievements.length,
                        itemBuilder: (context, index) => _AchievementPlate(
                          snapshot: gamification.achievements[index],
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: _SectionHeading(
                  eyebrow: 'OBSERVATION LOG',
                  title: 'Signals by orbit',
                  detail: analytics.totalAnswered == 0
                      ? 'Your first completed mission will begin this record.'
                      : 'A calm reading of solved questions, useful friction, and recent missions.',
                ),
              ),
              SliverToBoxAdapter(
                child: _ObservationDeck(
                  strongest: strongest,
                  weakTopics: analytics.weakTopics,
                  distractors: analytics.distractors,
                  topicLabels: topicLabels,
                  recentExams: controller.recentExams,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObservatoryBackdrop extends StatelessWidget {
  const _ObservatoryBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/visual/map/orrery_atmosphere_portrait.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: 1100,
        filterQuality: FilterQuality.low,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xC207151C), Color(0xF503090B)],
            stops: [.05, .7],
          ),
        ),
      ),
    ],
  );
}

class _ObservatoryHeader extends StatelessWidget {
  const _ObservatoryHeader({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 620;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          GaussWordmark(width: 118),
                          SizedBox(width: 10),
                          Text(
                            'OBSERVATORY',
                            style: TextStyle(
                              color: GaussColors.brassLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your observation log',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        narrow
                            ? 'Every signal comes from work you recorded.'
                            : 'Read the pattern of your practice without rankings, pressure, or invented progress.',
                        style: const TextStyle(color: GaussColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _LevelMedallion(
                  level: controller.gamification.level,
                  progress: controller.gamification.levelProgress,
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _LevelMedallion extends StatelessWidget {
  const _LevelMedallion({required this.level, required this.progress});

  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Observer level $level. ${(progress * 100).round()} percent toward the next level.',
    child: SizedBox.square(
      dimension: 58,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          trackColor: GaussColors.hairline,
          valueColor: GaussColors.brassLight,
          strokeWidth: 3.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$level',
              style: const TextStyle(
                color: GaussColors.ivory,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: .95,
              ),
            ),
            const Text(
              'LEVEL',
              style: TextStyle(
                color: GaussColors.fog,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SignalLens extends StatelessWidget {
  const _SignalLens({required this.analytics, required this.gamification});

  final AnalyticsSnapshot analytics;
  final GamificationSummary gamification;

  @override
  Widget build(BuildContext context) {
    final hasSignal = analytics.totalAnswered > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Semantics(
            container: true,
            label: hasSignal
                ? '${analytics.totalAnswered} answers recorded. ${analytics.accuracy.round()} percent accurate. ${analytics.streak} day study rhythm. ${gamification.totalXp} experience points.'
                : 'No observations recorded yet. Complete one mission to begin your observation log.',
            child: Container(
              constraints: const BoxConstraints(minHeight: 272),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: GaussColors.ink.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: GaussColors.line),
                boxShadow: [
                  BoxShadow(
                    color: GaussColors.brass.withValues(alpha: .08),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _LensGridPainter()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 690;
                        final reading = _PrimaryReading(
                          hasSignal: hasSignal,
                          accuracy: analytics.accuracy,
                          totalAnswered: analytics.totalAnswered,
                        );
                        final metrics = _SignalMetrics(
                          analytics: analytics,
                          gamification: gamification,
                        );
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              reading,
                              const SizedBox(height: 22),
                              metrics,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(flex: 5, child: reading),
                            Container(
                              width: 1,
                              height: 190,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              color: GaussColors.hairline,
                            ),
                            Expanded(flex: 6, child: metrics),
                          ],
                        );
                      },
                    ),
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

class _PrimaryReading extends StatelessWidget {
  const _PrimaryReading({
    required this.hasSignal,
    required this.accuracy,
    required this.totalAnswered,
  });

  final bool hasSignal;
  final double accuracy;
  final int totalAnswered;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(
        dimension: 116,
        child: CustomPaint(
          painter: _SignalDialPainter(
            progress: hasSignal ? accuracy / 100 : 0,
            active: hasSignal,
          ),
          child: Center(
            child: hasSignal
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${accuracy.round()}%',
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                      ),
                      const Text(
                        'ACCURACY',
                        style: TextStyle(
                          color: GaussColors.signalBright,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .75,
                        ),
                      ),
                    ],
                  )
                : const TheoremStarMark(size: 52),
          ),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasSignal ? 'Signal acquired' : 'Awaiting first signal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              hasSignal
                  ? '$totalAnswered ${totalAnswered == 1 ? 'answer has' : 'answers have'} entered your private proof ledger.'
                  : 'Complete one short mission. The lens will reveal a useful pattern only when there is real work to read.',
              style: const TextStyle(color: GaussColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SignalMetrics extends StatelessWidget {
  const _SignalMetrics({required this.analytics, required this.gamification});

  final AnalyticsSnapshot analytics;
  final GamificationSummary gamification;

  @override
  Widget build(BuildContext context) {
    if (analytics.totalAnswered == 0) return const _FirstSignalGuide();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InstrumentReadout(
              width: width,
              label: 'EXPERIENCE',
              value: '${gamification.totalXp}',
              unit: 'XP',
              accent: GaussColors.brassLight,
            ),
            _InstrumentReadout(
              width: width,
              label: 'TODAY',
              value: '${gamification.todayXp}',
              unit: 'XP',
              accent: GaussColors.signalBright,
            ),
            _InstrumentReadout(
              width: width,
              label: 'RHYTHM',
              value: '${analytics.streak}',
              unit: analytics.streak == 1 ? 'DAY' : 'DAYS',
              accent: GaussColors.violet,
            ),
            _InstrumentReadout(
              width: width,
              label: 'PACE',
              value: '${analytics.averageSeconds.round()}',
              unit: 'SEC',
              accent: GaussColors.ice,
            ),
          ],
        );
      },
    );
  }
}

class _FirstSignalGuide extends StatelessWidget {
  const _FirstSignalGuide();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'HOW THE LENS WAKES',
        style: TextStyle(
          color: GaussColors.brassLight,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 10),
      const _FirstSignalStep(
        index: '1',
        title: 'Choose a short set',
        detail: 'Start with a chapter that feels inviting.',
        color: GaussColors.brassLight,
      ),
      const SizedBox(height: 8),
      const _FirstSignalStep(
        index: '2',
        title: 'Reason at your pace',
        detail: 'Only completed work enters the log.',
        color: GaussColors.signalBright,
      ),
      const SizedBox(height: 8),
      const _FirstSignalStep(
        index: '3',
        title: 'Return for the pattern',
        detail: 'The lens turns real attempts into useful signals.',
        color: GaussColors.ice,
      ),
    ],
  );
}

class _FirstSignalStep extends StatelessWidget {
  const _FirstSignalStep({
    required this.index,
    required this.title,
    required this.detail,
    required this.color,
  });

  final String index;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .1),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Text(
          index,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              detail,
              style: const TextStyle(color: GaussColors.fog, fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );
}

class _InstrumentReadout extends StatelessWidget {
  const _InstrumentReadout({
    required this.width,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
  });

  final double width;
  final String label;
  final String value;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 82,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: accent.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .85,
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: accent,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: '  $unit',
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DailyQuestInstrument extends StatelessWidget {
  const _DailyQuestInstrument({required this.quest});

  final DailyQuest quest;

  @override
  Widget build(BuildContext context) {
    final progress = quest.target == 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Semantics(
            container: true,
            label:
                'Daily observation. ${quest.title}. ${quest.progress} of ${quest.target}. Reward ${quest.rewardXp} experience points. ${quest.completed ? 'Complete.' : 'In progress.'}',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GaussColors.signal.withValues(alpha: .15),
                    GaussColors.ink.withValues(alpha: .96),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: quest.completed
                      ? GaussColors.signal.withValues(alpha: .65)
                      : GaussColors.line,
                ),
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 56,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        trackColor: GaussColors.hairline,
                        valueColor: GaussColors.signalBright,
                        strokeWidth: 4,
                      ),
                      child: Center(
                        child: quest.completed
                            ? const _CheckGlyph()
                            : Text(
                                '${quest.progress}',
                                style: const TextStyle(
                                  color: GaussColors.signalBright,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'DAILY OBSERVATION',
                              style: TextStyle(
                                color: GaussColors.signalBright,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${quest.rewardXp} XP',
                              style: const TextStyle(
                                color: GaussColors.brassLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          quest.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: GaussColors.hairline,
                            color: GaussColors.signalBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${quest.progress}/${quest.target}',
                    style: const TextStyle(
                      color: GaussColors.ivory,
                      fontWeight: FontWeight.w900,
                    ),
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

class _CheckGlyph extends StatelessWidget {
  const _CheckGlyph();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: const Size.square(22), painter: _CheckPainter()),
  );
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..color = GaussColors.signalBright;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .17, size.height * .52)
        ..lineTo(size.width * .42, size.height * .76)
        ..lineTo(size.width * .84, size.height * .25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.detail,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: GaussColors.brassLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _AchievementPlate extends StatelessWidget {
  const _AchievementPlate({required this.snapshot});

  final AchievementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final definition = snapshot.definition;
    final earned = snapshot.earnedLevel;
    final next = snapshot.nextLevel;
    final rarity = earned?.rarity ?? next?.rarity ?? AchievementRarity.common;
    final color = _rarityColor(rarity);
    final progressLabel = next == null
        ? 'Constellation complete'
        : '${snapshot.current} / ${next.threshold} toward ${next.title}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${definition.accessibilityLabel}. ${earned?.title ?? 'Uncharted'}. $progressLabel. ${rarity.label} tier.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: .11),
              GaussColors.raised.withValues(alpha: .97),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .38)),
        ),
        child: Row(
          children: [
            _AchievementSeal(
              family: definition.family,
              color: color,
              earned: earned != null,
              rarity: rarity,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          definition.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _RarityNotches(count: rarity.index + 1, color: color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    earned?.title ?? 'Uncharted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    definition.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: snapshot.progress,
                      minHeight: 5,
                      backgroundColor: GaussColors.hairline,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progressLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Text(
                        rarity.label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .55,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementSeal extends StatelessWidget {
  const _AchievementSeal({
    required this.family,
    required this.color,
    required this.earned,
    required this.rarity,
  });

  final AchievementFamily family;
  final Color color;
  final bool earned;
  final AchievementRarity rarity;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 76,
    child: CustomPaint(
      painter: _AchievementSealPainter(
        family: family,
        color: color,
        earned: earned,
        tier: rarity.index + 1,
      ),
    ),
  );
}

class _AchievementSealPainter extends CustomPainter {
  const _AchievementSealPainter({
    required this.family,
    required this.color,
    required this.earned,
    required this.tier,
  });

  final AchievementFamily family;
  final Color color;
  final bool earned;
  final int tier;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .43;
    final dim = earned ? 1.0 : .52;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: dim);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .2 * dim);
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: .07 * dim);

    canvas.drawCircle(Offset.zero, radius, glow);
    canvas.drawCircle(Offset.zero, radius, line);
    canvas.drawCircle(Offset.zero, radius * .76, faint);
    for (var i = 0; i < tier; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / tier;
      final point = Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        2.1,
        Paint()..color = color.withValues(alpha: dim),
      );
    }

    switch (family) {
      case AchievementFamily.mastery:
        for (var i = 0; i < 4; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 2);
          canvas.drawPath(
            Path()
              ..moveTo(-3, -3)
              ..quadraticBezierTo(0, -13, 0, -20)
              ..quadraticBezierTo(0, -13, 3, -3)
              ..lineTo(0, 2)
              ..close(),
            Paint()..color = color.withValues(alpha: dim),
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, 4.5, line);
      case AchievementFamily.correction:
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 17),
          -.2,
          math.pi * 1.45,
          false,
          line..strokeWidth = 2.2,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-17, -8)
            ..lineTo(-19, 1)
            ..lineTo(-10, -2),
          line,
        );
        canvas.drawLine(const Offset(-8, 5), const Offset(-2, 11), line);
        canvas.drawLine(const Offset(-2, 11), const Offset(12, -8), line);
      case AchievementFamily.exploration:
        canvas.drawCircle(Offset.zero, 18, line);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 15, height: 36),
          line,
        );
        canvas.drawLine(const Offset(-18, 0), const Offset(18, 0), line);
        canvas.drawArc(
          Rect.fromCenter(center: Offset.zero, width: 34, height: 15),
          0,
          math.pi * 2,
          false,
          line,
        );
      case AchievementFamily.challenge:
        final diamond = Path()
          ..moveTo(0, -20)
          ..lineTo(18, 0)
          ..lineTo(0, 20)
          ..lineTo(-18, 0)
          ..close();
        canvas.drawPath(diamond, line..strokeWidth = 2.2);
        canvas.drawCircle(Offset.zero, 6.5, line);
        canvas.drawLine(const Offset(0, -13), const Offset(0, -6), line);
        canvas.drawLine(const Offset(0, 6), const Offset(0, 13), line);
      case AchievementFamily.consistency:
        final wave = Path()..moveTo(-22, 0);
        for (var x = -22.0; x <= 22; x += 1) {
          wave.lineTo(x, math.sin(x / 4.4) * 9);
        }
        canvas.drawPath(wave, line..strokeWidth = 2.2);
        canvas.drawLine(const Offset(-22, 14), const Offset(22, 14), faint);
        canvas.drawLine(const Offset(-22, -14), const Offset(22, -14), faint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AchievementSealPainter oldDelegate) =>
      oldDelegate.family != family ||
      oldDelegate.color != color ||
      oldDelegate.earned != earned ||
      oldDelegate.tier != tier;
}

class _RarityNotches extends StatelessWidget {
  const _RarityNotches({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < count; index++)
        Container(
          width: 3,
          height: 8 + index * 2,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
    ],
  );
}

class _ObservationDeck extends StatelessWidget {
  const _ObservationDeck({
    required this.strongest,
    required this.weakTopics,
    required this.distractors,
    required this.topicLabels,
    required this.recentExams,
  });

  final List<({TopicDescriptor topic, int completed})> strongest;
  final List<TopicInsight> weakTopics;
  final List<DistractorInsight> distractors;
  final Map<String, String> topicLabels;
  final List<RecentExamSummary> recentExams;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (strongest.isEmpty &&
                weakTopics.isEmpty &&
                recentExams.isEmpty) {
              return const _EmptyObservation();
            }
            final wide = constraints.maxWidth >= 820;
            final solved = _OrbitRegister(
              title: 'Recorded orbits',
              accent: GaussColors.signalBright,
              child: Column(
                children: [
                  for (final entry in strongest.take(6))
                    _OrbitReading(
                      topicKey: entry.topic.key,
                      label: entry.topic.label,
                      value: '${entry.completed}',
                      unit: entry.completed == 1 ? 'SOLVED' : 'SOLVED',
                      color: GaussColors.signalBright,
                    ),
                  if (strongest.isEmpty)
                    const _QuietMessage(
                      text: 'Solved chapters will appear after a mission.',
                    ),
                ],
              ),
            );
            final focus = _OrbitRegister(
              title: 'Useful friction',
              accent: GaussColors.brassLight,
              child: Column(
                children: [
                  for (final insight in weakTopics.take(5))
                    _OrbitReading(
                      topicKey: insight.topicKey,
                      label: topicLabels[insight.topicKey] ?? insight.topicKey,
                      value: '${insight.accuracy.round()}%',
                      unit: '${insight.total} ATTEMPTS',
                      color: GaussColors.brassLight,
                    ),
                  if (weakTopics.isEmpty)
                    const _QuietMessage(
                      text: 'No reliable friction pattern yet.',
                    ),
                ],
              ),
            );
            final traps = _OrbitRegister(
              title: 'Recurring traps',
              accent: GaussColors.warning,
              child: Column(
                children: [
                  for (final trap in distractors.take(5))
                    _TrapReading(
                      trap: trap,
                      label: topicLabels[trap.topicKey] ?? trap.subject.label,
                    ),
                  if (distractors.isEmpty)
                    const _QuietMessage(
                      text:
                          'No repeated trap yet. Your misses look random, not patterned.',
                    ),
                ],
              ),
            );
            final recent = _OrbitRegister(
              title: 'Recent missions',
              accent: GaussColors.violet,
              child: Column(
                children: [
                  for (final exam in recentExams)
                    _RecentMissionReading(
                      exam: exam,
                      label: exam.topicKey == 'revenge'
                          ? 'Revisit mistakes'
                          : exam.topicKey == 'review'
                          ? 'Review orbit'
                          : topicLabels[exam.topicKey] ?? exam.subject.label,
                    ),
                  if (recentExams.isEmpty)
                    const _QuietMessage(text: 'No completed missions yet.'),
                ],
              ),
            );
            if (!wide) {
              return Column(
                children: [
                  solved,
                  const SizedBox(height: 11),
                  focus,
                  const SizedBox(height: 11),
                  traps,
                  const SizedBox(height: 11),
                  recent,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: solved),
                    const SizedBox(width: 11),
                    Expanded(child: focus),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: traps),
                    const SizedBox(width: 11),
                    Expanded(child: recent),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _OrbitRegister extends StatelessWidget {
  const _OrbitRegister({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: GaussColors.ink.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: GaussColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        child,
      ],
    ),
  );
}

class _OrbitReading extends StatelessWidget {
  const _OrbitReading({
    required this.topicKey,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String topicKey;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GaussColors.deepInk,
            border: Border.all(color: color.withValues(alpha: .35)),
          ),
          child: TopicGlyph(topicKey: topicKey, color: color, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                color: GaussColors.fog,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: .35,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RecentMissionReading extends StatelessWidget {
  const _RecentMissionReading({required this.exam, required this.label});

  final RecentExamSummary exam;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 40,
          child: CustomPaint(
            painter: _RingPainter(
              progress: exam.scorePercentage / 100,
              trackColor: GaussColors.hairline,
              valueColor: GaussColors.violet,
              strokeWidth: 3,
            ),
            child: Center(
              child: Text(
                '${exam.scorePercentage.round()}',
                style: const TextStyle(
                  color: GaussColors.ivory,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${exam.correctCount}/${exam.totalQuestions}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 12),
        Text(
          '${exam.completedAt.month}/${exam.completedAt.day}',
          style: const TextStyle(color: GaussColors.fog, fontSize: 10),
        ),
      ],
    ),
  );
}

class _TrapReading extends StatelessWidget {
  const _TrapReading({required this.trap, required this.label});

  final DistractorInsight trap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + trap.choiceIndex);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Recurring trap. Choice $letter in $label caught you ${trap.count} times.',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GaussColors.deepInk,
                border: Border.all(
                  color: GaussColors.warning.withValues(alpha: .45),
                ),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: GaussColors.warning,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                  Text(
                    'Choice $letter keeps luring you here',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${trap.count}×',
                  style: const TextStyle(
                    color: GaussColors.warning,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'CAUGHT',
                  style: TextStyle(
                    color: GaussColors.fog,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StarChartPanel extends StatelessWidget {
  const _StarChartPanel({required this.heatmap});

  /// Day-key (`YYYY-MM-DD`) to finalized answer count, from analytics.
  final Map<String, int> heatmap;

  static const _weeks = 12;

  static String _dayKeyOf(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Saturday-first row index so the study week reads Sat..Fri top to bottom.
  static int _rowOf(DateTime date) => (date.weekday + 1) % 7;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final chartStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: (_weeks - 1) * 7 + _rowOf(today)));
    final cells = <_StarCell>[];
    var activeDays = 0;
    var busiest = 0;
    for (var column = 0; column < _weeks; column++) {
      for (var row = 0; row < 7; row++) {
        final date = chartStart.add(Duration(days: column * 7 + row));
        if (date.isAfter(today)) continue;
        final count = heatmap[_dayKeyOf(date)] ?? 0;
        if (count > 0) {
          activeDays++;
          if (count > busiest) busiest = count;
        }
        cells.add(
          _StarCell(
            column: column,
            row: row,
            count: count,
            isToday:
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day,
          ),
        );
      }
    }
    final monthLabels = List<String>.filled(_weeks, '');
    String? previousMonth;
    for (var column = 0; column < _weeks; column++) {
      final weekStart = chartStart.add(Duration(days: column * 7));
      final month = _monthName(weekStart.month);
      if (month != previousMonth) {
        monthLabels[column] = month;
        previousMonth = month;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Star chart of the last twelve weeks. $activeDays active '
                '${activeDays == 1 ? 'day' : 'days'}. '
                '${busiest == 0 ? 'No recorded answers in this window.' : 'Busiest day held $busiest answers.'}',
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
              decoration: BoxDecoration(
                color: GaussColors.ink.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: GaussColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 2,
                        decoration: BoxDecoration(
                          color: GaussColors.brassLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'STAR CHART',
                        style: TextStyle(
                          color: GaussColors.brassLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$activeDays lit ${activeDays == 1 ? 'day' : 'days'}',
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 122,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _StarChartPainter(
                        cells: cells,
                        weeks: _weeks,
                        busiest: busiest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final label in monthLabels)
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              color: GaussColors.fog,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Every answered day lights a star. Brighter stars held more work.',
                    style: TextStyle(color: GaussColors.fog, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) => const [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ][month - 1];
}

class _StarCell {
  const _StarCell({
    required this.column,
    required this.row,
    required this.count,
    required this.isToday,
  });

  final int column;
  final int row;
  final int count;
  final bool isToday;
}

class _StarChartPainter extends CustomPainter {
  const _StarChartPainter({
    required this.cells,
    required this.weeks,
    required this.busiest,
  });

  final List<_StarCell> cells;
  final int weeks;
  final int busiest;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / weeks;
    final cellHeight = size.height / 7;
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = GaussColors.brass.withValues(alpha: .08);
    canvas.drawCircle(
      Offset(size.width * .18, size.height * 1.35),
      size.height * 1.5,
      orbit,
    );
    canvas.drawCircle(
      Offset(size.width * .86, -size.height * .5),
      size.height * 1.25,
      orbit,
    );

    for (final cell in cells) {
      final center = Offset(
        cellWidth * (cell.column + .5),
        cellHeight * (cell.row + .5),
      );
      if (cell.count == 0) {
        canvas.drawCircle(
          center,
          1.1,
          Paint()..color = GaussColors.fog.withValues(alpha: .22),
        );
      } else {
        // Perceptually even ramp: sqrt keeps one answer visible while a heavy
        // day still reads clearly brighter.
        final intensity = busiest == 0
            ? 1.0
            : (math.sqrt(cell.count / busiest)).clamp(.35, 1.0);
        final radius = 2.6 + 3.2 * intensity;
        canvas.drawCircle(
          center,
          radius * 1.9,
          Paint()
            ..color = GaussColors.brass.withValues(alpha: .16 * intensity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        _drawStar(
          canvas,
          center,
          radius,
          Color.lerp(
            GaussColors.brassLight,
            GaussColors.ivory,
            intensity * .55,
          )!.withValues(alpha: .45 + .55 * intensity),
        );
      }
      if (cell.isToday) {
        canvas.drawCircle(
          center,
          math.min(cellWidth, cellHeight) * .42,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = GaussColors.signalBright.withValues(alpha: .65),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const waist = .34;
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + radius * waist * .4,
      center.dy - radius * waist,
      center.dx + radius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx + radius * waist * .4,
      center.dy + radius * waist,
      center.dx,
      center.dy + radius,
    );
    path.quadraticBezierTo(
      center.dx - radius * waist * .4,
      center.dy + radius * waist,
      center.dx - radius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx - radius * waist * .4,
      center.dy - radius * waist,
      center.dx,
      center.dy - radius,
    );
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarChartPainter oldDelegate) =>
      oldDelegate.cells != cells || oldDelegate.busiest != busiest;
}

class _QuietMessage extends StatelessWidget {
  const _QuietMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      text,
      style: const TextStyle(color: GaussColors.fog, fontSize: 12),
    ),
  );
}

class _EmptyObservation extends StatelessWidget {
  const _EmptyObservation();

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 280),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
    decoration: BoxDecoration(
      color: GaussColors.ink.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: GaussColors.line),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final companion = Image.asset(
          'assets/visual/mascot/mira_thinking.png',
          height: compact ? 132 : 205,
          fit: BoxFit.contain,
          cacheHeight: compact ? 400 : 620,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Mira considering an empty observation lens',
        );
        final copy = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FIRST SIGNAL',
              style: TextStyle(
                color: GaussColors.brassLight,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One mission begins the sky.',
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              'Gauss will keep the record private and reveal patterns only when they become useful.',
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: const TextStyle(color: GaussColors.muted, height: 1.45),
            ),
            const SizedBox(height: 17),
            FilledButton(
              onPressed: () => context.go('/practice'),
              child: const Text('Build a proof set'),
            ),
          ],
        );
        if (compact) {
          return Column(
            children: [companion, const SizedBox(height: 10), copy],
          );
        }
        return Row(
          children: [
            Expanded(child: companion),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: copy),
          ],
        );
      },
    ),
  );
}

class _SignalDialPainter extends CustomPainter {
  const _SignalDialPainter({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .43;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = GaussColors.hairline;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = active ? GaussColors.signalBright : GaussColors.brassDeep;
    canvas.drawCircle(center, radius, track);
    canvas.drawCircle(center, radius * .72, track..strokeWidth = 1);
    if (active) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0, 1),
        false,
        ring,
      );
    }
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 7);
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 3);
      canvas.drawLine(inner, outer, track..strokeWidth = i % 3 == 0 ? 1.6 : .8);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalDialPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.active != active;
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.valueColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color valueColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = valueColor;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      value,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.valueColor != valueColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _LensGridPainter extends CustomPainter {
  const _LensGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = GaussColors.brass.withValues(alpha: .09);
    final center = Offset(size.width * .16, size.height * .48);
    for (var radius = 70.0; radius < size.width; radius += 68) {
      canvas.drawCircle(center, radius, paint);
    }
    final star = Paint()
      ..style = PaintingStyle.fill
      ..color = GaussColors.signal.withValues(alpha: .25);
    final points = <Offset>[
      Offset(size.width * .72, size.height * .17),
      Offset(size.width * .91, size.height * .32),
      Offset(size.width * .62, size.height * .78),
      Offset(size.width * .84, size.height * .86),
    ];
    for (final point in points) {
      canvas.drawCircle(point, 1.2, star);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _rarityColor(AchievementRarity rarity) => switch (rarity) {
  AchievementRarity.common => GaussColors.muted,
  AchievementRarity.uncommon => GaussColors.signalBright,
  AchievementRarity.rare => GaussColors.ice,
  AchievementRarity.epic => GaussColors.violet,
  AchievementRarity.legendary => GaussColors.brassLight,
};
