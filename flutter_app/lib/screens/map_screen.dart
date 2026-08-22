import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/gauss_state_panel.dart';
import '../widgets/map_gamification_hud.dart';
import '../widgets/map_path_geometry.dart';
import '../widgets/orbital_action_control.dart';

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
      Image.asset(
        'assets/visual/map/orrery_atmosphere_portrait.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: _boundedRasterWidth(
          context,
          MediaQuery.sizeOf(context).width,
          sourceWidth: 941,
          minimum: 480,
        ),
        filterQuality: FilterQuality.low,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xA407151C), Color(0xD6071115), Color(0xF703090B)],
            stops: [0, .48, 1],
          ),
        ),
      ),
      const CustomPaint(painter: _StarFieldPainter()),
    ],
  );
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.controller,
    required this.subject,
    required this.sections,
    required this.section,
    required this.activeTopic,
    required this.activeTopicReflected,
    required this.lastSectionBySubject,
    required this.onSubject,
    required this.onNavigate,
  });

  final GaussController controller;
  final Subject subject;
  final List<StudySectionDefinition> sections;
  final StudySectionDefinition section;
  final TopicDescriptor activeTopic;
  final int activeTopicReflected;
  final Map<Subject, String> lastSectionBySubject;
  final ValueChanged<Subject> onSubject;
  final void Function(Subject, StudySectionDefinition) onNavigate;

  @override
  Widget build(BuildContext context) => Padding(
    // The accepted map direction treats the sky as the primary surface. The
    // top controls therefore float directly over it; only the actionable
    // orbit selector keeps a glass enclosure. This also returns horizontal
    // room to compact English metrics without weakening their touch targets.
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final tightPhone = constraints.maxWidth < 360;
        // Identical two-orbit flank instruments keep both the mathematical
        // axis and the perceived visual weight balanced. The centered brand
        // and course crest own independent rows, so neither flank can push
        // them away from the true screen axis.
        final flankTrack = compact ? 100.0 : 178.0;
        final sectionTotal = section.topicKeys.fold<int>(
          0,
          (sum, key) =>
              sum +
              controller.topics
                  .firstWhere((topic) => topic.key == key)
                  .questionCount,
        );
        final sectionReflected = section.topicKeys.fold<int>(
          0,
          (sum, key) => sum + controller.study.topic(key).reflected,
        );
        final subjectTopics = controller.topics.where(
          (topic) => topic.subject == subject,
        );
        final subjectTotal = subjectTopics.fold<int>(
          0,
          (sum, topic) => sum + topic.questionCount,
        );
        final subjectReflected = controller.topics
            .where((topic) => topic.subject == subject)
            .fold<int>(
              0,
              (sum, topic) => sum + controller.study.topic(topic.key).reflected,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: ValueKey(
                compact ? 'map-compact-header-frame' : 'map-wide-header-frame',
              ),
              // Keep the identity instruments in a deliberate masthead, but
              // do not let app chrome consume the first third of the route.
              // Compact Course copy is already encoded by the crest semantics
              // and the live reading, so its ornamental caption can yield the
              // vertical space to the actual learning path.
              height: compact ? 84 : 116,
              child: Column(
                children: [
                  SizedBox(
                    // Preserve the wordmark's 3:1 intrinsic ratio. The former
                    // 24dp slot forced an 88dp mark into a 24dp box, so its
                    // transparent top/bottom breathing room made the actual
                    // letters look absent on Android despite valid semantics.
                    height: compact ? 24 : 36,
                    child: Center(
                      child: GaussWordmark(
                        key: ValueKey(
                          compact
                              ? 'map-compact-centered-wordmark'
                              : 'map-wide-centered-wordmark',
                        ),
                        width: compact ? 70 : 104,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 0 : 4),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            key: ValueKey(
                              compact
                                  ? 'map-compact-identity-track'
                                  : 'map-wide-identity-track',
                            ),
                            width: flankTrack,
                            child: Align(
                              alignment: Alignment.center,
                              child: _CompactDailyProgress(
                                summary: controller.gamification,
                                compact: compact,
                                onDailyProgress: () =>
                                    _openDailyProgress(context),
                              ),
                            ),
                          ),
                        ),
                        _MapCourseProgressCrest(
                          key: const ValueKey('map-course-progress-crest'),
                          reflected: subjectReflected,
                          total: subjectTotal,
                          tight: compact || tightPhone,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: SizedBox(
                            key: ValueKey(
                              compact
                                  ? 'map-compact-subject-track'
                                  : 'map-wide-subject-track',
                            ),
                            width: flankTrack,
                            child: Align(
                              alignment: Alignment.center,
                              child: _SubjectSwitch(
                                subject: subject,
                                onSubject: onSubject,
                                compact: compact,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            _OrbitSelector(
              section: section,
              sectionIndex: sections.indexOf(section) + 1,
              sectionCount: sections.length,
              reflected: sectionReflected,
              total: sectionTotal,
              activeTopic: activeTopic,
              chapterIndex: section.topicKeys.indexOf(activeTopic.key) + 1,
              chapterReflected: activeTopicReflected,
              compact: compact,
              onPressed: () => _openOrbitNavigator(context),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _openOrbitNavigator(BuildContext context) async {
    Widget navigatorFor(BuildContext overlayContext) => _OrbitNavigator(
      controller: controller,
      initialSubject: subject,
      initialSection: section,
      lastSectionBySubject: Map.unmodifiable(lastSectionBySubject),
      onContinue: (nextSubject, nextSection) {
        Navigator.of(overlayContext).pop();
        onNavigate(nextSubject, nextSection);
      },
    );
    if (MediaQuery.sizeOf(context).width < GaussBreakpoints.medium) {
      await showModalBottomSheet<void>(
        context: context,
        // The Map lives inside the shell's nested navigator. Presenting this
        // course-picker on the root route keeps it above the shell footer
        // instead of allowing the footer to visually cut through its chapter
        // rail on compact Android screens.
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final textScale = MediaQuery.textScalerOf(sheetContext).scale(1);
          return ConstrainedBox(
            // The constellation navigator is a focused context switch, not a
            // second full-screen route. Large text keeps a taller scrollable
            // surface while normal phone layouts leave the Map visibly
            // present behind the sheet.
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(sheetContext).height *
                  (textScale >= 1.55 ? .94 : .76),
            ),
            child: navigatorFor(sheetContext),
          );
        },
      );
      return;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Orbit Navigator',
      barrierColor: GaussColors.abyss.withValues(alpha: .68),
      transitionDuration: GaussMotion.resolve(
        context,
        const Duration(milliseconds: 260),
      ),
      pageBuilder: (dialogContext, _, _) => SafeArea(
        minimum: const EdgeInsets.all(GaussSpacing.space16),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
            child: navigatorFor(dialogContext),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(.08, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openDailyProgress(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        // The sheet follows its content on tall phones instead of reserving a
        // fixed fraction of the display. A bounded ceiling keeps the same
        // composition scroll-safe at 200% text, after rotation, and when an
        // already-open sheet expands into a tablet window class.
        final maxSheetHeight = math.min(
          media.size.height *
              (media.size.width < GaussBreakpoints.medium ? .9 : .82),
          760.0,
        );
        final bottomClearance = math.max(
          GaussSpacing.space24,
          media.viewPadding.bottom + GaussSpacing.space16,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: DecoratedBox(
            key: const ValueKey('map-daily-orbit-sheet'),
            decoration: BoxDecoration(
              color: GaussColors.deepInk,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GaussRadii.large),
              ),
              border: Border(
                top: BorderSide(
                  color: GaussColors.brassLight.withValues(alpha: .42),
                ),
              ),
            ),
            child: SingleChildScrollView(
              key: const ValueKey('map-daily-orbit-scroll'),
              padding: EdgeInsetsDirectional.fromSTEB(
                GaussSpacing.space16,
                10,
                GaussSpacing.space16,
                bottomClearance,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GaussColors.fog.withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(
                              GaussRadii.pill,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DAILY ORBIT',
                                  style: TextStyle(
                                    color: GaussColors.brassLight,
                                    fontSize: GaussTypeScale.insignia,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your private learning rhythm',
                                  style: TextStyle(
                                    color: GaussColors.ivory,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('map-daily-orbit-close'),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            tooltip: 'Close daily progress',
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      MapGamificationHud(
                        summary: controller.gamification,
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.go('/insights');
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A missed day can use one calm grace day. Earned XP, completed lessons, and seals always remain on this device.',
                        style: TextStyle(
                          color: GaussColors.muted,
                          fontSize: GaussTypeScale.caption,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactDailyProgress extends StatelessWidget {
  const _CompactDailyProgress({
    required this.summary,
    required this.compact,
    required this.onDailyProgress,
  });

  final GamificationSummary summary;
  final bool compact;
  final VoidCallback onDailyProgress;

  @override
  Widget build(BuildContext context) {
    final accent = summary.streakGraceUsed
        ? GaussColors.ice
        : GaussColors.brassLight;
    return SizedBox(
      key: const ValueKey('map-daily-progress-button'),
      width: compact ? 100 : 178,
      height: 56,
      child: Semantics(
        button: true,
        label:
            'Open daily progress. ${summary.streak} day streak. '
            '${summary.todayXp} experience today.',
        child: Tooltip(
          message: 'Daily streak and rewards',
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onDailyProgress,
                customBorder: const StadiumBorder(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: compact ? 25 : 42,
                      right: compact ? 25 : 42,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: .22),
                              GaussColors.brassLight.withValues(alpha: .72),
                              GaussColors.signalBright.withValues(alpha: .22),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GaussColors.ivory,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: GaussColors.brassLight.withValues(
                              alpha: .58,
                            ),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _DailyOrbitMetric(
                            key: const ValueKey('map-daily-streak-orbit'),
                            value: '${summary.streak}',
                            label: summary.streakGraceUsed ? 'GRACE' : 'STREAK',
                            icon: summary.streakGraceUsed
                                ? Icons.shield_moon_outlined
                                : Icons.local_fire_department_rounded,
                            accent: accent,
                            compact: compact,
                          ),
                        ),
                        SizedBox(width: compact ? 4 : 8),
                        Expanded(
                          child: _DailyOrbitMetric(
                            key: const ValueKey('map-daily-xp-orbit'),
                            value: '${summary.todayXp}',
                            label: 'TODAY XP',
                            icon: Icons.bolt_rounded,
                            accent: GaussColors.signalBright,
                            compact: compact,
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
      ),
    );
  }
}

class _DailyOrbitMetric extends StatelessWidget {
  const _DailyOrbitMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.compact,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: GaussMotion.resolve(context, GaussMotion.micro),
    curve: Curves.easeOutCubic,
    constraints: const BoxConstraints(
      minWidth: GaussMetrics.minTouchTarget,
      minHeight: GaussMetrics.minTouchTarget,
    ),
    height: 52,
    padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 7),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .56),
      borderRadius: BorderRadius.circular(compact ? 26 : 18),
      border: Border.all(color: accent.withValues(alpha: .74)),
      boxShadow: [
        BoxShadow(color: accent.withValues(alpha: .1), blurRadius: 10),
      ],
    ),
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: compact
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 3),
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 3),
                    Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: GaussColors.ivory,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: accent,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .45,
                    height: 1,
                  ),
                ),
              ],
            ),
    ),
  );
}

class _MapCourseProgressCrest extends StatelessWidget {
  const _MapCourseProgressCrest({
    required this.reflected,
    required this.total,
    required this.tight,
    super.key,
  });

  final int reflected;
  final int total;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (reflected / total).clamp(0.0, 1.0);
    final accessible = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final compactCrest = tight || accessible;
    // At 200% Android text the live course reading still needs 16dp after
    // clamping. Give it real room instead of letting the central crest spill
    // out of the masthead by a couple of pixels.
    final ringSize = accessible
        ? 42.0
        : compactCrest
        ? 44.0
        : 48.0;
    return Semantics(
      container: true,
      label: '$reflected of $total course questions charted.',
      child: ExcludeSemantics(
        child: SizedBox(
          width: compactCrest ? 72 : 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: ringSize,
                child: CustomPaint(
                  painter: _MapCourseProgressPainter(progress: progress),
                  child: Center(
                    child: TheoremStarMark(
                      size: compactCrest ? 27 : 29,
                      semanticLabel: null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: accessible ? 0 : 2),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.35,
                child: Text(
                  '$reflected / $total',
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: GaussTypeScale.caption,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .15,
                  ),
                ),
              ),
              if (!compactCrest) ...[
                const SizedBox(height: 1),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.35,
                  child: const Text(
                    'COURSE',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: GaussColors.fog,
                      fontSize: 7.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

class _MapCourseProgressPainter extends CustomPainter {
  const _MapCourseProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final orbit = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = GaussColors.brass.withValues(alpha: .32),
    );
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = GaussColors.signal.withValues(alpha: .18),
    );
    if (progress > 0) {
      canvas.drawArc(
        orbit,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = GaussColors.signalBright,
      );
    }
    for (var tick = 0; tick < 8; tick++) {
      final angle = -math.pi / 2 + tick * math.pi / 4;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        tick.isEven ? 1.45 : 1,
        Paint()
          ..color = (tick == 0 ? GaussColors.brassLight : GaussColors.brass)
              .withValues(alpha: tick == 0 ? .9 : .52),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapCourseProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _OrbitSelector extends StatelessWidget {
  const _OrbitSelector({
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.reflected,
    required this.total,
    required this.activeTopic,
    required this.chapterIndex,
    required this.chapterReflected,
    required this.compact,
    required this.onPressed,
  });

  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final int reflected;
  final int total;
  final TopicDescriptor activeTopic;
  final int chapterIndex;
  final int chapterReflected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reflowCompact =
        compact && (media.size.width < 360 || media.textScaler.scale(1) > 1.35);
    final orbitTitleStyle = TextStyle(
      color: GaussColors.ivory,
      fontSize: compact ? 13 : 14,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );
    final orbitTitle = reflowCompact
        ? ExcludeSemantics(
            child: Wrap(
              key: const ValueKey('map-active-orbit-title'),
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 6,
              children: [
                for (final word in section.title.split(' '))
                  Text(
                    word,
                    maxLines: 1,
                    softWrap: false,
                    style: orbitTitleStyle,
                  ),
              ],
            ),
          )
        : Text(
            key: const ValueKey('map-active-orbit-title'),
            section.title,
            softWrap: true,
            style: orbitTitleStyle,
          );
    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT ORBIT · $sectionIndex OF $sectionCount',
          style: const TextStyle(
            color: GaussColors.brassLight,
            fontSize: GaussTypeScale.insignia,
            fontWeight: FontWeight.w900,
            letterSpacing: .85,
          ),
        ),
        const SizedBox(height: 2),
        orbitTitle,
      ],
    );
    final reading = Text(
      '$reflected / $total',
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        color: GaussColors.signalBright,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
    final centeredChapter = Container(
      key: const ValueKey('map-active-chapter-summary'),
      width: double.infinity,
      alignment: Alignment.center,
      // Course, chapter, and reading used to become two nested vertical
      // stacks. A single adaptive constellation line keeps the same complete
      // identity while returning the route to the first viewport. Wrap is
      // intentional: 320dp/200% gets a calm second line, never clipped copy.
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          Text(
            'CHAPTER $chapterIndex',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: GaussColors.brassLight,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: GaussColors.brass,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            activeTopic.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GaussColors.ivory,
              fontSize: compact ? 10.5 : 12,
              height: 1.16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$chapterReflected / ${activeTopic.questionCount}',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: GaussColors.signalBright,
              fontSize: 9.5,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
    final centeredCompactIdentity = Column(
      key: const ValueKey('map-orbit-center-axis'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ORBIT $sectionIndex  ·  $reflected / $total',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            color: GaussColors.brassLight,
            fontSize: GaussTypeScale.insignia,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: .75,
          ),
        ),
        const SizedBox(height: 2),
        orbitTitle,
        const SizedBox(height: 3),
        centeredChapter,
      ],
    );
    return Semantics(
      button: true,
      label:
          'Current orbit $sectionIndex of $sectionCount. ${section.title}. '
          'Chapter $chapterIndex, ${activeTopic.label}. '
          '$chapterReflected of ${activeTopic.questionCount} chapter questions charted. '
          '$reflected of $total orbit questions charted.',
      hint: 'Double tap to choose another orbit.',
      child: InkWell(
        key: const ValueKey('map-orbit-selector'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: GaussMetrics.minTouchTarget,
          ),
          padding: EdgeInsets.fromLTRB(
            8,
            reflowCompact ? 6 : 6,
            8,
            reflowCompact ? 6 : 6,
          ),
          decoration: BoxDecoration(
            color: GaussColors.deepInk.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .34)),
          ),
          child: compact
              ? MediaQuery.withClampedTextScaling(
                  // This is a map instrument, not reading content. Keep the
                  // complete phrases live and unbroken while capping their
                  // scale so the selected chapter cannot consume the route.
                  maxScaleFactor: reflowCompact ? 1.45 : 1.55,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Center(
                          child: _OrbitIndexRing(value: sectionIndex),
                        ),
                      ),
                      Expanded(child: centeredCompactIdentity),
                      const SizedBox(
                        width: 48,
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: GaussColors.fog,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    _OrbitIndexRing(value: sectionIndex),
                    const SizedBox(width: 10),
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        reading,
                        const SizedBox(height: 1),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: GaussColors.fog,
                          size: 15,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OrbitIndexRing extends StatelessWidget {
  const _OrbitIndexRing({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GaussColors.abyss.withValues(alpha: .8),
      border: Border.all(
        color: GaussColors.signalBright.withValues(alpha: .72),
        width: 1.6,
      ),
      boxShadow: [
        BoxShadow(
          color: GaussColors.signalBright.withValues(alpha: .16),
          blurRadius: 12,
        ),
      ],
    ),
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: Text(
        '$value',
        style: const TextStyle(
          color: GaussColors.ivory,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _OrbitNavigator extends StatefulWidget {
  const _OrbitNavigator({
    required this.controller,
    required this.initialSubject,
    required this.initialSection,
    required this.lastSectionBySubject,
    required this.onContinue,
  });

  final GaussController controller;
  final Subject initialSubject;
  final StudySectionDefinition initialSection;
  final Map<Subject, String> lastSectionBySubject;
  final void Function(Subject, StudySectionDefinition) onContinue;

  @override
  State<_OrbitNavigator> createState() => _OrbitNavigatorState();
}

class _OrbitNavigatorState extends State<_OrbitNavigator> {
  late Subject _subject;
  late String _sectionId;

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
    _sectionId = widget.initialSection.id;
  }

  List<StudySectionDefinition> get _sections =>
      GaussStudyCurriculum.forSubject(_subject);

  StudySectionDefinition get _section => _sections.firstWhere(
    (item) => item.id == _sectionId,
    orElse: () => _sections.first,
  );

  void _selectSubject(Subject subject) {
    if (_subject == subject) return;
    final sections = GaussStudyCurriculum.forSubject(subject);
    final restored = sections.firstWhere(
      (item) => item.id == widget.lastSectionBySubject[subject],
      orElse: () => sections.first,
    );
    setState(() {
      _subject = subject;
      _sectionId = restored.id;
    });
  }

  void _selectSection(StudySectionDefinition section) {
    if (_sectionId == section.id) return;
    setState(() => _sectionId = section.id);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final selectedIndex = sections.indexWhere((item) => item.id == _section.id);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.55;
    final courseName = _subject == Subject.math
        ? (largeText ? 'MATH' : 'MATHEMATICS')
        : 'PHYSICS';
    return KeyedSubtree(
      key: const ValueKey('orbit-navigator'),
      child: _GlassFrame(
        radius: 30,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GaussColors.fog.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(GaussRadii.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: GaussSpacing.space8),
                    Row(
                      key: const ValueKey('orbit-navigator-header'),
                      children: [
                        const TheoremStarMark(size: 34),
                        const SizedBox(width: GaussSpacing.space8),
                        Expanded(
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ORBIT NAVIGATOR',
                                  softWrap: false,
                                  style: TextStyle(
                                    color: GaussColors.brassLight,
                                    fontSize: GaussTypeScale.insignia,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  key: const ValueKey(
                                    'orbit-navigator-course-summary',
                                  ),
                                  '$courseName  ·  ${sections.length} CHAPTERS',
                                  softWrap: false,
                                  style: const TextStyle(
                                    color: GaussColors.fog,
                                    fontSize: GaussTypeScale.insignia,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: GaussSpacing.space4),
                        IconButton(
                          key: const ValueKey('orbit-navigator-close'),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close Orbit Navigator',
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: GaussSpacing.space8),
                    Center(
                      child: _OrbitCourseSwitch(
                        subject: _subject,
                        compact: largeText,
                        onSubject: _selectSubject,
                      ),
                    ),
                    const SizedBox(height: GaussSpacing.space12),
                    _OrbitChapterConstellation(
                      controller: widget.controller,
                      sections: sections,
                      selectedIndex: selectedIndex,
                      onSelected: _selectSection,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GaussSpacing.space8),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  key: const ValueKey('orbit-navigator-chapter-list'),
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 18),
                  child: AnimatedSwitcher(
                    duration: GaussMotion.resolve(
                      context,
                      GaussMotion.standard,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.025, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _OrbitChapterPreview(
                      key: ValueKey('orbit-preview-${_section.id}'),
                      controller: widget.controller,
                      section: _section,
                      index: selectedIndex,
                      sectionCount: sections.length,
                      onContinue: () => widget.onContinue(_subject, _section),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitCourseSwitch extends StatelessWidget {
  const _OrbitCourseSwitch({
    required this.subject,
    required this.compact,
    required this.onSubject,
  });

  final Subject subject;
  final bool compact;
  final ValueChanged<Subject> onSubject;

  @override
  Widget build(BuildContext context) => _SubjectSwitch(
    controlKey: const ValueKey('orbit-navigator-course-switch'),
    subject: subject,
    compact: compact,
    onSubject: onSubject,
  );
}

class _OrbitChapterConstellation extends StatelessWidget {
  const _OrbitChapterConstellation({
    required this.controller,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  final GaussController controller;
  final List<StudySectionDefinition> sections;
  final int selectedIndex;
  final ValueChanged<StudySectionDefinition> onSelected;

  double _progressFor(StudySectionDefinition section) {
    final total = section.topicKeys.fold<int>(
      0,
      (sum, key) =>
          sum +
          controller.topics
              .firstWhere((topic) => topic.key == key)
              .questionCount,
    );
    if (total == 0) return 0;
    final reflected = section.topicKeys.fold<int>(
      0,
      (sum, key) => sum + controller.study.topic(key).reflected,
    );
    return (reflected / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = sections.map(_progressFor).toList(growable: false);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Chapter constellation',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const beaconWidth = 48.0;
              final gaps = math.max(0, sections.length - 1);
              final rawGap = gaps == 0
                  ? 0.0
                  : (constraints.maxWidth - sections.length * beaconWidth) /
                        gaps;
              final gap = rawGap.clamp(8.0, 30.0);
              final contentWidth = sections.length * beaconWidth + gaps * gap;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(constraints.maxWidth, contentWidth),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < sections.length;
                            index++
                          ) ...[
                            if (index > 0)
                              SizedBox(
                                width: gap,
                                child: _OrbitChapterLink(
                                  active: index <= selectedIndex,
                                  complete: progress[index - 1] >= .999,
                                ),
                              ),
                            _OrbitChapterBeacon(
                              key: ValueKey(
                                'orbit-chapter-${sections[index].id}',
                              ),
                              index: index,
                              title: sections[index].title,
                              progress: progress[index],
                              selected: index == selectedIndex,
                              onPressed: () => onSelected(sections[index]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: GaussSpacing.space8),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: Text(
              'CHAPTER ${selectedIndex + 1} OF ${sections.length}',
              textAlign: TextAlign.center,
              softWrap: false,
              style: const TextStyle(
                color: GaussColors.fog,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: .72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitChapterLink extends StatelessWidget {
  const _OrbitChapterLink({required this.active, required this.complete});

  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? GaussColors.signalBright
        : active
        ? GaussColors.brassLight
        : GaussColors.hairline;
    return AnimatedContainer(
      key: const ValueKey('orbit-chapter-link'),
      duration: GaussMotion.resolve(context, GaussMotion.micro),
      height: active ? 2 : 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: active ? .26 : .5),
            color.withValues(alpha: active ? .9 : .5),
          ],
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 7)]
            : null,
      ),
    );
  }
}

class _OrbitChapterBeacon extends StatelessWidget {
  const _OrbitChapterBeacon({
    required this.index,
    required this.title,
    required this.progress,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final int index;
  final String title;
  final double progress;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? GaussColors.brassLight
        : progress >= .999
        ? GaussColors.signalBright
        : GaussColors.fog;
    return Tooltip(
      message: 'Chapter ${index + 1}: $title',
      child: Semantics(
        button: true,
        selected: selected,
        label:
            'Chapter ${index + 1}. $title. ${(progress * 100).round()} percent charted.',
        child: AnimatedScale(
          duration: GaussMotion.resolve(context, GaussMotion.micro),
          scale: selected ? 1.08 : 1,
          curve: Curves.easeOutCubic,
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: selected ? 2.4 : 1.8,
                  color: accent,
                  backgroundColor: GaussColors.hairline.withValues(alpha: .46),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkResponse(
                      onTap: onPressed,
                      containedInkWell: true,
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: GaussMotion.resolve(
                          context,
                          GaussMotion.micro,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected
                              ? RadialGradient(
                                  center: const Alignment(-.28, -.35),
                                  colors: [
                                    GaussColors.brassLight.withValues(
                                      alpha: .34,
                                    ),
                                    GaussColors.brass.withValues(alpha: .13),
                                    GaussColors.deepInk.withValues(alpha: .9),
                                  ],
                                  stops: const [0, .55, 1],
                                )
                              : null,
                          color: selected
                              ? null
                              : GaussColors.deepInk.withValues(alpha: .72),
                          border: Border.all(
                            color: accent.withValues(
                              alpha: selected ? .82 : .34,
                            ),
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: .24),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: selected
                                  ? GaussColors.ivory
                                  : GaussColors.fog,
                              fontSize: GaussTypeScale.metadata,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
}

class _OrbitChapterPreview extends StatelessWidget {
  const _OrbitChapterPreview({
    required this.controller,
    required this.section,
    required this.index,
    required this.sectionCount,
    required this.onContinue,
    super.key,
  });

  final GaussController controller;
  final StudySectionDefinition section;
  final int index;
  final int sectionCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    var currentIndex = nodes.indexWhere(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
    );
    if (currentIndex < 0) currentIndex = nodes.length - 1;
    final currentNode = nodes[currentIndex];
    final currentSnapshot = controller.study.shelf(currentNode.key);
    final total = section.topicKeys.fold<int>(
      0,
      (sum, key) =>
          sum +
          controller.topics
              .firstWhere((topic) => topic.key == key)
              .questionCount,
    );
    final reflected = section.topicKeys.fold<int>(
      0,
      (sum, key) => sum + controller.study.topic(key).reflected,
    );
    final progress = total == 0 ? 0.0 : reflected / total;
    final complete = total > 0 && reflected >= total;
    final nextLabel = complete ? 'MASTERY REVIEW' : 'NEXT FIVE QUESTIONS';
    final actionLabel = complete
        ? 'Open chapter ${index + 1} mastery review'
        : 'Continue chapter ${index + 1} at session ${currentIndex + 1}';

    return Semantics(
      container: true,
      label:
          'Chapter ${index + 1} of $sectionCount. ${section.title}. $reflected of $total charted. Current session ${currentIndex + 1} of ${nodes.length}.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GaussColors.brass.withValues(alpha: .12),
              GaussColors.deepInk.withValues(alpha: .66),
              GaussColors.ink.withValues(alpha: .82),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
              color: GaussColors.abyss.withValues(alpha: .46),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(GaussSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrbitIndexRing(value: index + 1),
                  const SizedBox(width: GaussSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.4,
                          child: Text(
                            'CHAPTER ${index + 1}  ·  ${(progress * 100).round()}% CHARTED',
                            style: const TextStyle(
                              color: GaussColors.brassLight,
                              fontSize: GaussTypeScale.insignia,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .62,
                            ),
                          ),
                        ),
                        const SizedBox(height: GaussSpacing.space4),
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: GaussColors.ivory,
                            fontSize: GaussTypeScale.title,
                            fontWeight: FontWeight.w900,
                            height: 1.16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GaussSpacing.space8),
              Text(
                section.subtitle,
                style: const TextStyle(
                  color: GaussColors.muted,
                  fontSize: GaussTypeScale.caption,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: GaussSpacing.space12),
              ClipRRect(
                borderRadius: BorderRadius.circular(GaussRadii.pill),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  color: complete
                      ? GaussColors.signalBright
                      : GaussColors.brassLight,
                  backgroundColor: GaussColors.abyss.withValues(alpha: .8),
                ),
              ),
              const SizedBox(height: GaussSpacing.space16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GaussColors.abyss.withValues(alpha: .52),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: GaussColors.hairline.withValues(alpha: .8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.4,
                              child: Text(
                                '$nextLabel  ·  ${currentIndex + 1} / ${nodes.length}',
                                softWrap: true,
                                style: const TextStyle(
                                  color: GaussColors.signalBright,
                                  fontSize: GaussTypeScale.insignia,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .58,
                                ),
                              ),
                            ),
                            const SizedBox(height: GaussSpacing.space4),
                            Directionality(
                              textDirection:
                                  _usesRtlScript(currentNode.topic.label)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: Text(
                                currentNode.topic.label,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: GaussColors.ivory,
                                  fontSize: GaussTypeScale.body,
                                  fontWeight: FontWeight.w900,
                                  height: 1.24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${currentSnapshot.reflected} / ${currentNode.questionCount} charted',
                              softWrap: false,
                              style: const TextStyle(
                                color: GaussColors.fog,
                                fontSize: GaussTypeScale.insignia,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: GaussSpacing.space8),
                      OrbitalActionControl(
                        key: const ValueKey('orbit-navigator-continue'),
                        semanticLabel: actionLabel,
                        onPressed: onContinue,
                        icon: complete
                            ? Icons.replay_rounded
                            : Icons.arrow_forward_rounded,
                        dimension: 56,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectSwitch extends StatelessWidget {
  const _SubjectSwitch({
    required this.subject,
    required this.onSubject,
    required this.compact,
    this.controlKey = const ValueKey('map-subject-dual-orbit'),
  });

  final Subject subject;
  final ValueChanged<Subject> onSubject;
  final bool compact;
  final Key controlKey;

  @override
  Widget build(BuildContext context) {
    final mathSelected = subject == Subject.math;
    return Semantics(
      container: true,
      label: 'Study path subject',
      child: SizedBox(
        key: controlKey,
        width: compact ? 100 : 178,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: compact ? 25 : 42,
              right: compact ? 25 : 42,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GaussColors.brass.withValues(alpha: .18),
                      GaussColors.brassLight.withValues(alpha: .72),
                      GaussColors.ice.withValues(alpha: .2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (mathSelected
                                  ? GaussColors.brassLight
                                  : GaussColors.ice)
                              .withValues(alpha: .2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: GaussColors.ivory,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: GaussColors.brassLight.withValues(alpha: .58),
                      blurRadius: 7,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _SubjectOrbitButton(
                    subject: Subject.math,
                    semanticLabel: 'Mathematics study path',
                    selected: mathSelected,
                    compact: compact,
                    key: const ValueKey('map-subject-math'),
                    onPressed: () => onSubject(Subject.math),
                  ),
                ),
                SizedBox(width: compact ? 4 : 8),
                Expanded(
                  child: _SubjectOrbitButton(
                    subject: Subject.physics,
                    semanticLabel: 'Physics study path',
                    selected: !mathSelected,
                    compact: compact,
                    key: const ValueKey('map-subject-physics'),
                    onPressed: () => onSubject(Subject.physics),
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

class _SubjectOrbitButton extends StatelessWidget {
  const _SubjectOrbitButton({
    required this.subject,
    required this.semanticLabel,
    required this.selected,
    required this.compact,
    required this.onPressed,
    super.key,
  });

  final Subject subject;
  final String semanticLabel;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = subject == Subject.math
        ? GaussColors.brassLight
        : GaussColors.ice;
    final label = subject == Subject.math ? 'Math' : 'Physics';
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        container: true,
        label: semanticLabel,
        button: true,
        selected: selected,
        child: InkResponse(
          onTap: onPressed,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          radius: compact ? 28 : 36,
          child: AnimatedContainer(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minWidth: GaussMetrics.minTouchTarget,
              minHeight: GaussMetrics.minTouchTarget,
            ),
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 6),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: .15)
                  : GaussColors.deepInk.withValues(alpha: .56),
              borderRadius: BorderRadius.circular(compact ? 26 : 18),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: .92)
                    : GaussColors.hairline.withValues(alpha: .78),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: .22),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (subject == Subject.math)
                    Icon(Icons.functions_rounded, color: accent, size: 21)
                  else
                    TopicGlyph(
                      topicKey: 'atomic_nuclear',
                      color: accent,
                      size: 22,
                    ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        softWrap: false,
                        style: TextStyle(
                          color: selected ? GaussColors.ivory : GaussColors.fog,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyPathStage extends StatefulWidget {
  const _StudyPathStage({
    required this.controller,
    required this.section,
    required this.nodes,
    required this.currentIndex,
    required this.selectedKey,
    required this.bottomObstruction,
    required this.onSelected,
    super.key,
  });

  final GaussController controller;
  final StudySectionDefinition section;
  final List<StudyPathNode> nodes;
  final int currentIndex;
  final String selectedKey;
  final double bottomObstruction;
  final ValueChanged<StudyPathNode> onSelected;

  @override
  State<_StudyPathStage> createState() => _StudyPathStageState();
}

class _StudyPathStageState extends State<_StudyPathStage> {
  final ScrollController _scrollController = ScrollController();
  final GaussPathGeometryCache _geometryCache = GaussPathGeometryCache();
  GaussPathGeometry? _geometry;
  GaussPathGeometry? _positionedGeometry;
  String? _positionedSectionId;

  @override
  void didUpdateWidget(covariant _StudyPathStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) {
      // The next layout owns the new route geometry. Let build schedule one
      // exact camera placement after those coordinates exist instead of
      // blindly resetting to offset zero and visually disagreeing with the
      // restored/selected learning topic.
      _positionedSectionId = null;
      _positionedGeometry = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _positionNode(int index, {required bool animate}) {
    final geometry = _geometry;
    if (!_scrollController.hasClients || geometry == null) return;
    final safe = index.clamp(0, geometry.positions.length - 1);
    final visibleHeight = math.max(
      160.0,
      _scrollController.position.viewportDimension - widget.bottomObstruction,
    );
    // A restored or explicitly targeted lesson belongs in the upper reading
    // third, not the mathematical center. This keeps its chapter threshold
    // and the next route segment visible together while the mission dock owns
    // the lower third of a compact Android viewport.
    final target = (geometry.positions[safe].dy - visibleHeight * .34).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
    );
  }

  void jumpToNode(int index) => _positionNode(index, animate: true);

  /// The path is the first meaningful visual after first-run onboarding.  A
  /// focus transfer from the dismissed overlay must never strand that first
  /// frame at a lower study set.
  void resetToStart() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final geometry = _geometryCache.resolve(
        sectionId: widget.section.id,
        width: constraints.maxWidth,
        nodes: widget.nodes,
        textScale: MediaQuery.textScalerOf(context).scale(1),
      );
      _geometry = geometry;
      final completed = List<bool>.unmodifiable([
        for (final node in widget.nodes)
          widget.controller.study.shelf(node.key).reflected >=
              node.questionCount,
      ]);
      final completedSignature = Object.hashAll(completed);
      if (_positionedSectionId != widget.section.id ||
          !identical(_positionedGeometry, geometry)) {
        _positionedSectionId = widget.section.id;
        _positionedGeometry = geometry;
        final sectionId = widget.section.id;
        final selectedIndex = widget.nodes.indexWhere(
          (node) => node.key == widget.selectedKey,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || widget.section.id != sectionId || selectedIndex < 0) {
            return;
          }
          _positionNode(selectedIndex, animate: false);
        });
      }
      final liveViewportHeight = math.max(
        160.0,
        constraints.maxHeight - widget.bottomObstruction,
      );
      return Stack(
        key: const ValueKey('map-study-path-scroll'),
        fit: StackFit.expand,
        children: [
          _MapViewportOcclusionFade(
            bottomObstruction: widget.bottomObstruction,
            child: CustomScrollView(
              key: const ValueKey('map-study-path-scrollable'),
              controller: _scrollController,
              scrollCacheExtent: ScrollCacheExtent.pixels(
                math.min(900.0, math.max(520.0, liveViewportHeight * 1.1)),
              ),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, bandIndex) => _StudyPathBand(
                      key: ValueKey('map-path-band-$bandIndex'),
                      band: geometry.bands[bandIndex],
                      geometry: geometry,
                      controller: widget.controller,
                      nodes: widget.nodes,
                      currentIndex: widget.currentIndex,
                      selectedKey: widget.selectedKey,
                      completed: completed,
                      completedSignature: completedSignature,
                      stageWidth: constraints.maxWidth,
                      onSelected: widget.onSelected,
                    ),
                    childCount: geometry.bands.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    addSemanticIndexes: false,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: widget.bottomObstruction + GaussSpacing.space32,
                  ),
                ),
              ],
            ),
          ),
          if (widget.bottomObstruction > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.bottomObstruction,
              child: const AbsorbPointer(
                key: ValueKey('map-overlay-hit-shield'),
                child: SizedBox.expand(),
              ),
            ),
        ],
      );
    },
  );
}

/// Dissolves map instruments before they enter the fixed Mission Compass and
/// shell-footer control field. The astronomical backdrop remains untouched, so
/// this creates neither an opaque shelf nor the false full-width bar that the
/// floating HUD replaced.
class _MapViewportOcclusionFade extends StatelessWidget {
  const _MapViewportOcclusionFade({
    required this.bottomObstruction,
    required this.child,
  });

  final double bottomObstruction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (bottomObstruction <= 0) return child;
    return ShaderMask(
      key: const ValueKey('map-overlay-occlusion-fade'),
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final boundary = (bounds.height - bottomObstruction).clamp(
          0.0,
          bounds.height,
        );
        final fadeStart = (boundary - GaussSpacing.space32).clamp(
          0.0,
          bounds.height,
        );
        final fadeEnd = (boundary + GaussSpacing.space12).clamp(
          fadeStart + .001,
          bounds.height,
        );
        final height = math.max(1.0, bounds.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0, fadeStart / height, fadeEnd / height],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class _StudyPathBand extends StatelessWidget {
  const _StudyPathBand({
    required this.band,
    required this.geometry,
    required this.controller,
    required this.nodes,
    required this.currentIndex,
    required this.selectedKey,
    required this.completed,
    required this.completedSignature,
    required this.stageWidth,
    required this.onSelected,
    super.key,
  });

  final GaussPathBand band;
  final GaussPathGeometry geometry;
  final GaussController controller;
  final List<StudyPathNode> nodes;
  final int currentIndex;
  final String selectedKey;
  final List<bool> completed;
  final int completedSignature;
  final double stageWidth;
  final ValueChanged<StudyPathNode> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: band.height,
    width: stageWidth,
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _StageInstrumentPainter(
                current: geometry.positions[currentIndex],
                nodeSize: geometry.nodeSize,
                bandTop: band.top,
                sceneHeight: geometry.height,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _ContinuousPathPainter(
                geometry: geometry,
                subject: nodes.first.topic.subject,
                segmentIndices: band.segmentIndices,
                completed: completed,
                completedSignature: completedSignature,
                currentIndex: currentIndex,
                bandTop: band.top,
              ),
            ),
          ),
        ),
        for (final landmarkIndex in band.landmarkIndices)
          _PathLandmark(
            landmark: geometry.landmarks[landmarkIndex],
            localTop: geometry.landmarks[landmarkIndex].top - band.top,
          ),
        for (final headerIndex in band.headerIndices)
          Positioned(
            key: ValueKey(
              'map-section-gate-${geometry.unitHeaders[headerIndex].unitNumber}',
            ),
            left: 12,
            right: 12,
            top: geometry.unitHeaders[headerIndex].y - band.top,
            child: _SectionGate(
              topic: geometry.unitHeaders[headerIndex].topic,
              unitNumber: geometry.unitHeaders[headerIndex].unitNumber,
              reflected: controller.study
                  .topic(geometry.unitHeaders[headerIndex].topic.key)
                  .reflected,
            ),
          ),
        for (final nodeIndex in band.nodeIndices)
          Positioned(
            left: geometry.positions[nodeIndex].dx - geometry.nodeSize / 2,
            top:
                geometry.positions[nodeIndex].dy -
                band.top -
                geometry.nodeSize / 2,
            child: _StudyNode(
              node: nodes[nodeIndex],
              studyLabel: controller.studySetLabel(nodes[nodeIndex]),
              size: geometry.nodeSize,
              snapshot: controller.study.shelf(nodes[nodeIndex].key),
              current: nodeIndex == currentIndex,
              selected: nodes[nodeIndex].key == selectedKey,
              future: nodeIndex > currentIndex,
              entryAngle: nodeIndex == 0
                  ? null
                  : math.atan2(
                          geometry.tangents[nodeIndex].dy,
                          geometry.tangents[nodeIndex].dx,
                        ) +
                        math.pi,
              exitAngle: nodeIndex >= geometry.positions.length - 1
                  ? null
                  : math.atan2(
                      geometry.tangents[nodeIndex].dy,
                      geometry.tangents[nodeIndex].dx,
                    ),
              onPressed: () => onSelected(nodes[nodeIndex]),
            ),
          ),
        for (final nodeIndex in band.nodeIndices)
          _PathNodeLabel(
            node: nodes[nodeIndex],
            studyLabel: controller.studySetLabel(nodes[nodeIndex]),
            snapshot: controller.study.shelf(nodes[nodeIndex].key),
            position: band.localize(geometry.positions[nodeIndex]),
            nodeSize: geometry.nodeSize,
            stageWidth: stageWidth,
            isCurrent: nodeIndex == currentIndex,
            selected: nodes[nodeIndex].key == selectedKey,
          ),
      ],
    ),
  );
}

class _SectionGate extends StatelessWidget {
  const _SectionGate({
    required this.topic,
    required this.unitNumber,
    required this.reflected,
  });

  final TopicDescriptor topic;
  final int unitNumber;
  final int reflected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final stacked = constraints.maxWidth < 360 || textScale >= 1.35;
      final accessibilityCompact = textScale >= 1.55;
      final orbit = Text(
        'CHAPTER $unitNumber',
        style: const TextStyle(
          color: GaussColors.brassLight,
          fontSize: GaussTypeScale.insignia,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.05,
        ),
      );
      final title = Text(
        topic.label,
        textAlign: stacked ? TextAlign.center : TextAlign.start,
        softWrap: true,
        style: const TextStyle(
          color: GaussColors.ivory,
          fontSize: 13,
          height: 1.22,
          fontWeight: FontWeight.w900,
        ),
      );
      final progress = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GaussSpacing.space8,
        runSpacing: GaussSpacing.space4,
        children: [
          TopicGlyph(
            topicKey: topic.key,
            color: GaussColors.signalBright,
            size: 16,
          ),
          Text(
            '$reflected / ${topic.questionCount} CHARTED',
            style: const TextStyle(
              color: GaussColors.fog,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w800,
              letterSpacing: .55,
            ),
          ),
        ],
      );

      final compactStage = constraints.maxWidth < 560;
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: accessibilityCompact ? 1.45 : 1.75,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compactStage ? 360 : 430),
            child: Semantics(
              container: true,
              label:
                  'Chapter $unitNumber. ${topic.label}. $reflected of ${topic.questionCount} questions charted.',
              child: Container(
                key: const ValueKey('map-section-gate-instrument'),
                padding: EdgeInsetsDirectional.fromSTEB(
                  14,
                  compactStage ? 8 : 10,
                  14,
                  compactStage ? 9 : 11,
                ),
                // Chapter thresholds are celestial annotations on the map,
                // not opaque dashboard cards. The restrained edge rails keep
                // the identity readable while leaving the astronomical route
                // visibly continuous behind it.
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      GaussColors.deepInk.withValues(
                        alpha: compactStage ? .24 : .42,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0, .5, 1],
                  ),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: GaussColors.brass.withValues(alpha: .32),
                    ),
                  ),
                ),
                child: accessibilityCompact
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SectionGateNumber(value: unitNumber),
                              const SizedBox(width: GaussSpacing.space8),
                              orbit,
                            ],
                          ),
                          const SizedBox(height: GaussSpacing.space4),
                          title,
                          const SizedBox(height: GaussSpacing.space8),
                          progress,
                        ],
                      )
                    : stacked
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SectionGateNumber(value: unitNumber),
                              const SizedBox(width: GaussSpacing.space8),
                              orbit,
                            ],
                          ),
                          const SizedBox(height: GaussSpacing.space4),
                          title,
                          const SizedBox(height: GaussSpacing.space8),
                          progress,
                        ],
                      )
                    : Row(
                        children: [
                          _SectionGateNumber(value: unitNumber),
                          const SizedBox(width: GaussSpacing.space8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                orbit,
                                const SizedBox(height: 2),
                                title,
                              ],
                            ),
                          ),
                          const SizedBox(width: GaussSpacing.space12),
                          progress,
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SectionGateNumber extends StatelessWidget {
  const _SectionGateNumber({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GaussColors.abyss,
      border: Border.all(color: GaussColors.brassLight.withValues(alpha: .78)),
      boxShadow: [
        BoxShadow(
          color: GaussColors.brassLight.withValues(alpha: .16),
          blurRadius: 10,
        ),
      ],
    ),
    child: Text(
      '$value',
      style: const TextStyle(
        color: GaussColors.ivory,
        fontSize: GaussTypeScale.metadata,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _PathLandmark extends StatelessWidget {
  const _PathLandmark({required this.landmark, required this.localTop});

  final GaussLandmarkGeometry landmark;
  final double localTop;

  @override
  Widget build(BuildContext context) {
    final asset = switch (landmark.kind) {
      0 => 'assets/visual/map/theorem_engine.png',
      1 => 'assets/visual/nodes/boss_observatory.png',
      _ => 'assets/visual/mascot/mira_thinking.png',
    };
    return PositionedDirectional(
      start: landmark.start,
      end: landmark.end,
      top: localTop,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: SizedBox.square(
            dimension: landmark.size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: landmark.size * .58,
                  height: landmark.size * .58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (landmark.kind == 2
                                    ? GaussColors.ice
                                    : GaussColors.brass)
                                .withValues(alpha: .16),
                        blurRadius: landmark.size * .24,
                        spreadRadius: landmark.size * .025,
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: landmark.kind == 2 ? .9 : .84,
                  child: Image.asset(
                    asset,
                    width: landmark.size,
                    height: landmark.size,
                    fit: BoxFit.contain,
                    cacheWidth: _boundedRasterWidth(
                      context,
                      landmark.size,
                      sourceWidth: 1254,
                      minimum: 160,
                    ),
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                if (landmark.kind == 0 && landmark.size >= 150)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GaussColors.deepInk.withValues(alpha: .86),
                        borderRadius: BorderRadius.circular(GaussRadii.pill),
                        border: Border.all(
                          color: GaussColors.brass.withValues(alpha: .32),
                        ),
                      ),
                      child: const Text(
                        'THEOREM ENGINE',
                        style: TextStyle(
                          color: GaussColors.brassLight,
                          fontSize: GaussTypeScale.insignia,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .85,
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
}

/// Quiet astrolabe scaffolding behind the path. It gives wide stages the same
/// authored astronomical depth as the accepted direction without turning the
/// continuous learning route back into a set of disconnected orbit menus.
class _StageInstrumentPainter extends CustomPainter {
  const _StageInstrumentPainter({
    required this.current,
    required this.nodeSize,
    required this.bandTop,
    required this.sceneHeight,
  });

  final Offset current;
  final double nodeSize;
  final double bandTop;
  final double sceneHeight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, -bandTop);
    final expanded = size.width >= 760;
    final majorRadius = math.min(
      size.width * (expanded ? .58 : .66),
      expanded ? 460.0 : 310.0,
    );
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GaussColors.brass.withValues(alpha: expanded ? .105 : .075);
    final finePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = GaussColors.ice.withValues(alpha: .055);
    final pinPaint = Paint()
      ..color = GaussColors.brassLight.withValues(alpha: .18);

    final firstCenter = math
        .max(330.0, ((bandTop - 380) / 720).floor() * 720 + 330)
        .toDouble();
    final lastCenter = math
        .min(sceneHeight + 300, bandTop + size.height + 380)
        .toDouble();
    for (var centerY = firstCenter; centerY < lastCenter; centerY += 720) {
      final center = Offset(size.width * .5, centerY);
      for (final scale in const [.58, .79, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: majorRadius * 2 * scale,
            height: majorRadius * .78 * scale,
          ),
          scale == 1 ? orbitPaint : finePaint,
        );
      }
      canvas.drawLine(
        Offset(center.dx - majorRadius, center.dy),
        Offset(center.dx + majorRadius, center.dy),
        finePaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - majorRadius * .39),
        Offset(center.dx, center.dy + majorRadius * .39),
        finePaint,
      );
      for (var tick = 0; tick < 12; tick++) {
        final angle = tick * math.pi * 2 / 12;
        canvas.drawCircle(
          Offset(
            center.dx + math.cos(angle) * majorRadius,
            center.dy + math.sin(angle) * majorRadius * .39,
          ),
          tick.isEven ? 1.35 : .8,
          pinPaint,
        );
      }
      canvas.drawCircle(
        center,
        4.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = GaussColors.signalBright.withValues(alpha: .12),
      );
    }
    final focusPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final focusRect = Rect.fromCircle(center: current, radius: nodeSize * .71);
    focusPaint
      ..strokeWidth = 1.3
      ..color = GaussColors.signalBright.withValues(alpha: .34);
    canvas.drawArc(focusRect, -.3, math.pi * .72, false, focusPaint);
    focusPaint
      ..strokeWidth = 1
      ..color = GaussColors.brassLight.withValues(alpha: .26);
    canvas.drawArc(
      focusRect.inflate(nodeSize * .12),
      math.pi * .84,
      math.pi * .62,
      false,
      focusPaint,
    );
    canvas.drawCircle(
      current,
      nodeSize * .92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = GaussColors.brass.withValues(alpha: .13),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StageInstrumentPainter oldDelegate) =>
      oldDelegate.current != current ||
      oldDelegate.nodeSize != nodeSize ||
      oldDelegate.bandTop != bandTop ||
      oldDelegate.sceneHeight != sceneHeight;
}

/// The reference route keeps the names attached to their instruments, instead
/// of making people infer every destination from an icon.  This stays live so
/// Persian curriculum labels and real local progress never get frozen into a
/// decorative map image.
class _PathNodeLabel extends StatelessWidget {
  const _PathNodeLabel({
    required this.node,
    required this.studyLabel,
    required this.snapshot,
    required this.position,
    required this.nodeSize,
    required this.stageWidth,
    required this.isCurrent,
    required this.selected,
  });

  final StudyPathNode node;
  final String studyLabel;
  final StudyTopicSnapshot snapshot;
  final Offset position;
  final double nodeSize;
  final double stageWidth;
  final bool isCurrent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final compact = stageWidth < 560;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.55;
    final emphasized = isCurrent || selected;
    final desiredWidth = math.min(
      compact
          ? largeText
                ? 142.0
                : emphasized
                ? 138.0
                : 132.0
          : 172.0,
      math.max(compact ? 120.0 : 138.0, stageWidth * (compact ? .43 : .29)),
    );
    final nodeReach = nodeSize * .61;
    final leadingCapacity = math.max(0.0, position.dx - nodeReach - 6);
    final trailingCapacity = math.max(
      0.0,
      stageWidth - 6 - (position.dx + nodeReach),
    );
    // Central lessons cannot fit the ideal label width on either side at
    // 320dp. Choose the roomier side and let the label reflow into the exact
    // available lane instead of clamping a full-width plate through the node.
    final rightPreferred = trailingCapacity >= leadingCapacity;
    final availableWidth = rightPreferred ? trailingCapacity : leadingCapacity;
    final width = math.min(desiredWidth, math.max(92.0, availableWidth));
    final left = rightPreferred
        ? position.dx + nodeReach
        : math.max(6.0, position.dx - nodeReach - width);
    final accent = emphasized
        ? GaussColors.signalBright
        : GaussColors.brassLight;
    return Positioned(
      key: ValueKey('map-node-label-${node.key}'),
      left: left,
      top: position.dy - (compact ? 22 : 30),
      width: width,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            opacity: emphasized ? 1 : .94,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.35,
              child: AnimatedContainer(
                duration: GaussMotion.resolve(context, GaussMotion.micro),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: emphasized
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          begin: rightPreferred
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: rightPreferred
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          colors: [
                            GaussColors.deepInk.withValues(alpha: .58),
                            GaussColors.deepInk.withValues(alpha: .06),
                          ],
                        ),
                      )
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (rightPreferred) ...[
                      _OrbitalLabelAnchor(
                        pointsTowardStart: true,
                        color: accent,
                        emphasized: emphasized,
                      ),
                      const SizedBox(width: GaussSpacing.space4),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            studyLabel,
                            textAlign: rightPreferred
                                ? TextAlign.start
                                : TextAlign.end,
                            softWrap: true,
                            style: TextStyle(
                              color: emphasized
                                  ? GaussColors.ivory
                                  : GaussColors.ivory.withValues(alpha: .74),
                              fontSize: compact
                                  ? (emphasized ? 10.8 : 10.2)
                                  : 13,
                              height: 1.22,
                              fontWeight: emphasized
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              shadows: const [
                                Shadow(color: Color(0xCC03090B), blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${snapshot.reflected} / ${node.questionCount}  ·  ${isCurrent ? 'CURRENT' : 'LESSON'}',
                            textAlign: rightPreferred
                                ? TextAlign.start
                                : TextAlign.end,
                            softWrap: true,
                            style: TextStyle(
                              color: emphasized
                                  ? GaussColors.signalBright
                                  : GaussColors.signal.withValues(alpha: .86),
                              fontSize: compact ? 8.2 : GaussTypeScale.insignia,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!rightPreferred) ...[
                      const SizedBox(width: GaussSpacing.space4),
                      _OrbitalLabelAnchor(
                        pointsTowardStart: false,
                        color: accent,
                        emphasized: emphasized,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitalLabelAnchor extends StatelessWidget {
  const _OrbitalLabelAnchor({
    required this.pointsTowardStart,
    required this.color,
    required this.emphasized,
  });

  final bool pointsTowardStart;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: emphasized ? 16 : 12,
    height: 34,
    child: CustomPaint(
      painter: _OrbitalLabelAnchorPainter(
        pointsTowardStart: pointsTowardStart,
        color: color,
        emphasized: emphasized,
      ),
    ),
  );
}

class _OrbitalLabelAnchorPainter extends CustomPainter {
  const _OrbitalLabelAnchorPainter({
    required this.pointsTowardStart,
    required this.color,
    required this.emphasized,
  });

  final bool pointsTowardStart;
  final Color color;
  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    final near = pointsTowardStart ? 0.0 : size.width;
    final far = pointsTowardStart ? size.width : 0.0;
    final y = size.height * .5;
    canvas.drawLine(
      Offset(near, y),
      Offset(far, y),
      Paint()
        ..strokeWidth = emphasized ? 1.4 : .8
        ..color = color.withValues(alpha: emphasized ? .72 : .38),
    );
    canvas.drawCircle(
      Offset(near, y),
      emphasized ? 2.5 : 1.8,
      Paint()..color = color.withValues(alpha: emphasized ? .95 : .7),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalLabelAnchorPainter oldDelegate) =>
      oldDelegate.pointsTowardStart != pointsTowardStart ||
      oldDelegate.color != color ||
      oldDelegate.emphasized != emphasized;
}

class _StudyNode extends StatelessWidget {
  const _StudyNode({
    required this.node,
    required this.studyLabel,
    required this.size,
    required this.snapshot,
    required this.current,
    required this.selected,
    required this.future,
    required this.entryAngle,
    required this.exitAngle,
    required this.onPressed,
  });

  final StudyPathNode node;
  final String studyLabel;
  final double size;
  final StudyTopicSnapshot snapshot;
  final bool current;
  final bool selected;
  final bool future;
  final double? entryAngle;
  final double? exitAngle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final complete = snapshot.reflected >= node.questionCount;
    final mathStation = node.topic.subject == Subject.math;
    final accent = complete
        ? GaussColors.signalBright
        : current || selected
        ? mathStation
              ? GaussColors.brassLight
              : GaussColors.ice
        : mathStation
        ? GaussColors.brass
        : GaussColors.ice;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${node.topic.label}. $studyLabel. ${node.setLabel}. '
          '${snapshot.reflected} of ${node.questionCount} reflected. '
          '${snapshot.revisit} marked for revisit.',
      hint: 'Double tap to inspect this study set.',
      child: InkResponse(
        key: ValueKey('map-node-${node.key}'),
        onTap: onPressed,
        radius: size * .62,
        child: AnimatedScale(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: current
              ? 1.13
              : selected
              ? 1.07
              : future
              ? .98
              : 1,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (current || selected)
                  CustomPaint(
                    size: Size.square(size * 1.28),
                    painter: _CurrentNodeAuraPainter(
                      accent: accent,
                      selected: selected,
                    ),
                  ),
                RepaintBoundary(
                  key: ValueKey(
                    'map-node-${node.topic.subject.name}-station-${node.key}',
                  ),
                  child: Opacity(
                    opacity: future && !selected ? .72 : 1,
                    child: Image.asset(
                      node.topic.subject == Subject.math
                          ? 'assets/visual/nodes/math_astrolabe_station_v2.png'
                          : 'assets/visual/nodes/physics_gyroscope_station_v2.png',
                      width: size * 1.04,
                      height: size * 1.04,
                      fit: BoxFit.contain,
                      cacheWidth: _boundedRasterWidth(
                        context,
                        size * 1.04,
                        sourceWidth: node.topic.subject == Subject.math
                            ? 1254
                            : 1285,
                        minimum: 192,
                      ),
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size.square(size),
                  painter: _SubjectStationOverlayPainter(
                    subject: node.topic.subject,
                    accent: accent,
                    reflected: snapshot.reflected,
                    emphasized: current || selected,
                    complete: complete,
                    future: future && !selected,
                    entryAngle: entryAngle,
                    exitAngle: exitAngle,
                  ),
                ),
                PositionedDirectional(
                  end: -3,
                  top: -4,
                  child: _NodeNumber(value: node.partIndex + 1),
                ),
                if (complete)
                  const PositionedDirectional(
                    start: 2,
                    bottom: 3,
                    child: _NodeStateJewel(
                      color: GaussColors.signalBright,
                      diamond: true,
                    ),
                  )
                else if (snapshot.revisit > 0)
                  const PositionedDirectional(
                    start: 2,
                    bottom: 3,
                    child: _NodeStateJewel(
                      color: GaussColors.warning,
                      diamond: false,
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

class _SubjectStationOverlayPainter extends CustomPainter {
  const _SubjectStationOverlayPainter({
    required this.subject,
    required this.accent,
    required this.reflected,
    required this.emphasized,
    required this.complete,
    required this.future,
    required this.entryAngle,
    required this.exitAngle,
  });

  final Subject subject;
  final Color accent;
  final int reflected;
  final bool emphasized;
  final bool complete;
  final bool future;
  final double? entryAngle;
  final double? exitAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final opacity = future ? .58 : 1.0;
    for (final angle in [entryAngle, exitAngle]) {
      if (angle != null) {
        _paintDockingPort(canvas, center, size.shortestSide, angle, opacity);
      }
    }
    _paintLessonBearings(canvas, center, size.shortestSide, opacity);
    if (complete) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.shortestSide * .485),
        -math.pi * .72,
        math.pi * 1.44,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.1
          ..color = GaussColors.signalBright.withValues(alpha: .88),
      );
    }
  }

  void _paintDockingPort(
    Canvas canvas,
    Offset center,
    double extent,
    double angle,
    double opacity,
  ) {
    final metal = subject == Subject.math
        ? GaussColors.brassLight
        : GaussColors.ice;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    // The live rail terminates just inside this recessed collar.  A short
    // channel continues beneath the station body, so the connection reads as
    // one engineered instrument rather than a line touching an image.
    final portCenter = Offset(extent * .405, 0);
    final outerRadius = extent * .058;
    final channelStart = Offset(extent * .338, 0);
    final channelEnd = Offset(extent * .44, 0);
    canvas.drawLine(
      channelStart,
      channelEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = extent * .054
        ..color = const Color(0xE603090C),
    );
    canvas.drawLine(
      channelStart,
      channelEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = extent * .026
        ..color = metal.withValues(alpha: .78 * opacity),
    );
    canvas.drawLine(
      channelStart,
      channelEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = extent * .009
        ..color = accent.withValues(alpha: .9 * opacity),
    );
    canvas.drawCircle(
      portCenter + Offset(0, extent * .018),
      outerRadius,
      Paint()
        ..color = const Color(0xCC010609)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(
      portCenter,
      outerRadius,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-.35, -.42),
              colors: [
                metal.withValues(alpha: .9 * opacity),
                const Color(0xFF132126).withValues(alpha: .98 * opacity),
              ],
            ).createShader(
              Rect.fromCircle(center: portCenter, radius: outerRadius),
            ),
    );
    canvas.drawCircle(
      portCenter,
      extent * .034,
      Paint()..color = const Color(0xFF031014).withValues(alpha: opacity),
    );
    canvas.drawCircle(
      portCenter,
      extent * .013,
      Paint()..color = accent.withValues(alpha: .92 * opacity),
    );
    canvas.drawCircle(
      portCenter - Offset(extent * .004, extent * .004),
      extent * .004,
      Paint()..color = GaussColors.ivory.withValues(alpha: .82 * opacity),
    );
    canvas.restore();
  }

  void _paintLessonBearings(
    Canvas canvas,
    Offset center,
    double extent,
    double opacity,
  ) {
    final filledCount = reflected.clamp(0, GaussStudyCurriculum.batchSize);
    final bearingColor = complete ? GaussColors.signalBright : accent;
    for (var index = 0; index < GaussStudyCurriculum.batchSize; index++) {
      final angle =
          math.pi * (.17 + .66 * index / (GaussStudyCurriculum.batchSize - 1));
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (extent * .315);
      final filled = index < filledCount;
      canvas.drawCircle(
        point + Offset(0, extent * .006),
        emphasized ? 2.5 : 2.2,
        Paint()..color = const Color(0xB8010507),
      );
      canvas.drawCircle(
        point,
        emphasized ? 1.9 : 1.65,
        Paint()
          ..color = filled
              ? bearingColor.withValues(alpha: .96 * opacity)
              : const Color(0xFF13252B).withValues(alpha: .9 * opacity),
      );
      canvas.drawCircle(
        point,
        emphasized ? 1.9 : 1.65,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = bearingColor.withValues(
            alpha: (filled ? .9 : .42) * opacity,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SubjectStationOverlayPainter oldDelegate) =>
      oldDelegate.subject != subject ||
      oldDelegate.accent != accent ||
      oldDelegate.reflected != reflected ||
      oldDelegate.emphasized != emphasized ||
      oldDelegate.complete != complete ||
      oldDelegate.future != future ||
      oldDelegate.entryAngle != entryAngle ||
      oldDelegate.exitAngle != exitAngle;
}

class _CurrentNodeAuraPainter extends CustomPainter {
  const _CurrentNodeAuraPainter({required this.accent, required this.selected});

  final Color accent;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Rect.fromCircle(center: center, radius: size.width * .41);
    final outer = Rect.fromCircle(center: center, radius: size.width * .48);
    final glowRect = Rect.fromCircle(center: center, radius: size.width * .46);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: selected ? .2 : .15),
          accent.withValues(alpha: .055),
          accent.withValues(alpha: 0),
        ],
        stops: const [0, .56, 1],
      ).createShader(glowRect);
    canvas.drawCircle(center, size.width * .46, glow);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1
      ..color = accent.withValues(alpha: .82);
    canvas.drawArc(ring, -.95, math.pi * .46, false, arc);
    canvas.drawArc(ring, math.pi * .78, math.pi * .36, false, arc);
    arc
      ..strokeWidth = 1
      ..color = GaussColors.brassLight.withValues(alpha: .48);
    canvas.drawArc(outer, .1, math.pi * .28, false, arc);
    canvas.drawArc(outer, math.pi * 1.18, math.pi * .22, false, arc);
    for (var index = 0; index < 4; index++) {
      final angle = -.95 + index * math.pi * .5;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * size.width * .48,
        1.6,
        Paint()..color = GaussColors.brassLight.withValues(alpha: .7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurrentNodeAuraPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.selected != selected;
}

class _NodeNumber extends StatelessWidget {
  const _NodeNumber({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 23, minHeight: 23),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GaussColors.deepInk,
      border: Border.all(color: GaussColors.brass.withValues(alpha: .6)),
    ),
    child: Text(
      '$value',
      style: const TextStyle(
        color: GaussColors.ivory,
        fontSize: GaussTypeScale.insignia,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _NodeStateJewel extends StatelessWidget {
  const _NodeStateJewel({required this.color, required this.diamond});

  final Color color;
  final bool diamond;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: diamond ? math.pi / 4 : 0,
    child: Container(
      width: diamond ? 13 : 11,
      height: diamond ? 13 : 11,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .86),
        shape: diamond ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: diamond ? BorderRadius.circular(2.5) : null,
        border: Border.all(color: GaussColors.ivory.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .45), blurRadius: 7),
        ],
      ),
    ),
  );
}

class _ContinuousPathPainter extends CustomPainter {
  const _ContinuousPathPainter({
    required this.geometry,
    required this.subject,
    required this.segmentIndices,
    required this.completed,
    required this.completedSignature,
    required this.currentIndex,
    required this.bandTop,
  });

  final GaussPathGeometry geometry;
  final Subject subject;
  final List<int> segmentIndices;
  final List<bool> completed;
  final int completedSignature;
  final int currentIndex;
  final double bandTop;

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.positions.length < 2) return;
    final subjectMetal = subject == Subject.math
        ? GaussColors.brass
        : const Color(0xFF5B9EAC);
    final subjectHighlight = subject == Subject.math
        ? GaussColors.brassLight
        : GaussColors.ice;
    canvas.save();
    canvas.translate(0, -bandTop);
    for (final index in segmentIndices) {
      final source = geometry.pathForSegment(index);
      final sourceMetric = source.computeMetrics().single;
      final trim = math.min(
        geometry.nodeSize * .405,
        sourceMetric.length * .32,
      );
      final rail = sourceMetric.extractPath(
        trim,
        math.max(trim + 1, sourceMetric.length - trim),
      );
      final railMetric = rail.computeMetrics().single;
      final isComplete = completed[index];
      final isCurrentLead = index == currentIndex;
      final energized = isComplete || isCurrentLead;
      final energy = isComplete ? GaussColors.signalBright : subjectHighlight;
      final bounds = rail.getBounds().inflate(14);

      if (energized) {
        canvas.drawPath(
          rail,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isCurrentLead ? 9 : 7
            ..strokeCap = StrokeCap.round
            ..color = energy.withValues(alpha: isCurrentLead ? .2 : .12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawPath(
        rail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.6
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xD8010507),
      );
      canvas.drawPath(
        rail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.9
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF111A1D),
              subjectMetal.withValues(alpha: energized ? .9 : .58),
              const Color(0xFF071014),
            ],
          ).createShader(bounds),
      );
      canvas.drawPath(
        rail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = energized ? 1.65 : 1.25
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: energized
                ? [
                    energy.withValues(alpha: .42),
                    energy.withValues(alpha: .98),
                    energy.withValues(alpha: .48),
                  ]
                : [
                    subjectHighlight.withValues(alpha: .22),
                    subjectMetal.withValues(alpha: .62),
                    subjectHighlight.withValues(alpha: .18),
                  ],
          ).createShader(bounds),
      );
      canvas.drawPath(
        rail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .48
          ..strokeCap = StrokeCap.round
          ..color = GaussColors.ivory.withValues(alpha: energized ? .46 : .22),
      );

      final start = railMetric.getTangentForOffset(0)?.position;
      final end = railMetric.getTangentForOffset(railMetric.length)?.position;
      if (start != null) _drawCouplerGlow(canvas, start, energy, energized);
      if (end != null) _drawCouplerGlow(canvas, end, energy, energized);

      if (isCurrentLead) {
        for (var marker = 1; marker <= 3; marker++) {
          final tangent = railMetric.getTangentForOffset(
            railMetric.length * marker / 4,
          );
          if (tangent != null) {
            canvas.drawCircle(
              tangent.position,
              1.9,
              Paint()..color = subjectHighlight.withValues(alpha: .9),
            );
          }
        }
      }
    }
    canvas.restore();
  }

  void _drawCouplerGlow(
    Canvas canvas,
    Offset position,
    Color color,
    bool energized,
  ) {
    canvas.drawCircle(
      position,
      energized ? 4.2 : 3.2,
      Paint()
        ..color = color.withValues(alpha: energized ? .22 : .1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      position,
      energized ? 2.5 : 2.1,
      Paint()..color = const Color(0xF203090C),
    );
    canvas.drawCircle(
      position,
      energized ? 1.95 : 1.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .72
        ..color = color.withValues(alpha: energized ? .88 : .48),
    );
    canvas.drawCircle(
      position,
      energized ? .72 : .55,
      Paint()..color = color.withValues(alpha: energized ? .96 : .58),
    );
  }

  @override
  bool shouldRepaint(covariant _ContinuousPathPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.subject != subject ||
      oldDelegate.segmentIndices != segmentIndices ||
      oldDelegate.completedSignature != completedSignature ||
      oldDelegate.currentIndex != currentIndex ||
      oldDelegate.bandTop != bandTop;
}

class _StudyDock extends StatelessWidget {
  const _StudyDock({
    required this.node,
    required this.studyLabel,
    required this.snapshot,
    required this.missionReady,
    required this.isCurrent,
    required this.onOpen,
  });

  final StudyPathNode node;
  final String studyLabel;
  final StudyTopicSnapshot snapshot;
  final bool missionReady;
  final bool isCurrent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isComplete = snapshot.reflected >= node.questionCount;
    final accessible = MediaQuery.textScalerOf(context).scale(1) >= 1.55;
    final status = isComplete
        ? 'LESSON COMPLETE'
        : isCurrent
        ? 'CURRENT MISSION'
        : 'SELECTED LESSON';
    final visualStatus = accessible
        ? '${isComplete
              ? 'COMPLETE'
              : isCurrent
              ? 'CURRENT'
              : 'SELECTED'} · ${snapshot.reflected} / ${node.questionCount}'
        : status;
    final accent = isComplete
        ? GaussColors.signalBright
        : isCurrent
        ? GaussColors.brassLight
        : GaussColors.brass;
    return KeyedSubtree(
      key: const ValueKey('map-study-dock'),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: Semantics(
          container: true,
          label:
              '$status. $studyLabel. ${node.topic.label}. '
              '${snapshot.reflected} of ${node.questionCount} questions '
              'charted. Lesson ${node.partIndex + 1} of ${node.partCount}.',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _MissionCompassFramePainter(accent: accent),
                  ),
                ),
              ),
              Row(
                key: const ValueKey('map-study-dock-main-row'),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: ExcludeSemantics(
                        child: _StudyDockEmblem(
                          topicKey: node.topic.key,
                          isCurrent: isCurrent,
                          isComplete: isComplete,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DecoratedBox(
                      key: const ValueKey('map-study-dock-copy'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GaussColors.deepInk.withValues(alpha: .9),
                            GaussColors.ink.withValues(alpha: .94),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accent.withValues(alpha: .24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GaussColors.abyss.withValues(alpha: .44),
                            blurRadius: 16,
                            spreadRadius: -7,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: KeyedSubtree(
                        key: const ValueKey('map-study-dock-plaque'),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            accessible ? 9 : 7,
                            12,
                            accessible ? 9 : 7,
                          ),
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent,
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(alpha: .3),
                                            blurRadius: 7,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        visualStatus,
                                        textAlign: TextAlign.center,
                                        softWrap: false,
                                        style: const TextStyle(
                                          color: GaussColors.brassLight,
                                          fontSize: 8.2,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .62,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  studyLabel,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: const TextStyle(
                                    color: GaussColors.ivory,
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                                if (!accessible) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    key: const ValueKey(
                                      'map-study-dock-readings',
                                    ),
                                    children: [
                                      Expanded(
                                        child: _FiveQuestionTrack(
                                          reflected: snapshot.reflected,
                                          complete: isComplete,
                                        ),
                                      ),
                                      if (snapshot.revisit > 0)
                                        const Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            start: 5,
                                          ),
                                          child: Icon(
                                            Icons.bookmark_outline_rounded,
                                            size: 13,
                                            color: GaussColors.signalBright,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: _StudyDockAction(onPressed: onOpen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCompassFramePainter extends CustomPainter {
  const _MissionCompassFramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final rail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = GaussColors.brass.withValues(alpha: .48);
    canvas.drawLine(
      const Offset(26, 0) + Offset(0, y),
      Offset(size.width - 26, y),
      rail,
    );
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3
      ..color = accent.withValues(alpha: .58);
    for (final x in [24.0, size.width - 24]) {
      final rect = Rect.fromCircle(center: Offset(x, y), radius: 25);
      canvas.drawArc(rect, -.85, math.pi * .55, false, orbit);
      canvas.drawArc(rect, math.pi * .72, math.pi * .38, false, orbit);
    }
    canvas.drawCircle(
      Offset(size.width / 2, y),
      1.7,
      Paint()..color = accent.withValues(alpha: .72),
    );
  }

  @override
  bool shouldRepaint(covariant _MissionCompassFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _StudyDockAction extends StatelessWidget {
  const _StudyDockAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OrbitalActionControl(
    key: const ValueKey('map-study-dock-action'),
    semanticLabel: 'Start five-question mission',
    onPressed: onPressed,
    icon: Icons.rocket_launch_rounded,
    dimension: 48,
  );
}

class _FiveQuestionTrack extends StatelessWidget {
  const _FiveQuestionTrack({required this.reflected, required this.complete});

  final int reflected;
  final bool complete;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < GaussStudyCurriculum.batchSize; index++) ...[
        Expanded(
          child: AnimatedContainer(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            height: 4,
            decoration: BoxDecoration(
              color: index < reflected
                  ? GaussColors.signalBright
                  : complete
                  ? GaussColors.brassLight
                  : GaussColors.hairline,
              borderRadius: BorderRadius.circular(GaussRadii.pill),
              boxShadow: index < reflected
                  ? [
                      BoxShadow(
                        color: GaussColors.signalBright.withValues(alpha: .3),
                        blurRadius: 5,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        if (index < GaussStudyCurriculum.batchSize - 1)
          const SizedBox(width: 3),
      ],
      const SizedBox(width: 8),
      Text(
        '$reflected / ${GaussStudyCurriculum.batchSize}',
        softWrap: false,
        style: TextStyle(
          color: complete ? GaussColors.signalBright : GaussColors.ivory,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _StudyDockEmblem extends StatelessWidget {
  const _StudyDockEmblem({
    required this.topicKey,
    required this.isCurrent,
    required this.isComplete,
  });

  final String topicKey;
  final bool isCurrent;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final accent = isComplete
        ? GaussColors.signalBright
        : isCurrent
        ? GaussColors.brassLight
        : GaussColors.brass;
    return Container(
      key: const ValueKey('map-study-dock-emblem'),
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: .2),
            GaussColors.deepInk.withValues(alpha: .98),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: .78), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .18),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCurrent || isComplete)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .42)),
              ),
            ),
          TopicGlyph(topicKey: topicKey, color: accent, size: 21),
        ],
      ),
    );
  }
}

class _StudyInspector extends StatelessWidget {
  const _StudyInspector({
    required this.section,
    required this.node,
    required this.snapshot,
    required this.topicSnapshot,
    required this.missionReady,
    required this.onOpen,
  });

  final StudySectionDefinition section;
  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final StudyTopicSnapshot topicSnapshot;
  final bool missionReady;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.reflected / node.questionCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: _GlassFrame(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
        child: SafeArea(
          left: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'STUDY INSPECTOR',
                style: TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.title,
                style: const TextStyle(color: GaussColors.fog, fontSize: 11),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GaussColors.deepInk,
                      shape: BoxShape.circle,
                      border: Border.all(color: GaussColors.brass),
                    ),
                    child: TopicGlyph(
                      topicKey: node.topic.key,
                      color: GaussColors.brassLight,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UNIT · ${node.setLabel.toUpperCase()}',
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: GaussTypeScale.insignia,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          node.topic.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProgressReading(
                label: 'This study set',
                value: snapshot.reflected,
                total: node.questionCount,
                progress: progress,
              ),
              const SizedBox(height: 12),
              _ProgressReading(
                label: 'Whole unit',
                value: topicSnapshot.reflected,
                total: node.topic.questionCount,
                progress: topicSnapshot.reflected / node.topic.questionCount,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: GaussColors.deepInk.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GaussColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STUDY LENS',
                      style: TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 11),
                    for (final item in _focusAreas(node.topic.key))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: GaussColors.signalBright,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  color: GaussColors.muted,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              if (snapshot.revisit > 0) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_outline_rounded,
                      color: GaussColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${snapshot.revisit} ${snapshot.revisit == 1 ? 'question is' : 'questions are'} waiting for another pass.',
                        style: const TextStyle(
                          color: GaussColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Center(
                child: OrbitalActionControl(
                  key: const ValueKey('map-study-inspector-action'),
                  semanticLabel: 'Start five-question mission',
                  caption: 'START 5',
                  onPressed: onOpen,
                  icon: Icons.rocket_launch_rounded,
                  dimension: 62,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                missionReady
                    ? 'Five questions are ready. Reviewed evidence remains attached where available.'
                    : 'Five source questions are available for private practice. Report anything that needs repair.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressReading extends StatelessWidget {
  const _ProgressReading({
    required this.label,
    required this.value,
    required this.total,
    required this.progress,
  });

  final String label;
  final int value;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: GaussColors.muted, fontSize: 11),
            ),
          ),
          Text(
            '$value / $total',
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 8,
        ),
      ),
    ],
  );
}

class _JumpToCurrentButton extends StatelessWidget {
  const _JumpToCurrentButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Return to current set',
    child: Semantics(
      button: true,
      label: 'Return to the next uncharted study set',
      child: _GlassFrame(
        radius: GaussRadii.pill,
        padding: EdgeInsets.zero,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.my_location_rounded),
          color: GaussColors.brassLight,
        ),
      ),
    ),
  );
}

class _GlassFrame extends StatelessWidget {
  const _GlassFrame({
    required this.child,
    required this.padding,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF20A171C), Color(0xF50D2025)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: GaussColors.brass.withValues(alpha: .28)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x8A000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(9077);
    for (var index = 0; index < 150; index++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final bright = random.nextDouble() > .88;
      canvas.drawCircle(
        center,
        bright ? 1.15 : .55,
        Paint()
          ..color = (bright ? GaussColors.brassLight : GaussColors.ice)
              .withValues(alpha: bright ? .45 : .22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

List<String> _focusAreas(String key) {
  if (key.contains('function') || key.contains('derivative')) {
    return const [
      'Read structure from equations and graphs',
      'Choose a rigorous line of attack',
      'Check edge cases before committing',
    ];
  }
  if (key.contains('geometry') || key.contains('trigonometry')) {
    return const [
      'Translate diagrams into exact relationships',
      'Select the decisive theorem',
      'Verify every construction step',
    ];
  }
  if (key.contains('probability') || key.contains('statistics')) {
    return const [
      'Define the sample space precisely',
      'Separate signal from distracting data',
      'Test whether the result is plausible',
    ];
  }
  if (key.contains('electric') || key.contains('magnet')) {
    return const [
      'Map physical quantities to a model',
      'Track direction, sign, and units',
      'Validate the model against the scenario',
    ];
  }
  if (key.contains('motion') || key.contains('dynamic')) {
    return const [
      'Choose a useful frame of reference',
      'Connect motion diagrams and equations',
      'Check signs, units, and limiting cases',
    ];
  }
  return const [
    'Recognize the governing structure',
    'Build a clear chain of reasoning',
    'Check the conclusion independently',
  ];
}

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
