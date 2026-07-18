import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/mission_start_guard.dart';
import '../widgets/scratchpad.dart';

String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

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
  bool _answerFirst = false;

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
    final topicKey = _selectedTopicKey;
    if (topicKey == null) return;
    final controller = GaussScope.of(context);
    final topic = controller.topics.firstWhere(
      (descriptor) => descriptor.key == topicKey,
    );
    if (topic.missionReadyCount == 0) return;
    final confirmed = await confirmMissionReplacement(
      context,
      controller.resumableMission,
    );
    if (!confirmed || !mounted) return;
    final query = <String>['count=$_count'];
    for (final difficulty in _difficulties) {
      query.add('difficulty=${Uri.encodeQueryComponent(difficulty.key)}');
    }
    if (_answerFirst) query.add('cover=1');
    await context.push('/mission/$topicKey?${query.join('&')}');
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
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PracticeBackdrop(),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PracticeHeader(
                  controller: controller,
                  onScratchpad: () => showScratchpad(context),
                ),
              ),
              SliverToBoxAdapter(
                child: _PracticeModes(
                  controller: controller,
                  onScratchpad: () => showScratchpad(context),
                ),
              ),
              SliverToBoxAdapter(
                child: _SetComposer(
                  subject: _subject,
                  difficulties: _difficulties,
                  count: _count,
                  answerFirst: _answerFirst,
                  totalQuestions: controller.totalQuestions,
                  onSubject: _selectSubject,
                  onDifficulty: (difficulty) => setState(() {
                    if (!_difficulties.remove(difficulty)) {
                      _difficulties.add(difficulty);
                    }
                  }),
                  onCount: (count) => setState(() => _count = count),
                  onAnswerFirst: () =>
                      setState(() => _answerFirst = !_answerFirst),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 23, 18, 10),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Row(
                        children: [
                          Text(
                            _subject == Subject.math
                                ? 'Mathematics chapters'
                                : 'Physics chapters',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '${topics.length} chapters',
                            style: const TextStyle(color: GaussColors.fog),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1030
                        ? 3
                        : constraints.crossAxisExtent >= 650
                        ? 2
                        : 1;
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 11,
                        crossAxisSpacing: 11,
                        childAspectRatio: columns == 1 ? 3.35 : 2.28,
                      ),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return _ChapterTile(
                          topic: topic,
                          completed: controller.completedInTopic(topic.key),
                          selected: topic.key == selected.key,
                          onTap: () =>
                              setState(() => _selectedTopicKey = topic.key),
                        );
                      },
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _LaunchDeck(
                  topic: selected,
                  completed: controller.completedInTopic(selected.key),
                  count: _count,
                  difficultyCount: _difficulties.length,
                  onStart: _startMission,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PracticeBackdrop extends StatelessWidget {
  const _PracticeBackdrop();

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
            colors: [Color(0xE007151C), GaussColors.abyss],
            stops: [0, .62],
          ),
        ),
      ),
    ],
  );
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({required this.controller, required this.onScratchpad});

  final GaussController controller;
  final VoidCallback onScratchpad;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
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
                            'PRACTICE DECK',
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
                        'Build a proof set',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        narrow
                            ? 'Choose a chapter, tune the set, and begin.'
                            : 'Choose a chapter, tune the challenge, and draw a focused set from your offline library.',
                        style: const TextStyle(color: GaussColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!narrow)
                  _TinyMetric(
                    label: 'DUE',
                    value: '${controller.reviewDueCount}',
                  ),
                if (!narrow) const SizedBox(width: 8),
                if (!narrow)
                  IconButton(
                    onPressed: onScratchpad,
                    tooltip: 'Open scratchpad',
                    icon: const GaussScratchGlyph(
                      color: GaussColors.signalBright,
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

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: GaussColors.signalBright,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class _PracticeModes extends StatelessWidget {
  const _PracticeModes({required this.controller, required this.onScratchpad});

  final GaussController controller;
  final VoidCallback onScratchpad;

  @override
  Widget build(BuildContext context) {
    final modes = <Widget>[
      if (controller.resumableMission case final saved?)
        _ModeTile(
          glyph: GaussDestinationGlyph.map,
          title: 'Resume mission',
          detail:
              '${saved.answeredCount} of ${saved.questions.length} recorded',
          accent: GaussColors.violet,
          onTap: () => context.push('/resume'),
        ),
      const _ModeTile(
        glyph: GaussDestinationGlyph.practice,
        title: 'Focus set',
        detail: 'Chapter, challenge, and length',
        accent: GaussColors.brassLight,
      ),
      _ModeTile(
        glyph: GaussDestinationGlyph.map,
        title: 'Review orbit',
        detail: controller.reviewDueCount == 0
            ? 'No stars are dimming today'
            : '${controller.reviewDueCount} proofs due before they fade',
        accent: GaussColors.brassLight,
        onTap: controller.reviewDueCount == 0
            ? null
            : () => context.push('/review?count=10'),
      ),
      _ModeTile(
        glyph: GaussDestinationGlyph.insights,
        title: 'Revisit mistakes',
        detail: controller.revengeCount == 0
            ? 'Nothing due right now'
            : '${controller.revengeCount} questions ready',
        accent: GaussColors.signalBright,
        onTap: controller.revengeCount == 0
            ? null
            : () => context.push('/revenge?count=10'),
      ),
      _ModeTile(
        glyph: GaussDestinationGlyph.practice,
        title: 'Open scratchpad',
        detail: 'Think freely without starting a set',
        accent: GaussColors.ice,
        onTap: onScratchpad,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? modes.length
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final mode in modes) SizedBox(width: width, child: mode),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.glyph,
    required this.title,
    required this.detail,
    required this.accent,
    this.onTap,
  });

  final GaussDestinationGlyph glyph;
  final String title;
  final String detail;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    enabled: onTap != null,
    label: '$title. $detail.',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: .12),
              GaussColors.raised.withValues(alpha: .94),
            ],
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: onTap == null
                ? GaussColors.hairline
                : accent.withValues(alpha: .42),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GaussColors.deepInk,
                border: Border.all(color: accent.withValues(alpha: .55)),
              ),
              child: GaussNavGlyph(glyph: glyph, selected: true, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_rounded, color: accent, size: 19),
          ],
        ),
      ),
    ),
  );
}

class _SetComposer extends StatelessWidget {
  const _SetComposer({
    required this.subject,
    required this.difficulties,
    required this.count,
    required this.answerFirst,
    required this.totalQuestions,
    required this.onSubject,
    required this.onDifficulty,
    required this.onCount,
    required this.onAnswerFirst,
  });

  final Subject subject;
  final Set<Difficulty> difficulties;
  final int count;
  final bool answerFirst;
  final int totalQuestions;
  final ValueChanged<Subject> onSubject;
  final ValueChanged<Difficulty> onDifficulty;
  final ValueChanged<int> onCount;
  final VoidCallback onAnswerFirst;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: GaussColors.ink.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: GaussColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  TheoremStarMark(size: 26),
                  SizedBox(width: 9),
                  Text(
                    'SET COMPOSER',
                    style: TextStyle(
                      color: GaussColors.brassLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChoiceToken(
                    label: 'Math',
                    selected: subject == Subject.math,
                    onTap: () => onSubject(Subject.math),
                  ),
                  _ChoiceToken(
                    label: 'Physics',
                    selected: subject == Subject.physics,
                    onTap: () => onSubject(Subject.physics),
                  ),
                  const SizedBox(width: 5),
                  for (final value in const [5, 10, 20, 30])
                    _ChoiceToken(
                      label: '$value questions',
                      selected: count == value,
                      onTap: () => onCount(value),
                    ),
                  const SizedBox(width: 5),
                  _ChoiceToken(
                    label: 'Answer-first',
                    selected: answerFirst,
                    onTap: onAnswerFirst,
                  ),
                ],
              ),
              if (answerFirst) ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 15,
                      color: GaussColors.brassLight,
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Choices stay covered until you uncover them — derive the answer before it can be recognized.',
                        style: TextStyle(
                          color: GaussColors.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 25),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final difficulty in Difficulty.values)
                    _ChoiceToken(
                      label: difficulty.label,
                      selected: difficulties.contains(difficulty),
                      rtl: true,
                      onTap: () => onDifficulty(difficulty),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 17,
                    color: GaussColors.signalBright,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your complete ${_formatCount(totalQuestions)}-question library stays on this device. Every practice set uses questions with a clear answer path.',
                      style: const TextStyle(
                        color: GaussColors.muted,
                        fontSize: 11,
                      ),
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

class _ChoiceToken extends StatelessWidget {
  const _ChoiceToken({
    required this.label,
    required this.selected,
    required this.onTap,
    this.rtl = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool rtl;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? GaussColors.brass.withValues(alpha: .14)
              : GaussColors.deepInk,
          borderRadius: BorderRadius.circular(GaussRadii.pill),
          border: Border.all(
            color: selected ? GaussColors.brassLight : GaussColors.hairline,
          ),
        ),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? GaussColors.brassLight : GaussColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
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
  Widget build(BuildContext context) {
    final progress = topic.missionReadyCount == 0
        ? 0.0
        : (completed / topic.missionReadyCount).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${topic.label}. ${topic.missionReadyCount == 0 ? 'No scored set yet.' : '$completed solved.'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 190),
          padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      GaussColors.brass.withValues(alpha: .16),
                      GaussColors.raised,
                    ]
                  : [GaussColors.panelHigh, GaussColors.raised],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? GaussColors.brassLight : GaussColors.line,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: topic.missionReadyCount == 0
                          ? const ColorFilter.matrix(<double>[
                              .4,
                              .4,
                              .4,
                              0,
                              0,
                              .4,
                              .4,
                              .4,
                              0,
                              0,
                              .4,
                              .4,
                              .4,
                              0,
                              0,
                              0,
                              0,
                              0,
                              .6,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: Image.asset(
                        'assets/visual/nodes/topic_shell.png',
                        cacheWidth: 360,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    TopicGlyph(
                      topicKey: topic.key,
                      size: 25,
                      color: selected
                          ? GaussColors.brassLight
                          : topic.subject == Subject.math
                          ? GaussColors.brass
                          : GaussColors.ice,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        topic.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.missionReadyCount == 0
                          ? 'Study archive · no scored set yet'
                          : completed == 0
                          ? 'Ready to begin'
                          : '$completed solved',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GaussColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(GaussRadii.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: TheoremStarMark(size: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchDeck extends StatelessWidget {
  const _LaunchDeck({
    required this.topic,
    required this.completed,
    required this.count,
    required this.difficultyCount,
    required this.onStart,
  });

  final TopicDescriptor topic;
  final int completed;
  final int count;
  final int difficultyCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GaussColors.brass.withValues(alpha: .12),
                GaussColors.ink.withValues(alpha: .98),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .4)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      topic.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    topic.missionReadyCount == 0
                        ? 'This chapter is preserved for study, but no scored set is available.'
                        : '$count questions · ${difficultyCount == 0 ? 'all challenge levels' : '$difficultyCount selected levels'} · $completed solved here',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
              final button = topic.missionReadyCount == 0
                  ? FilledButton.icon(
                      onPressed: topic.preservedArchiveCount == 0
                          ? null
                          : () => context.push('/archive/${topic.key}'),
                      icon: const Icon(Icons.menu_book_outlined, size: 19),
                      label: const Text('Reading room'),
                    )
                  : FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Start mission'),
                    );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [details, const SizedBox(height: 12), button],
                );
              }
              return Row(
                children: [
                  TopicGlyph(
                    topicKey: topic.key,
                    color: GaussColors.brassLight,
                    size: 38,
                  ),
                  const SizedBox(width: 13),
                  Expanded(child: details),
                  const SizedBox(width: 15),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
