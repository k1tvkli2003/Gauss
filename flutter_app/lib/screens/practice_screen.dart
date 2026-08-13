import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/orbital_action_control.dart';
import '../widgets/scratchpad.dart';

String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

String _subjectTitle(Subject subject) =>
    subject == Subject.math ? 'Mathematics' : 'Physics';

String _sessionLabel(StudyPathNode node) =>
    'Session ${node.partIndex + 1} of ${node.partCount}';

abstract final class _StudyGeometry {
  static const contentMaxWidth = 1180.0;
  static const courseMaxWidth = 760.0;
  static const compactCourseBreakpoint = 300.0;
  static const accessibleLayoutScale = 1.6;
  static const controlTrack = 48.0;
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Future<void> _openNode(BuildContext context, StudyPathNode node) async {
    await context.push('/mission/${node.topic.key}?offset=${node.offset}');
  }

  StudyPathNode _continueNode(
    GaussController controller,
    StudySectionDefinition section,
  ) {
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    final selectedTopicNodes = nodes
        .where((node) => node.topic.key == controller.selectedTopicKey)
        .toList(growable: false);
    final selectedTopicNext = selectedTopicNodes.where(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
    );
    if (selectedTopicNext.isNotEmpty) return selectedTopicNext.first;
    return nodes.firstWhere(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
      orElse: () =>
          selectedTopicNodes.isNotEmpty ? selectedTopicNodes.last : nodes.last,
    );
  }

  Future<void> _selectSection(
    GaussController controller,
    StudySectionDefinition section,
  ) async {
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    final destination = nodes.firstWhere(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
      orElse: () => nodes.first,
    );
    await controller.selectTopic(destination.topic.key);
  }

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final subject = controller.selectedTopic.subject;
    final window = GaussWindowClass.of(context);
    final sections = GaussStudyCurriculum.forSubject(subject);
    final activeSectionIndex = sections.indexWhere(
      (section) => section.topicKeys.contains(controller.selectedTopicKey),
    );
    final safeActiveSectionIndex = activeSectionIndex < 0
        ? 0
        : activeSectionIndex;
    final activeSection = sections[safeActiveSectionIndex];
    final continueNode = _continueNode(controller, activeSection);
    final previousSection =
        sections[(safeActiveSectionIndex - 1 + sections.length) %
            sections.length];
    final nextSection =
        sections[(safeActiveSectionIndex + 1) % sections.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        const _StudyBackdrop(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: window.isCompact ? GaussMetrics.compactChromeReserve : 0,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _StudyHeader(
                    controller: controller,
                    subject: subject,
                    onScratchpad: () => showScratchpad(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CourseInstrument(
                    subject: subject,
                    onChanged: controller.selectStudySubject,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ContinueInstrument(
                    node: continueNode,
                    snapshot: controller.study.shelf(continueNode.key),
                    subject: subject,
                    section: activeSection,
                    sectionIndex: safeActiveSectionIndex,
                    sectionCount: sections.length,
                    previousSectionTitle: previousSection.title,
                    nextSectionTitle: nextSection.title,
                    onPreviousSection: () =>
                        _selectSection(controller, previousSection),
                    onNextSection: () =>
                        _selectSection(controller, nextSection),
                    onOpen: () => _openNode(context, continueNode),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final breathingRoom =
                          constraints.maxWidth < 360 &&
                          MediaQuery.textScalerOf(context).scale(1) >=
                              _StudyGeometry.accessibleLayoutScale;
                      return SizedBox(
                        key: const ValueKey(
                          'study-accessible-footer-breathing-room',
                        ),
                        height: breathingRoom ? 64 : 0,
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: '${_subjectTitle(subject).toUpperCase()} ATLAS',
                    title: 'Library',
                    countLabel: '${sections.length} chapters',
                    detail:
                        'Choose a tool or open any chapter. Every micro-lesson stays one tap away.',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _StudyModes(
                    revisitCount: controller.study.revisitCount,
                    dueCount: controller.studyDueCount,
                    gemCount: controller.study.gemCount,
                    onGems: () => context.push('/study/gems'),
                    onRevisit: () => context.push('/study/revisit'),
                    onScratchpad: () => showScratchpad(context),
                    onMap: () => context.go('/map'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                    child: _SectionAtlas(
                      sections: sections,
                      controller: controller,
                      onOpen: (node) => _openNode(context, node),
                    ),
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
  Widget build(BuildContext context) {
    final accessible =
        MediaQuery.textScalerOf(context).scale(1) >=
        _StudyGeometry.accessibleLayoutScale;
    return Padding(
      key: const ValueKey('study-balanced-header'),
      padding: EdgeInsets.fromLTRB(
        18,
        accessible ? 8 : 18,
        18,
        accessible ? 6 : 9,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _StudyGeometry.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: const ValueKey('study-header-axis'),
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox.square(
                        key: ValueKey('study-offline-track'),
                        dimension: _StudyGeometry.controlTrack,
                        child: Center(child: _StudyOfflineSignal()),
                      ),
                    ),
                    const Center(
                      child: GaussWordmark(
                        key: ValueKey('study-centered-wordmark'),
                        width: 116,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox.square(
                        key: const ValueKey('study-scratch-track'),
                        dimension: _StudyGeometry.controlTrack,
                        child: IconButton.filledTonal(
                          key: const ValueKey('study-header-scratchpad'),
                          onPressed: onScratchpad,
                          tooltip: 'Open scratchpad',
                          icon: const Icon(Icons.draw_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: accessible ? 4 : 7),
              if (accessible)
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.2,
                  child: Semantics(
                    key: const ValueKey('study-accessible-header-meta'),
                    label:
                        'Study Observatory. ${controller.totalQuestions} questions. Fully offline.',
                    excludeSemantics: true,
                    child: Text(
                      'STUDY OBSERVATORY · ${_formatCount(controller.totalQuestions)} OFFLINE',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.35,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'STUDY OBSERVATORY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GaussColors.brassLight,
                          fontSize: GaussTypeScale.insignia,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCount(controller.totalQuestions)} questions · fully offline',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyOfflineSignal extends StatelessWidget {
  const _StudyOfflineSignal();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Private and fully offline',
    child: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GaussColors.signal.withValues(alpha: .1),
        border: Border.all(
          color: GaussColors.signalBright.withValues(alpha: .34),
        ),
      ),
      child: const Icon(
        Icons.offline_bolt_outlined,
        size: 20,
        color: GaussColors.signalBright,
      ),
    ),
  );
}

class _CourseInstrument extends StatelessWidget {
  const _CourseInstrument({required this.subject, required this.onChanged});

  final Subject subject;
  final ValueChanged<Subject> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 5, 18, 11),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _StudyGeometry.courseMaxWidth,
        ),
        child: _StudyGlass(
          key: const ValueKey('study-course-instrument'),
          radius: 22,
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final accessible =
                  textScale >= _StudyGeometry.accessibleLayoutScale;
              final stacked =
                  constraints.maxWidth <
                  _StudyGeometry.compactCourseBreakpoint - 50;
              final pairedVertical = (constraints.maxWidth - 12) / 2 < 145;
              final options = [
                for (final item in Subject.values)
                  _CourseOption(
                    semanticKey: ValueKey('study-subject-${item.key}'),
                    subject: item,
                    selected: subject == item,
                    compactAccessible: accessible,
                    chapterCount: GaussStudyCurriculum.forSubject(item).length,
                    onTap: () => onChanged(item),
                  ),
              ];
              final rawChoices = stacked
                  ? Column(
                      children: [
                        options.first,
                        const SizedBox(height: 8),
                        options.last,
                      ],
                    )
                  : SizedBox(
                      height: pairedVertical ? 96 : 70,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: options.first),
                          const SizedBox(width: 12),
                          Expanded(child: options.last),
                        ],
                      ),
                    );
              final choices = accessible
                  ? MediaQuery.withClampedTextScaling(
                      // Course names are selector chrome. Keep the complete
                      // labels while preserving a compact two-orbit chooser.
                      maxScaleFactor: 1.35,
                      child: rawChoices,
                    )
                  : rawChoices;
              return Stack(
                alignment: Alignment.center,
                children: [
                  choices,
                  IgnorePointer(
                    child: ExcludeSemantics(
                      child: Container(
                        key: const ValueKey('study-course-axis-label'),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GaussColors.deepInk,
                          border: Border.all(
                            color: GaussColors.brass.withValues(alpha: .62),
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 8,
                          color: GaussColors.brassLight,
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
    ),
  );
}

class _CourseOption extends StatelessWidget {
  const _CourseOption({
    required this.semanticKey,
    required this.subject,
    required this.selected,
    required this.compactAccessible,
    required this.chapterCount,
    required this.onTap,
  });

  final Key semanticKey;
  final Subject subject;
  final bool selected;
  final bool compactAccessible;
  final int chapterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GaussColors.ivory : GaussColors.fog;
    return Semantics(
      key: semanticKey,
      button: true,
      selected: selected,
      label: _subjectTitle(subject),
      hint: '$chapterCount chapters${selected ? ', selected course' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: GaussMotion.resolve(context, GaussMotion.standard),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: subject == Subject.math
                          ? const [Color(0xFF6F4A16), Color(0xFF2A2117)]
                          : const [Color(0xFF245E66), Color(0xFF132D35)],
                    )
                  : null,
              color: selected
                  ? null
                  : GaussColors.raised.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? (subject == Subject.math
                              ? GaussColors.brassLight
                              : GaussColors.signalBright)
                          .withValues(alpha: .58)
                    : GaussColors.hairline,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            (subject == Subject.math
                                    ? GaussColors.brass
                                    : GaussColors.signal)
                                .withValues(alpha: .12),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // At phone split widths, a side-by-side icon and the full
                // "Mathematics" label create unequal card heights. Reflow
                // both choices as centered instruments before either label
                // has to wrap, so the pair keeps one optical baseline.
                final vertical = constraints.maxWidth < 145;
                final compact = compactAccessible && vertical;
                final chromeTextScaler = compact
                    ? const TextScaler.linear(1.25)
                    : null;
                final icon = Container(
                  width: compact ? 30 : 36,
                  height: compact ? 30 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GaussColors.deepInk.withValues(
                      alpha: selected ? .5 : .78,
                    ),
                    border: Border.all(
                      color: foreground.withValues(alpha: .28),
                    ),
                  ),
                  child: Icon(
                    subject == Subject.math
                        ? Icons.functions_rounded
                        : Icons.electric_bolt_rounded,
                    size: compact ? 17 : 19,
                    color: foreground,
                  ),
                );
                final copy = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: vertical
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subjectTitle(subject),
                      maxLines: 1,
                      softWrap: false,
                      textScaler: chromeTextScaler,
                      textAlign: vertical ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$chapterCount chapters',
                      maxLines: 1,
                      softWrap: false,
                      textScaler: chromeTextScaler,
                      textAlign: vertical ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: foreground.withValues(alpha: .78),
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
                if (vertical) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      SizedBox(height: compact ? 4 : 6),
                      copy,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Flexible(child: copy),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueInstrument extends StatelessWidget {
  const _ContinueInstrument({
    required this.node,
    required this.snapshot,
    required this.subject,
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.previousSectionTitle,
    required this.nextSectionTitle,
    required this.onPreviousSection,
    required this.onNextSection,
    required this.onOpen,
  });

  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final Subject subject;
  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final String previousSectionTitle;
  final String nextSectionTitle;
  final VoidCallback onPreviousSection;
  final VoidCallback onNextSection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accessibleViewport =
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(1) >=
            _StudyGeometry.accessibleLayoutScale;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _StudyGeometry.contentMaxWidth,
          ),
          child: _StudyGlass(
            key: const ValueKey('study-today'),
            radius: 28,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentSectionAxis(
                  subject: subject,
                  section: section,
                  sectionIndex: sectionIndex,
                  sectionCount: sectionCount,
                  previousSectionTitle: previousSectionTitle,
                  nextSectionTitle: nextSectionTitle,
                  onPrevious: onPreviousSection,
                  onNext: onNextSection,
                ),
                Divider(
                  height: 1,
                  color: GaussColors.brass.withValues(alpha: .2),
                ),
                Padding(
                  padding: EdgeInsets.all(accessibleViewport ? 8 : 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final wide =
                          constraints.maxWidth >= 720 &&
                          textScale < _StudyGeometry.accessibleLayoutScale;
                      final compactHeroRow =
                          constraints.maxWidth >= 330 && textScale < 1.45;
                      final compactAccessible =
                          constraints.maxWidth < 330 &&
                          textScale >= _StudyGeometry.accessibleLayoutScale;
                      final progress = node.questionCount == 0
                          ? 0.0
                          : snapshot.reflected / node.questionCount;
                      final emblem = _OrbitEmblem(
                        dimension: wide
                            ? 126
                            : compactHeroRow
                            ? 72
                            : 84,
                        progress: progress,
                      );
                      final lessonCopy = _CurrentLessonCopy(
                        node: node,
                        centered: !wide && !compactHeroRow,
                      );
                      final lessonProgress = _LessonProgress(
                        reflected: snapshot.reflected,
                        total: node.questionCount,
                      );
                      final continueButton = _ContinueButton(
                        node: node,
                        onOpen: onOpen,
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            emblem,
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  lessonCopy,
                                  const SizedBox(height: 14),
                                  lessonProgress,
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(width: 120, child: continueButton),
                          ],
                        );
                      }

                      if (compactAccessible) {
                        return Column(
                          key: const ValueKey(
                            'study-accessible-current-mission',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            lessonCopy,
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: lessonProgress),
                                const SizedBox(width: 12),
                                continueButton,
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (compactHeroRow)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                emblem,
                                const SizedBox(width: 14),
                                Expanded(child: lessonCopy),
                                const SizedBox(width: 8),
                                continueButton,
                              ],
                            )
                          else ...[
                            Center(child: emblem),
                            const SizedBox(height: 12),
                            lessonCopy,
                          ],
                          const SizedBox(height: 10),
                          lessonProgress,
                          if (!compactHeroRow) ...[
                            const SizedBox(height: 12),
                            continueButton,
                          ],
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
    );
  }
}

class _CurrentSectionAxis extends StatelessWidget {
  const _CurrentSectionAxis({
    required this.subject,
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.previousSectionTitle,
    required this.nextSectionTitle,
    required this.onPrevious,
    required this.onNext,
  });

  final Subject subject;
  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final String previousSectionTitle;
  final String nextSectionTitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        '${_subjectTitle(subject)} course. Current chapter ${sectionIndex + 1} of $sectionCount, ${section.title}.',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final reflowNavigation =
              textScale >= _StudyGeometry.accessibleLayoutScale;
          final previous = SizedBox.square(
            dimension: _StudyGeometry.controlTrack,
            child: IconButton.outlined(
              key: const ValueKey('study-previous-section'),
              onPressed: onPrevious,
              tooltip: 'Previous chapter: $previousSectionTitle',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          );
          final next = SizedBox.square(
            dimension: _StudyGeometry.controlTrack,
            child: IconButton.outlined(
              key: const ValueKey('study-next-section'),
              onPressed: onNext,
              tooltip: 'Next chapter: $nextSectionTitle',
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          );
          final sectionTitle = ExcludeSemantics(
            key: const ValueKey('study-current-section-title'),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 1,
              children: [
                for (final word in section.title.split(' '))
                  Text(
                    word,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: GaussColors.ivory,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          );
          final sectionLabel = Column(
            key: const ValueKey('study-current-section-label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                runSpacing: 1,
                children: [
                  Text(
                    '${_subjectTitle(subject)} course',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'chapter ${sectionIndex + 1} of $sectionCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              sectionTitle,
            ],
          );
          final responsiveSectionLabel = reflowNavigation
              ? Column(
                  key: const ValueKey('study-current-section-label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.2,
                      child: Text(
                        '${_subjectTitle(subject).toUpperCase()} · CHAPTER ${sectionIndex + 1}/$sectionCount',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: GaussTypeScale.insignia,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.35,
                      child: sectionTitle,
                    ),
                  ],
                )
              : sectionLabel;

          if (reflowNavigation) {
            return Column(
              key: const ValueKey('study-current-section-axis'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                responsiveSectionLabel,
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    previous,
                    const SizedBox(width: 16),
                    Container(
                      width: _StudyGeometry.controlTrack,
                      height: _StudyGeometry.controlTrack,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GaussColors.raised.withValues(alpha: .5),
                        border: Border.all(color: GaussColors.hairline),
                      ),
                      child: const TheoremStarMark(size: 24),
                    ),
                    const SizedBox(width: 16),
                    next,
                  ],
                ),
              ],
            );
          }

          return Row(
            key: const ValueKey('study-current-section-axis'),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              previous,
              const SizedBox(width: 8),
              Expanded(child: responsiveSectionLabel),
              const SizedBox(width: 8),
              next,
            ],
          );
        },
      ),
    ),
  );
}

class _CurrentLessonCopy extends StatelessWidget {
  const _CurrentLessonCopy({required this.node, required this.centered});

  final StudyPathNode node;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final accessible =
        MediaQuery.textScalerOf(context).scale(1) >=
        _StudyGeometry.accessibleLayoutScale;
    final title = Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        node.topic.label,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    if (accessible) {
      return Semantics(
        key: const ValueKey('study-current-lesson-copy'),
        label:
            'Current study. ${node.topic.label}. Micro-lesson ${node.partIndex + 1} of ${node.partCount}.',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                'CURRENT STUDY · LESSON ${node.partIndex + 1}/${node.partCount}',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
            const SizedBox(height: 3),
            title,
          ],
        ),
      );
    }
    return Column(
      key: const ValueKey('study-current-lesson-copy'),
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CURRENT STUDY',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GaussColors.brassLight,
            fontSize: GaussTypeScale.insignia,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        title,
        const SizedBox(height: 3),
        Text(
          'MICRO-LESSON ${node.partIndex + 1} OF ${node.partCount}',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(color: GaussColors.fog, fontSize: 12),
        ),
      ],
    );
  }
}

class _LessonProgress extends StatelessWidget {
  const _LessonProgress({required this.reflected, required this.total});

  final int reflected;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$reflected of $total questions charted in this micro-lesson.',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final reflow =
              constraints.maxWidth < 130 ||
              textScale >= _StudyGeometry.accessibleLayoutScale;
          Widget segments() => Row(
            children: [
              for (var index = 0; index < total; index++) ...[
                if (index > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: GaussMotion.resolve(
                      context,
                      GaussMotion.standard,
                    ),
                    height: 6,
                    decoration: BoxDecoration(
                      color: index < reflected
                          ? GaussColors.signalBright
                          : GaussColors.line,
                      borderRadius: BorderRadius.circular(GaussRadii.pill),
                    ),
                  ),
                ),
              ],
            ],
          );
          final counter = MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.35,
            child: Text(
              '$reflected / $total',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GaussColors.signalBright,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
          if (reflow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [segments(), const SizedBox(height: 5), counter],
            );
          }
          return Row(
            children: [
              Expanded(child: segments()),
              const SizedBox(width: 10),
              counter,
            ],
          );
        },
      ),
    ),
  );
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.node, required this.onOpen});

  final StudyPathNode node;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.35,
    child: Center(
      child: OrbitalActionControl(
        key: const ValueKey('study-primary-continue'),
        semanticLabel: 'Continue ${node.topic.label}, ${_sessionLabel(node)}',
        caption: 'NEXT 5',
        onPressed: onOpen,
        icon: Icons.play_arrow_rounded,
        dimension: 58,
      ),
    ),
  );
}

class _OrbitEmblem extends StatelessWidget {
  const _OrbitEmblem({required this.progress, this.dimension = 126});
  final double progress;
  final double dimension;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: dimension - 10,
          child: CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: GaussColors.line,
            color: GaussColors.brass,
          ),
        ),
        Container(
          width: dimension * .7,
          height: dimension * .7,
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
          child: Center(child: TheoremStarMark(size: dimension * .44)),
        ),
      ],
    ),
  );
}

class _StudyModes extends StatelessWidget {
  const _StudyModes({
    required this.revisitCount,
    required this.dueCount,
    required this.gemCount,
    required this.onRevisit,
    required this.onGems,
    required this.onScratchpad,
    required this.onMap,
  });

  final int revisitCount;
  final int dueCount;
  final int gemCount;
  final VoidCallback onRevisit;
  final VoidCallback onGems;
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
            : dueCount == 0
            ? '$revisitCount shelved · none due yet'
            : '$dueCount due now · $revisitCount shelved',
        onTap: onRevisit,
      ),
      (
        icon: Icons.auto_awesome_outlined,
        title: 'Gem shelf',
        detail: gemCount == 0
            ? 'Keep a question you admire'
            : '$gemCount kept for their ideas',
        onTap: onGems,
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
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: _StudyGlass(
            key: const ValueKey('study-library-tools'),
            radius: 22,
            padding: const EdgeInsets.all(6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final window = GaussWindowClass.fromWidth(
                  math.max(
                    MediaQuery.sizeOf(context).width,
                    constraints.maxWidth,
                  ),
                );
                final accessibleText =
                    MediaQuery.textScalerOf(
                      context,
                    ).scale(GaussTypeScale.body) >=
                    20;
                if (window.isCompact ||
                    constraints.maxWidth < 480 ||
                    accessibleText) {
                  return Column(
                    children: [
                      for (var index = 0; index < modes.length; index++) ...[
                        if (index > 0)
                          Divider(
                            height: 1,
                            color: GaussColors.hairline.withValues(alpha: .7),
                          ),
                        _ModePlate(
                          key: ValueKey('study-mode-${modes[index].title}'),
                          icon: modes[index].icon,
                          title: modes[index].title,
                          detail: modes[index].detail,
                          onTap: modes[index].onTap,
                        ),
                      ],
                    ],
                  );
                }
                if (window.isMedium) {
                  final plateWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final mode in modes)
                        SizedBox(
                          width: plateWidth,
                          child: _ModePlate(
                            key: ValueKey('study-mode-${mode.title}'),
                            icon: mode.icon,
                            title: mode.title,
                            detail: mode.detail,
                            onTap: mode.onTap,
                          ),
                        ),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var index = 0; index < modes.length; index++) ...[
                      if (index > 0)
                        Container(
                          width: 1,
                          height: 44,
                          color: GaussColors.hairline.withValues(alpha: .7),
                        ),
                      Expanded(
                        child: _ModePlate(
                          key: ValueKey('study-mode-${modes[index].title}'),
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
      ),
    );
  }
}

class _ModePlate extends StatelessWidget {
  const _ModePlate({
    super.key,
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $detail',
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: GaussColors.brass.withValues(alpha: .11),
                    border: Border.all(
                      color: GaussColors.brass.withValues(alpha: .28),
                    ),
                  ),
                  child: Icon(icon, color: GaussColors.brassLight, size: 21),
                ),
                const SizedBox(width: 10),
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
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.countLabel,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String countLabel;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('study-library'),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 11),
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
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  countLabel,
                  style: const TextStyle(
                    color: GaussColors.signalBright,
                    fontSize: GaussTypeScale.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
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

class _SectionAtlas extends StatelessWidget {
  const _SectionAtlas({
    required this.sections,
    required this.controller,
    required this.onOpen,
  });

  final List<StudySectionDefinition> sections;
  final GaussController controller;
  final ValueChanged<StudyPathNode> onOpen;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final window = GaussWindowClass.fromWidth(
            math.max(MediaQuery.sizeOf(context).width, constraints.maxWidth),
          );
          final usePairs =
              window.isExpanded &&
              constraints.maxWidth >= 880 &&
              MediaQuery.textScalerOf(context).scale(GaussTypeScale.body) < 20;
          if (!usePairs) {
            return Column(
              children: [
                for (var index = 0; index < sections.length; index++) ...[
                  if (index > 0) const SizedBox(height: 14),
                  _SectionAtlasCard(
                    key: ValueKey('study-section-${sections[index].id}'),
                    number: index + 1,
                    section: sections[index],
                    controller: controller,
                    onOpen: onOpen,
                  ),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var index = 0; index < sections.length; index += 2) ...[
                if (index > 0) const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SectionAtlasCard(
                        key: ValueKey('study-section-${sections[index].id}'),
                        number: index + 1,
                        section: sections[index],
                        controller: controller,
                        onOpen: onOpen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: index + 1 < sections.length
                          ? _SectionAtlasCard(
                              key: ValueKey(
                                'study-section-${sections[index + 1].id}',
                              ),
                              number: index + 2,
                              section: sections[index + 1],
                              controller: controller,
                              onOpen: onOpen,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _SectionAtlasCard extends StatefulWidget {
  const _SectionAtlasCard({
    super.key,
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
  State<_SectionAtlasCard> createState() => _SectionAtlasCardState();
}

class _SectionAtlasCardState extends State<_SectionAtlasCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final controller = widget.controller;
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            key: ValueKey('study-section-toggle-${section.id}'),
            button: true,
            expanded: _expanded,
            label:
                '${section.title}. $reflected of $total session slots charted.',
            hint: _expanded ? 'Collapse chapter' : 'Open chapter',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final accessibleText =
                              MediaQuery.textScalerOf(
                                context,
                              ).scale(GaussTypeScale.body) >=
                              20;

                          Widget numberBadge() => Container(
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
                                  color: GaussColors.brass.withValues(
                                    alpha: .25,
                                  ),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Text(
                              '${widget.number}',
                              style: const TextStyle(
                                color: GaussColors.deepInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );

                          Widget titleBlock() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${topics.length} micro-lessons · ${nodes.length} sessions',
                                style: const TextStyle(
                                  color: GaussColors.fog,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );

                          Widget chevron() => AnimatedRotation(
                            turns: _expanded ? .5 : 0,
                            duration: GaussMotion.resolve(
                              context,
                              GaussMotion.micro,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: GaussColors.brassLight,
                            ),
                          );

                          final progress = Text(
                            '$reflected/$total',
                            style: const TextStyle(
                              color: GaussColors.signalBright,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          );
                          if (accessibleText || constraints.maxWidth < 360) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    numberBadge(),
                                    const SizedBox(width: 12),
                                    Expanded(child: titleBlock()),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    progress,
                                    const Spacer(),
                                    chevron(),
                                  ],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              numberBadge(),
                              const SizedBox(width: 12),
                              Expanded(child: titleBlock()),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [progress, chevron()],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        section.subtitle,
                        style: const TextStyle(
                          color: GaussColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: total == 0 ? 0 : reflected / total,
                          backgroundColor: GaussColors.line,
                          color: GaussColors.signal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ListView.separated(
                shrinkWrap: true,
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
                  final topicSlots = topicNodes.fold<int>(
                    0,
                    (sum, node) => sum + node.questionCount,
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
                    sessionCount: topicNodes.length,
                    reflected: topicReflected,
                    totalSlots: topicSlots,
                    onOpen: () => widget.onOpen(nextNode),
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
    required this.sessionCount,
    required this.reflected,
    required this.totalSlots,
    required this.onOpen,
  });

  final int index;
  final TopicDescriptor topic;
  final int sessionCount;
  final int reflected;
  final int totalSlots;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: GaussColors.raised.withValues(alpha: .62),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: GaussMetrics.minTouchTarget,
        ),
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
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sessionCount sessions · $reflected/$totalSlots slots charted',
                      style: const TextStyle(
                        color: GaussColors.muted,
                        fontSize: GaussTypeScale.insignia,
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
    ),
  );
}

class _StudyGlass extends StatelessWidget {
  const _StudyGlass({
    super.key,
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
