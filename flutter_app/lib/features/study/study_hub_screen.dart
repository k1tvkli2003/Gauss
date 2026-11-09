import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/ui/components/gauss_brand.dart';
import 'package:gauss/ui/components/gauss_surface.dart';
import 'package:gauss/ui/components/orbital_action_control.dart';
import 'package:gauss/features/manuscript/scratchpad.dart';

part 'study_hub_course.dart';
part 'study_hub_continue.dart';
part 'study_hub_modes.dart';
part 'study_hub_atlas.dart';

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

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
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
                    eyebrow: '${_subjectTitle(subject)} atlas',
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
      Image(
        image: GaussImages.atmosphere,
        opacity: const AlwaysStoppedAnimation(.42),
        fit: BoxFit.cover,
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
                        child: IconButton(
                          key: const ValueKey('study-header-scratchpad'),
                          color: GaussColors.ivory,
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
                      'Study observatory · ${_formatCount(controller.totalQuestions)} offline',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: GaussTypeScale.caption,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .2,
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
                        'Study observatory',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GaussColors.brassLight,
                          fontSize: GaussTypeScale.caption,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
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

  // A status mark, not a control: no ring or fill, so it never reads as a
  // button beside the real scratchpad action.
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Private and fully offline',
    child: const SizedBox.square(
      dimension: 42,
      child: Icon(
        Icons.offline_pin_outlined,
        size: 22,
        color: GaussColors.signalBright,
      ),
    ),
  );
}
