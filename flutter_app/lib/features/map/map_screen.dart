import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/ui/components/gauss_brand.dart';
import 'package:gauss/ui/components/gauss_surface.dart';
import 'package:gauss/ui/components/gauss_state_panel.dart';
import 'package:gauss/features/map/map_gamification_hud.dart';
import 'package:gauss/features/map/map_path_geometry.dart';
import 'package:gauss/ui/components/orbital_action_control.dart';

part 'map_header.dart';
part 'map_orbit_navigator.dart';
part 'map_path_stage.dart';
part 'map_path_node.dart';
part 'map_mission_dock.dart';
part 'map_inspector.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<_StudyPathStageState> _pathKey = GlobalKey();
  Subject _subject = Subject.math;
  String? _sectionId;
  String? _selectedNodeKey;
  final Map<Subject, String> _lastSectionBySubject = {};
  final Map<Subject, String> _lastNodeBySubject = {};
  bool? _tourWasVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = GaussScope.of(context);
    for (final subject in Subject.values) {
      _lastSectionBySubject.putIfAbsent(
        subject,
        () => GaussStudyCurriculum.forSubject(subject).first.id,
      );
    }
    // The controller owns the durable learning context shared with Study.
    // Seed Map's local navigation lens from it exactly once; otherwise every
    // cold launch visually falls back to Math chapter 1 while the stored
    // topic still points somewhere else. Later Map navigation remains local
    // and continues to persist through controller.selectTopic.
    if (_sectionId == null) {
      final restoredTopic = controller.selectedTopic;
      final restoredSections = GaussStudyCurriculum.forSubject(
        restoredTopic.subject,
      );
      final restoredSection = restoredSections.firstWhere(
        (section) => section.topicKeys.contains(restoredTopic.key),
        orElse: () => restoredSections.first,
      );
      _subject = restoredTopic.subject;
      _sectionId = restoredSection.id;
      _lastSectionBySubject[restoredTopic.subject] = restoredSection.id;
      _selectedNodeKey = GaussStudyCurriculum.nodesFor(
        restoredSection,
        controller.topics,
      ).firstWhere((node) => node.topic.key == restoredTopic.key).key;
      _lastNodeBySubject[restoredTopic.subject] = _selectedNodeKey!;
    }
  }

  void _selectSubject(GaussController controller, Subject subject) {
    if (_subject == subject) return;
    final sections = GaussStudyCurriculum.forSubject(subject);
    final section = sections.firstWhere(
      (item) => item.id == _lastSectionBySubject[subject],
      orElse: () => sections.first,
    );
    _navigateToOrbit(controller, subject, section);
  }

  void _navigateToOrbit(
    GaussController controller,
    Subject subject,
    StudySectionDefinition section,
  ) {
    final sections = GaussStudyCurriculum.forSubject(subject);
    final targetSection = sections.firstWhere(
      (item) => item.id == section.id,
      orElse: () => sections.first,
    );
    final nodes = GaussStudyCurriculum.nodesFor(
      targetSection,
      controller.topics,
    );
    final restoresKnownOrbit =
        _lastSectionBySubject[subject] == targetSection.id;
    final preferredNodeKey = restoresKnownOrbit
        ? _lastNodeBySubject[subject]
        : null;
    var nodeIndex = preferredNodeKey == null
        ? -1
        : nodes.indexWhere((node) => node.key == preferredNodeKey);
    if (nodeIndex < 0) {
      nodeIndex = nodes.indexWhere(
        (node) =>
            controller.study.shelf(node.key).reflected < node.questionCount,
      );
    }
    if (nodeIndex < 0) nodeIndex = nodes.length - 1;
    final targetNode = nodes[nodeIndex];
    final routeChanged = _subject != subject || _sectionId != targetSection.id;
    setState(() {
      _subject = subject;
      _sectionId = targetSection.id;
      _selectedNodeKey = targetNode.key;
      _lastSectionBySubject[subject] = targetSection.id;
      _lastNodeBySubject[subject] = targetNode.key;
    });
    controller.selectTopic(targetNode.topic.key);
    if (routeChanged) _jumpPathToNode(nodeIndex);
  }

  void _jumpPathToNode(int nodeIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pathKey.currentState?.jumpToNode(nodeIndex);
    });
  }

  void _selectNode(GaussController controller, StudyPathNode node) {
    setState(() {
      _selectedNodeKey = node.key;
      _lastSectionBySubject[_subject] = _sectionId!;
      _lastNodeBySubject[_subject] = node.key;
    });
    controller.selectTopic(node.topic.key);
  }

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    if (controller.fatalError != null) return const _FatalDatasetView();
    if (_tourWasVisible == true && !controller.needsTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pathKey.currentState?.resetToStart();
      });
    }
    _tourWasVisible = controller.needsTour;
    final sections = GaussStudyCurriculum.forSubject(_subject);
    final section = sections.firstWhere(
      (item) => item.id == _sectionId,
      orElse: () => sections.first,
    );
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    final currentIndex = nodes.indexWhere(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
    );
    final effectiveCurrent = currentIndex < 0 ? nodes.length - 1 : currentIndex;
    final selected = nodes.firstWhere(
      (node) => node.key == _selectedNodeKey,
      orElse: () => nodes[effectiveCurrent],
    );
    final mediaWidth = MediaQuery.sizeOf(context).width;

    return ColoredBox(
      color: GaussColors.abyss,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _AstronomicalBackdrop()),
          LayoutBuilder(
            builder: (context, constraints) {
              final viewport = GaussViewport.fromSize(
                Size(
                  math.max(mediaWidth, constraints.maxWidth),
                  constraints.maxHeight,
                ),
              );
              final window = viewport.widthClass;
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final showInspector =
                  viewport.showsPersistentInspector && textScale < 1.6;
              final dockWidth = math.min(
                math.max(0.0, constraints.maxWidth - GaussSpacing.space24),
                window.isCompact ? 340.0 : 420.0,
              );
              final dockInset = math.max(
                GaussSpacing.space12,
                (constraints.maxWidth - dockWidth) / 2,
              );
              // The compact shell already places its footer above Android's
              // system navigation inset. The map only clears the footer's
              // visual height plus the optical gap; the shell owns Android's
              // safe inset outside the content-hugging footer.
              final dockBottom = window.isCompact
                  ? GaussMetrics.compactMapDockBottom(context)
                  : GaussMetrics.mapDockBottom(window);
              // The floating instrument no longer owns an opaque full-width
              // panel. Reserve only its measured controls and reading tier so
              // the route retains useful vertical presence behind it.
              // Reserve a small optical safety ring beyond the live compass;
              // a node may remain visible behind the transparent rail, but
              // no part of its 48dp hit target may enter the control field.
              const dockReservedHeight = 94.0;
              final bottomObstruction = showInspector
                  ? GaussMetrics.mapBottomObstruction(window)
                  : dockBottom +
                        dockReservedHeight +
                        GaussMetrics.mapOverlayGap;
              return Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            SafeArea(
                              bottom: false,
                              child: _MapHeader(
                                controller: controller,
                                subject: _subject,
                                sections: sections,
                                section: section,
                                activeTopic: selected.topic,
                                activeTopicReflected: controller.study
                                    .topic(selected.topic.key)
                                    .reflected,
                                lastSectionBySubject: _lastSectionBySubject,
                                onSubject: (subject) =>
                                    _selectSubject(controller, subject),
                                onNavigate: (subject, value) =>
                                    _navigateToOrbit(
                                      controller,
                                      subject,
                                      value,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: _StudyPathStage(
                                key: _pathKey,
                                controller: controller,
                                section: section,
                                nodes: nodes,
                                currentIndex: effectiveCurrent,
                                selectedKey: selected.key,
                                // The path canvas remains physically full
                                // height behind the floating glass. Scroll and
                                // jump math still reserve the live-control
                                // region, removing the opaque-looking dead band
                                // without making any node untappable.
                                bottomObstruction: showInspector
                                    ? 0
                                    : bottomObstruction,
                                onSelected: (node) =>
                                    _selectNode(controller, node),
                              ),
                            ),
                          ],
                        ),
                        PositionedDirectional(
                          end: 14,
                          bottom: showInspector ? 18 : bottomObstruction,
                          child: _JumpToCurrentButton(
                            onPressed: () => _pathKey.currentState?.jumpToNode(
                              effectiveCurrent,
                            ),
                          ),
                        ),
                        if (!showInspector)
                          PositionedDirectional(
                            start: dockInset,
                            bottom: dockBottom,
                            child: SizedBox(
                              width: dockWidth,
                              child: _StudyDock(
                                node: selected,
                                studyLabel: controller.studySetLabel(selected),
                                snapshot: controller.study.shelf(selected.key),
                                missionReady: controller
                                    .isStudySessionMissionReady(selected),
                                isCurrent:
                                    selected.key == nodes[effectiveCurrent].key,
                                onOpen: () => _openNode(context, selected),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showInspector)
                    SizedBox(
                      key: const ValueKey('map-study-inspector'),
                      width: window.isWide
                          ? GaussMetrics.mapWideInspectorWidth
                          : GaussMetrics.mapInspectorWidth,
                      child: _StudyInspector(
                        section: section,
                        node: selected,
                        upcoming: [
                          for (final next
                              in nodes
                                  .skip(
                                    nodes.indexWhere(
                                          (n) => n.key == selected.key,
                                        ) +
                                        1,
                                  )
                                  .take(3))
                            (
                              title: controller.studySetLabel(next),
                              charted: controller.study
                                  .shelf(next.key)
                                  .reflected,
                              total: next.questionCount,
                            ),
                        ],
                        snapshot: controller.study.shelf(selected.key),
                        topicSnapshot: controller.study.topic(
                          selected.topic.key,
                        ),
                        missionReady: controller.isStudySessionMissionReady(
                          selected,
                        ),
                        onOpen: () => _openNode(context, selected),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _openNode(BuildContext context, StudyPathNode node) async {
  await context.push('/mission/${node.topic.key}?offset=${node.offset}');
}

class _AstronomicalBackdrop extends StatelessWidget {
  const _AstronomicalBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image(
        image: GaussImages.atmosphere,
        opacity: const AlwaysStoppedAnimation(.42),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.low,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GaussScrims.abyssTop,
              Color(0xD6071115),
              GaussScrims.abyssBottom,
            ],
            stops: [0, .48, 1],
          ),
        ),
      ),
    ],
  );
}

int _boundedRasterWidth(
  BuildContext context,
  double logicalWidth, {
  required int sourceWidth,
  required int minimum,
}) => (logicalWidth * MediaQuery.devicePixelRatioOf(context))
    .ceil()
    .clamp(minimum, sourceWidth)
    .toInt();

bool _usesRtlScript(String value) => value.runes.any(
  (rune) =>
      (rune >= 0x0600 && rune <= 0x06ff) ||
      (rune >= 0x0750 && rune <= 0x077f) ||
      (rune >= 0x08a0 && rune <= 0x08ff),
);

class _FatalDatasetView extends StatelessWidget {
  const _FatalDatasetView();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const _AstronomicalBackdrop(),
      const GaussStatePanel(
        title: 'The observatory could not verify its library',
        detail:
            'No questions or field notes were reset. Reopen Gauss to try the local integrity check again.',
        icon: Icons.folder_off_outlined,
        accent: GaussColors.error,
      ),
    ],
  );
}
