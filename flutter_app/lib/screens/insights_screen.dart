import 'package:flutter/material.dart';

import '../app/gauss_theme.dart';
import '../domain/gamification_catalog.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your observatory',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Only recorded attempts appear here—no preview statistics or invented progress.',
                style: TextStyle(color: GaussColors.muted),
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 700;
                  final cards = [
                    _MetricCard(
                      label: 'Experience',
                      value: '${controller.xp}',
                      suffix: 'XP',
                      icon: Icons.auto_awesome,
                    ),
                    _MetricCard(
                      label: 'Attempts',
                      value: '${analytics.totalAnswered}',
                      suffix: 'answers',
                      icon: Icons.fact_check_outlined,
                    ),
                    _MetricCard(
                      label: 'Accuracy',
                      value: '${(controller.accuracy * 100).round()}',
                      suffix: '%',
                      icon: Icons.track_changes,
                    ),
                    _MetricCard(
                      label: 'Study rhythm',
                      value: '${analytics.streak}',
                      suffix: analytics.streak == 1 ? 'day' : 'days',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ];
                  final columns = narrow ? 1 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final card in cards)
                        SizedBox(width: width, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _DailyQuestCard(quest: gamification.quest),
              const SizedBox(height: 24),
              Text(
                'Signal badges',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Private milestones derived only from recorded missions.',
                style: TextStyle(color: GaussColors.muted),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 580
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final achievement in gamification.achievements)
                        SizedBox(
                          width: width,
                          child: _AchievementCard(snapshot: achievement),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Mastery by orbit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (strongest.isEmpty)
                const _EmptyInsights()
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        for (final entry in strongest.take(10))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(entry.topic.label),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${entry.completed} mastered',
                                  style: const TextStyle(
                                    color: GaussColors.teal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (analytics.weakTopics.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Focus next',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        for (final insight in analytics.weakTopics.take(5))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      controller.topics
                                          .firstWhere(
                                            (topic) =>
                                                topic.key == insight.topicKey,
                                          )
                                          .label,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${insight.accuracy.round()}% · ${insight.total} attempts',
                                  style: const TextStyle(
                                    color: GaussColors.brassLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (controller.recentExams.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Recent missions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        for (final exam in controller.recentExams)
                          _RecentExamRow(
                            exam: exam,
                            label: exam.topicKey == 'revenge'
                                ? 'Revenge review'
                                : topicLabels[exam.topicKey] ??
                                      exam.subject.label,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentExamRow extends StatelessWidget {
  const _RecentExamRow({required this.exam, required this.label});
  final RecentExamSummary exam;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: GaussColors.brass.withValues(alpha: .12),
          child: Text(
            '${exam.scorePercentage.round()}',
            style: const TextStyle(
              color: GaussColors.brassLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(label),
          ),
        ),
        Text(
          '${exam.correctCount} / ${exam.totalQuestions}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 14),
        Text(
          '${exam.completedAt.month}/${exam.completedAt.day}',
          style: const TextStyle(color: GaussColors.muted),
        ),
      ],
    ),
  );
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({required this.quest});
  final DailyQuest quest;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: GaussColors.teal.withValues(alpha: .14),
            child: Icon(
              quest.completed ? Icons.check : Icons.flag_outlined,
              color: GaussColors.teal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily quest · +${quest.rewardXp} XP',
                  style: const TextStyle(
                    color: GaussColors.teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(quest.title),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: quest.target == 0 ? 0 : quest.progress / quest.target,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: GaussColors.line,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${quest.progress} / ${quest.target}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.snapshot});

  final AchievementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final definition = snapshot.definition;
    final earned = snapshot.earnedLevel;
    final next = snapshot.nextLevel;
    final rarity = earned?.rarity ?? next?.rarity ?? AchievementRarity.common;
    final color = _rarityColor(rarity);
    final progressLabel = next == null
        ? 'All ${definition.levels.length} levels recorded'
        : '${snapshot.current} of ${next.threshold} toward ${next.title}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${definition.accessibilityLabel}. ${earned?.title ?? 'Not yet earned'}. '
          '$progressLabel. ${rarity.label} tier.',
      child: Card(
        child: SizedBox(
          height: 224,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: .12),
                        border: Border.all(color: color.withValues(alpha: .58)),
                      ),
                      child: Icon(_familyIcon(definition.family), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            definition.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            earned?.title ?? 'Uncharted',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RarityNotches(count: rarity.index + 1, color: color),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  definition.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GaussColors.muted,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: snapshot.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: GaussColors.line,
                  color: color,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        next == null
                            ? 'Constellation complete'
                            : '${snapshot.current} / ${next.threshold}',
                        style: const TextStyle(
                          color: GaussColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      rarity.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
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

  static IconData _familyIcon(AchievementFamily family) => switch (family) {
    AchievementFamily.mastery => Icons.functions,
    AchievementFamily.correction => Icons.change_circle_outlined,
    AchievementFamily.exploration => Icons.public,
    AchievementFamily.challenge => Icons.workspace_premium_outlined,
    AchievementFamily.consistency => Icons.graphic_eq,
  };

  static Color _rarityColor(AchievementRarity rarity) => switch (rarity) {
    AchievementRarity.common => GaussColors.muted,
    AchievementRarity.uncommon => GaussColors.teal,
    AchievementRarity.rare => const Color(0xFF63A8FF),
    AchievementRarity.epic => const Color(0xFFC78CFF),
    AchievementRarity.legendary => GaussColors.brassLight,
  };
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
          height: 12 + index * 2,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
  });
  final String label;
  final String value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: GaussColors.brass.withValues(alpha: .14),
            child: Icon(icon, color: GaussColors.brassLight),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: GaussColors.muted)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' $suffix',
                      style: const TextStyle(color: GaussColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.auto_graph, size: 42, color: GaussColors.muted),
            const SizedBox(height: 12),
            Text(
              'No observations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete a mission to begin your real mastery record.',
              style: TextStyle(color: GaussColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
