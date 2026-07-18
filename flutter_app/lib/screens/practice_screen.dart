import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/scratchpad.dart';

String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

String _subjectTitle(Subject subject) =>
    subject == Subject.math ? 'Mathematics' : 'Physics';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Subject _subject = Subject.math;

  void _openNode(BuildContext context, StudyPathNode node) {
    context.push(
      '/study/chapter/${node.topic.key}'
      '?offset=${node.offset}&count=${GaussStudyCurriculum.batchSize}',
    );
  }

  StudyPathNode _continueNode(GaussController controller) {
    final nodes = [
      for (final section in GaussStudyCurriculum.forSubject(_subject))
        ...GaussStudyCurriculum.nodesFor(section, controller.topics),
    ];
    return nodes.firstWhere(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
      orElse: () => nodes.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final sections = GaussStudyCurriculum.forSubject(_subject);
    final continueNode = _continueNode(controller);
    final subjectQuestions = controller.topics
        .where((topic) => topic.subject == _subject)
        .fold<int>(0, (total, topic) => total + topic.questionCount);
    final subjectReflected = sections
        .expand(
          (section) =>
              GaussStudyCurriculum.nodesFor(section, controller.topics),
        )
        .fold<int>(
          0,
          (total, node) => total + controller.study.shelf(node.key).reflected,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        const _StudyBackdrop(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).width < 760 ? 88 : 0,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _StudyHeader(
                    controller: controller,
                    subject: _subject,
                    onScratchpad: () => showScratchpad(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SubjectSwitch(
                    subject: _subject,
                    onChanged: (subject) => setState(() => _subject = subject),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ContinueInstrument(
                    node: continueNode,
                    snapshot: controller.study.shelf(continueNode.key),
                    subjectReflected: subjectReflected,
                    subjectQuestions: subjectQuestions,
                    onOpen: () => _openNode(context, continueNode),
                    onMap: () => context.go('/map'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _StudyModes(
                    revisitCount: controller.study.revisitCount,
                    onRevisit: () => context.push('/study/revisit'),
                    onScratchpad: () => showScratchpad(context),
                    onMap: () => context.go('/map'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: '${_subjectTitle(_subject).toUpperCase()} ATLAS',
                    title: '${sections.length} focused sections',
                    detail:
                        'Every chapter is divided into calm sets of up to ${GaussStudyCurriculum.batchSize} source questions. Nothing is locked.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 126),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 1040
                          ? 2
                          : 1;
                      final aspectRatio = columns == 2
                          ? 1.02
                          : constraints.crossAxisExtent >= 700
                          ? 1.55
                          : .72;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: sections.length,
                        itemBuilder: (context, index) => _SectionAtlasCard(
                          number: index + 1,
                          section: sections[index],
                          controller: controller,
                          onOpen: (node) => _openNode(context, node),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudyBackdrop extends StatelessWidget {
  const _StudyBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/visual/map/orrery_atmosphere_portrait.png',
        fit: BoxFit.cover,
        cacheWidth: 1400,
        filterQuality: FilterQuality.medium,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xB4061116), Color(0xF503090B)],
            stops: [.06, .72],
          ),
        ),
      ),
    ],
  );
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.controller,
    required this.subject,
    required this.onScratchpad,
  });

  final GaussController controller;
  final Subject subject;
  final VoidCallback onScratchpad;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 12, 9),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Row(
          children: [
            const GaussWordmark(width: 122),
            const SizedBox(width: 14),
            Container(width: 1, height: 30, color: GaussColors.hairline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STUDY OBSERVATORY',
                    style: TextStyle(
                      color: GaussColors.brassLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.35,
                    ),
                  ),
                  Text(
                    '${_formatCount(controller.totalQuestions)} source questions · fully offline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onScratchpad,
              tooltip: 'Open scratchpad',
              icon: const Icon(Icons.draw_outlined),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SubjectSwitch extends StatelessWidget {
  const _SubjectSwitch({required this.subject, required this.onChanged});

  final Subject subject;
  final ValueChanged<Subject> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _StudyGlass(
          radius: 22,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (final item in Subject.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: subject == item,
                    child: InkWell(
                      onTap: () => onChanged(item),
                      borderRadius: BorderRadius.circular(17),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: subject == item
                              ? LinearGradient(
                                  colors: item == Subject.math
                                      ? const [
                                          Color(0xFFCE9230),
                                          Color(0xFF8C5B15),
                                        ]
                                      : const [
                                          Color(0xFF3F9F9A),
                                          Color(0xFF235E66),
                                        ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item == Subject.math
                                  ? Icons.functions_rounded
                                  : Icons.bolt_rounded,
                              size: 20,
                              color: subject == item
                                  ? GaussColors.ivory
                                  : GaussColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _subjectTitle(item),
                                  style: TextStyle(
                                    color: subject == item
                                        ? GaussColors.ivory
                                        : GaussColors.muted,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ContinueInstrument extends StatelessWidget {
  const _ContinueInstrument({
    required this.node,
    required this.snapshot,
    required this.subjectReflected,
    required this.subjectQuestions,
    required this.onOpen,
    required this.onMap,
  });

  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final int subjectReflected;
  final int subjectQuestions;
  final VoidCallback onOpen;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: _StudyGlass(
          radius: 28,
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 680;
              final emblem = _OrbitEmblem(
                progress: node.questionCount == 0
                    ? 0
                    : snapshot.reflected / node.questionCount,
              );
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CONTINUE YOUR ORBIT',
                    style: TextStyle(
                      color: GaussColors.brassLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      node.topic.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${node.setLabel} · ${snapshot.reflected}/${node.questionCount} charted',
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: subjectQuestions == 0
                          ? 0
                          : subjectReflected / subjectQuestions,
                      backgroundColor: GaussColors.line,
                      valueColor: const AlwaysStoppedAnimation(
                        GaussColors.signalBright,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$subjectReflected of ${_formatCount(subjectQuestions)} questions reflected on',
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Wrap(
                    spacing: 10,
                    runSpacing: 9,
                    children: [
                      FilledButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: Text(
                          snapshot.reflected == 0 ? 'Begin set' : 'Resume set',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onMap,
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('View path'),
                      ),
                    ],
                  ),
                ],
              );
              if (!wide) {
                return Column(
                  children: [emblem, const SizedBox(height: 16), copy],
                );
              }
              return Row(
                children: [
                  emblem,
                  const SizedBox(width: 26),
                  Expanded(child: copy),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _OrbitEmblem extends StatelessWidget {
  const _OrbitEmblem({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 126,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: 116,
          child: CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: GaussColors.line,
            color: GaussColors.brass,
          ),
        ),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF17353A), GaussColors.deepInk],
            ),
            border: Border.all(color: GaussColors.brass, width: 2),
            boxShadow: [
              BoxShadow(
                color: GaussColors.brass.withValues(alpha: .18),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(child: TheoremStarMark(size: 55)),
        ),
      ],
    ),
  );
}

class _StudyModes extends StatelessWidget {
  const _StudyModes({
    required this.revisitCount,
    required this.onRevisit,
    required this.onScratchpad,
    required this.onMap,
  });

  final int revisitCount;
  final VoidCallback onRevisit;
  final VoidCallback onScratchpad;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (
        icon: Icons.loop_rounded,
        title: 'Revisit orbit',
        detail: revisitCount == 0
            ? 'Nothing waiting'
            : '$revisitCount concepts waiting',
        onTap: onRevisit,
      ),
      (
        icon: Icons.draw_outlined,
        title: 'Scratchpad',
        detail: 'Full-sheet freehand work',
        onTap: onScratchpad,
      ),
      (
        icon: Icons.route_outlined,
        title: 'Path atlas',
        detail: 'Browse the continuous route',
        onTap: onMap,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              if (compact) {
                return Column(
                  children: [
                    for (final mode in modes) ...[
                      _ModePlate(
                        icon: mode.icon,
                        title: mode.title,
                        detail: mode.detail,
                        onTap: mode.onTap,
                      ),
                      const SizedBox(height: 9),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < modes.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _ModePlate(
                        icon: modes[index].icon,
                        title: modes[index].title,
                        detail: modes[index].detail,
                        onTap: modes[index].onTap,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModePlate extends StatelessWidget {
  const _ModePlate({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _StudyGlass(
    radius: 19,
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: GaussColors.brass.withValues(alpha: .11),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .28),
                ),
              ),
              child: Icon(icon, color: GaussColors.brassLight, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: GaussColors.fog,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 13),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: GaussColors.brassLight,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(
                color: GaussColors.muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionAtlasCard extends StatelessWidget {
  const _SectionAtlasCard({
    required this.number,
    required this.section,
    required this.controller,
    required this.onOpen,
  });

  final int number;
  final StudySectionDefinition section;
  final GaussController controller;
  final ValueChanged<StudyPathNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    final topics = [
      for (final key in section.topicKeys)
        controller.topics.firstWhere((topic) => topic.key == key),
    ];
    final total = nodes.fold<int>(0, (sum, node) => sum + node.questionCount);
    final reflected = nodes.fold<int>(
      0,
      (sum, node) => sum + controller.study.shelf(node.key).reflected,
    );
    return _StudyGlass(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE1AD4C), Color(0xFF8B5713)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GaussColors.brass.withValues(alpha: .25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: GaussColors.deepInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${topics.length} units · ${nodes.length} study sets',
                      style: const TextStyle(
                        color: GaussColors.fog,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$reflected/$total',
                style: const TextStyle(
                  color: GaussColors.signalBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            section.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GaussColors.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: total == 0 ? 0 : reflected / total,
              backgroundColor: GaussColors.line,
              color: GaussColors.signal,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final topic = topics[index];
                final topicNodes = nodes
                    .where((node) => node.topic.key == topic.key)
                    .toList(growable: false);
                final topicReflected = topicNodes.fold<int>(
                  0,
                  (sum, node) =>
                      sum + controller.study.shelf(node.key).reflected,
                );
                final nextNode = topicNodes.firstWhere(
                  (node) =>
                      controller.study.shelf(node.key).reflected <
                      node.questionCount,
                  orElse: () => topicNodes.last,
                );
                return _UnitRow(
                  index: index + 1,
                  topic: topic,
                  setCount: topicNodes.length,
                  reflected: topicReflected,
                  onOpen: () => onOpen(nextNode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.index,
    required this.topic,
    required this.setCount,
    required this.reflected,
    required this.onOpen,
  });

  final int index;
  final TopicDescriptor topic;
  final int setCount;
  final int reflected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: GaussColors.raised.withValues(alpha: .62),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 29,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: GaussColors.hairline),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      topic.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GaussColors.ivory,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$setCount sets · $reflected/${topic.questionCount} charted',
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: GaussColors.brassLight,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

class _StudyGlass extends StatelessWidget {
  const _StudyGlass({
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GaussColors.panelHigh.withValues(alpha: .88),
              GaussColors.deepInk.withValues(alpha: .82),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .22)),
        ),
        child: child,
      ),
    ),
  );
}
