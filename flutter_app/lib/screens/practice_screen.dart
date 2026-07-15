import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/mission_start_guard.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Subject _subject = Subject.math;
  String? _selectedTopicKey;
  final Set<Difficulty> _difficulties = {};
  int _count = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedTopicKey ??= GaussScope.of(
      context,
    ).topics.firstWhere((topic) => topic.subject == _subject).key;
  }

  void _selectSubject(Subject subject) {
    final controller = GaussScope.of(context);
    setState(() {
      _subject = subject;
      _selectedTopicKey = controller.topics
          .firstWhere((topic) => topic.subject == subject)
          .key;
    });
  }

  Future<void> _startMission() async {
    final topic = _selectedTopicKey;
    if (topic == null) return;
    final controller = GaussScope.of(context);
    if (controller.topics
            .firstWhere((descriptor) => descriptor.key == topic)
            .missionReadyCount ==
        0) {
      return;
    }
    if (!await confirmMissionReplacement(
          context,
          controller.resumableMission,
        ) ||
        !mounted) {
      return;
    }
    final query = <String>['count=$_count'];
    for (final difficulty in _difficulties) {
      query.add('difficulty=${Uri.encodeQueryComponent(difficulty.key)}');
    }
    context.push('/mission/$topic?${query.join('&')}');
  }

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final topics = controller.topics
        .where((topic) => topic.subject == _subject)
        .toList(growable: false);
    final selected = topics.firstWhere(
      (topic) => topic.key == _selectedTopicKey,
      orElse: () => topics.first,
    );
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice observatory',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Build a focused mission from the complete offline archive, or revisit mistakes that are due.',
                      style: TextStyle(color: GaussColors.muted),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 700;
                        final cards = [
                          if (controller.resumableMission case final saved?)
                            _ModeCard(
                              icon: Icons.play_circle_outline,
                              title: 'Resume mission',
                              detail:
                                  '${saved.answeredCount} of ${saved.questions.length} answers recorded. Continue from the exact next orbit.',
                              accent: GaussColors.violet,
                              action: 'Resume now',
                              onTap: () => context.push('/resume'),
                            ),
                          _ModeCard(
                            icon: Icons.explore_outlined,
                            title: 'Orbit mission',
                            detail: 'Choose subject, topic, and challenge.',
                            accent: GaussColors.brassLight,
                            action: 'Configure below',
                          ),
                          _ModeCard(
                            icon: Icons.replay_circle_filled_outlined,
                            title: 'Revenge review',
                            detail: controller.revengeCount == 0
                                ? 'No due mistakes. Finish a mission to build your queue.'
                                : '${controller.revengeCount} due questions from past mistakes.',
                            accent: GaussColors.teal,
                            action: controller.revengeCount == 0
                                ? 'Queue clear'
                                : 'Start review',
                            onTap: controller.revengeCount == 0
                                ? null
                                : () => context.push('/revenge?count=10'),
                          ),
                        ];
                        return narrow
                            ? Column(
                                children: [
                                  for (final card in cards)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: card,
                                    ),
                                ],
                              )
                            : Row(
                                children: [
                                  for (
                                    var index = 0;
                                    index < cards.length;
                                    index++
                                  ) ...[
                                    Expanded(child: cards[index]),
                                    if (index < cards.length - 1)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 20),
                    _FiltersPanel(
                      subject: _subject,
                      difficulties: _difficulties,
                      count: _count,
                      missionReadyCount: controller.missionReadyQuestions,
                      preservedArchiveCount:
                          controller.preservedArchiveQuestions,
                      onSubject: _selectSubject,
                      onDifficulty: (difficulty) => setState(() {
                        _difficulties.contains(difficulty)
                            ? _difficulties.remove(difficulty)
                            : _difficulties.add(difficulty);
                      }),
                      onCount: (count) => setState(() => _count = count),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          _subject == Subject.math
                              ? 'Mathematics orbits'
                              : 'Physics orbits',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          '${topics.length} topics',
                          style: const TextStyle(color: GaussColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent >= 1050
                  ? 4
                  : (constraints.crossAxisExtent >= 680 ? 3 : 1);
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 2.8 : 1.2,
                ),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return _PracticeTopicCard(
                    topic: topic,
                    completed: controller.completedInTopic(topic.key),
                    selected: topic.key == selected.key,
                    onTap: () => setState(() => _selectedTopicKey = topic.key),
                  );
                },
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: GaussColors.brass.withValues(
                            alpha: .16,
                          ),
                          child: Icon(
                            _subject == Subject.math
                                ? Icons.functions
                                : Icons.bolt,
                            color: GaussColors.brassLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  selected.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '$_count questions · ${_difficulties.isEmpty ? 'any difficulty' : '${_difficulties.length} difficulties'}',
                                style: const TextStyle(
                                  color: GaussColors.muted,
                                ),
                              ),
                              Text(
                                '${selected.missionReadyCount} mission-ready · ${selected.preservedArchiveCount} preserved',
                                style: const TextStyle(
                                  color: GaussColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: selected.missionReadyCount == 0
                              ? null
                              : _startMission,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            selected.missionReadyCount == 0
                                ? 'Archive only'
                                : 'Start mission',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
    required this.action,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final Color accent;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: .14),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(color: GaussColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              action,
              style: TextStyle(
                color: onTap == null ? GaussColors.muted : accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.subject,
    required this.difficulties,
    required this.count,
    required this.missionReadyCount,
    required this.preservedArchiveCount,
    required this.onSubject,
    required this.onDifficulty,
    required this.onCount,
  });
  final Subject subject;
  final Set<Difficulty> difficulties;
  final int count;
  final int missionReadyCount;
  final int preservedArchiveCount;
  final ValueChanged<Subject> onSubject;
  final ValueChanged<Difficulty> onDifficulty;
  final ValueChanged<int> onCount;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MISSION FILTERS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: GaussColors.brassLight,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Math'),
                selected: subject == Subject.math,
                onSelected: (_) => onSubject(Subject.math),
              ),
              ChoiceChip(
                label: const Text('Physics'),
                selected: subject == Subject.physics,
                onSelected: (_) => onSubject(Subject.physics),
              ),
              for (final value in [10, 20, 30, 50])
                ChoiceChip(
                  label: Text('$value questions'),
                  selected: count == value,
                  onSelected: (_) => onCount(value),
                ),
            ],
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final difficulty in Difficulty.values)
                FilterChip(
                  label: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(difficulty.label),
                  ),
                  selected: difficulties.contains(difficulty),
                  onSelected: (_) => onDifficulty(difficulty),
                ),
              _ArchiveStatusPill(
                icon: Icons.verified_outlined,
                label: 'Gauss · $missionReadyCount mission-ready',
              ),
              _ArchiveStatusPill(
                icon: Icons.inventory_2_outlined,
                label: 'Nardebam · $preservedArchiveCount preserved',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            label:
                'Source integrity notice. $missionReadyCount contract-checked Gauss questions are mission ready. $preservedArchiveCount Nardebam items are preserved but quarantined from scoring.',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GaussColors.brass.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .28),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: GaussColors.brassLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mission-ready: $missionReadyCount contract-checked Gauss questions. Preserved archive: $preservedArchiveCount Nardebam items are kept locally but excluded from scoring because source explanations and some answer keys conflict.',
                      style: const TextStyle(
                        color: GaussColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArchiveStatusPill extends StatelessWidget {
  const _ArchiveStatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GaussColors.raised,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: GaussColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: GaussColors.brassLight),
              const SizedBox(width: 7),
              Text(label),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PracticeTopicCard extends StatelessWidget {
  const _PracticeTopicCard({
    required this.topic,
    required this.completed,
    required this.selected,
    required this.onTap,
  });
  final TopicDescriptor topic;
  final int completed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected ? GaussColors.brassLight : GaussColors.line,
        width: selected ? 2 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  topic.subject == Subject.math ? Icons.functions : Icons.bolt,
                  color: topic.subject == Subject.math
                      ? GaussColors.violet
                      : GaussColors.ice,
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: GaussColors.brassLight,
                  ),
                const SizedBox(width: 6),
                Text(
                  '${topic.missionReadyCount}/${topic.questionCount}',
                  style: const TextStyle(color: GaussColors.muted),
                ),
              ],
            ),
            const Spacer(),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                topic.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              topic.missionReadyCount == 0
                  ? 'Archive preserved · scoring off'
                  : (completed == 0 ? 'Not started' : '$completed mastered'),
              style: const TextStyle(color: GaussColors.muted),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: topic.missionReadyCount == 0
                  ? 0
                  : (completed / topic.missionReadyCount).clamp(0, 1),
              minHeight: 5,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: GaussColors.line,
            ),
          ],
        ),
      ),
    ),
  );
}
