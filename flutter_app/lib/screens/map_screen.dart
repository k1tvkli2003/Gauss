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
import '../widgets/gauss_state_panel.dart';
import '../widgets/map_gamification_hud.dart';
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
              final window = GaussWindowClass.fromWidth(
                math.max(mediaWidth, constraints.maxWidth),
              );
              final showInspector = window.showsPersistentInspector;
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final accessibleDock = textScale >= 1.55;
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
              final dockReservedHeight = accessibleDock ? 128.0 : 96.0;
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
        cacheWidth: 1400,
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
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
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
              height: compact ? 108 : 116,
              child: Column(
                children: [
                  SizedBox(
                    // Preserve the wordmark's 3:1 intrinsic ratio. The former
                    // 24dp slot forced an 88dp mark into a 24dp box, so its
                    // transparent top/bottom breathing room made the actual
                    // letters look absent on Android despite valid semantics.
                    height: compact ? 27 : 36,
                    child: Center(
                      child: GaussWordmark(
                        key: ValueKey(
                          compact
                              ? 'map-compact-centered-wordmark'
                              : 'map-wide-centered-wordmark',
                        ),
                        width: compact ? 78 : 104,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 1 : 4),
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
                          tight: tightPhone,
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
            const SizedBox(height: 10),
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
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: .9,
          widthFactor: 1,
          child: navigatorFor(sheetContext),
        ),
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
            constraints: const BoxConstraints(maxWidth: 540),
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
    final ringSize = tight ? 44.0 : 48.0;
    return Semantics(
      container: true,
      label: '$reflected of $total course questions charted.',
      child: ExcludeSemantics(
        child: SizedBox(
          width: tight ? 72 : 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: ringSize,
                child: CustomPaint(
                  painter: _MapCourseProgressPainter(progress: progress),
                  child: Center(
                    child: TheoremStarMark(
                      size: tight ? 27 : 29,
                      semanticLabel: null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
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
          const SizedBox(height: 1),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 1,
            children: [
              for (final word in activeTopic.label.split(' '))
                Text(
                  word,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: GaussColors.ivory,
                    fontSize: compact ? 11 : 12,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
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
        const SizedBox(height: 3),
        orbitTitle,
        const SizedBox(height: 5),
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
            reflowCompact ? 6 : 8,
            8,
            reflowCompact ? 6 : 8,
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
  final Map<String, GlobalKey> _chapterKeys = {};

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
    _revealSelected();
  }

  void _selectSection(StudySectionDefinition section) {
    if (_sectionId == section.id) return;
    setState(() => _sectionId = section.id);
    _revealSelected();
  }

  void _moveSection(int delta) {
    final current = _sections.indexWhere((item) => item.id == _section.id);
    final target = (current + delta).clamp(0, _sections.length - 1);
    if (target == current) return;
    _selectSection(_sections[target]);
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _chapterKeys[_sectionId]?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: GaussMotion.resolve(context, GaussMotion.standard),
        curve: Curves.easeOutCubic,
        alignment: .18,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final selectedIndex = sections.indexWhere((item) => item.id == _section.id);
    return KeyedSubtree(
      key: const ValueKey('orbit-navigator'),
      child: _GlassFrame(
        radius: 28,
        padding: EdgeInsets.zero,
        backgroundColor: GaussColors.ink,
        child: Material(
          color: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largeText =
                  MediaQuery.textScalerOf(context).scale(1) >= 1.55;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      12,
                      10,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: GaussColors.fog.withValues(alpha: .44),
                              borderRadius: BorderRadius.circular(
                                GaussRadii.pill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: GaussSpacing.space8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ORBIT NAVIGATOR',
                                    softWrap: false,
                                    style: TextStyle(
                                      color: GaussColors.brassLight,
                                      fontSize: GaussTypeScale.insignia,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.05,
                                    ),
                                  ),
                                  SizedBox(height: GaussSpacing.space4),
                                  Text(
                                    'Choose a chapter. Continue at the next real session.',
                                    style: TextStyle(
                                      color: GaussColors.muted,
                                      fontSize: GaussTypeScale.caption,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: GaussSpacing.space8),
                            IconButton(
                              key: const ValueKey('orbit-navigator-close'),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Close Orbit Navigator',
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: GaussSpacing.space12),
                        _OrbitCourseSwitch(
                          subject: _subject,
                          onSubject: _selectSubject,
                        ),
                        const SizedBox(height: GaussSpacing.space12),
                        Row(
                          children: [
                            IconButton(
                              key: const ValueKey('orbit-navigator-previous'),
                              onPressed: selectedIndex > 0
                                  ? () => _moveSection(-1)
                                  : null,
                              tooltip: 'Previous chapter',
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'CHAPTER ${selectedIndex + 1} OF ${sections.length}',
                                textAlign: TextAlign.center,
                                softWrap: false,
                                style: const TextStyle(
                                  color: GaussColors.ivory,
                                  fontSize: GaussTypeScale.metadata,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('orbit-navigator-next'),
                              onPressed: selectedIndex < sections.length - 1
                                  ? () => _moveSection(1)
                                  : null,
                              tooltip: 'Next chapter',
                              icon: const Icon(Icons.arrow_forward_ios_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GaussSpacing.space8),
                  Expanded(
                    child: ListView.builder(
                      key: const ValueKey('orbit-navigator-chapter-list'),
                      padding: EdgeInsetsDirectional.fromSTEB(
                        largeText ? 10 : 14,
                        0,
                        largeText ? 10 : 14,
                        18,
                      ),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final item = sections[index];
                        return KeyedSubtree(
                          key: _chapterKeys.putIfAbsent(
                            item.id,
                            () => GlobalKey(),
                          ),
                          child: _OrbitChapterStop(
                            controller: widget.controller,
                            section: item,
                            index: index,
                            isFirst: index == 0,
                            isLast: index == sections.length - 1,
                            selected: item.id == _section.id,
                            onSelected: () => _selectSection(item),
                            onContinue: () => widget.onContinue(_subject, item),
                          ),
                        );
                      },
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
}

class _OrbitCourseSwitch extends StatelessWidget {
  const _OrbitCourseSwitch({required this.subject, required this.onSubject});

  final Subject subject;
  final ValueChanged<Subject> onSubject;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('orbit-navigator-course-switch'),
    padding: const EdgeInsets.all(GaussSpacing.space4),
    decoration: BoxDecoration(
      color: GaussColors.abyss.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Row(
      children: [
        for (final item in Subject.values)
          Expanded(
            child: _OrbitCourseButton(
              key: ValueKey('orbit-navigator-${item.name}'),
              subject: item,
              selected: subject == item,
              onPressed: () => onSubject(item),
            ),
          ),
      ],
    ),
  );
}

class _OrbitCourseButton extends StatelessWidget {
  const _OrbitCourseButton({
    required this.subject,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final Subject subject;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = subject == Subject.math ? 'Math' : 'Physics';
    return Semantics(
      button: true,
      selected: selected,
      label: '$label course',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        child: AnimatedContainer(
          duration: GaussMotion.resolve(context, GaussMotion.micro),
          constraints: const BoxConstraints(
            minHeight: GaussMetrics.minTouchTarget,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: GaussSpacing.space8),
          decoration: BoxDecoration(
            color: selected
                ? GaussColors.brass.withValues(alpha: .2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(GaussRadii.pill),
            border: Border.all(
              color: selected ? GaussColors.brass : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            softWrap: false,
            style: TextStyle(
              color: selected ? GaussColors.brassLight : GaussColors.muted,
              fontSize: GaussTypeScale.metadata,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitChapterStop extends StatelessWidget {
  const _OrbitChapterStop({
    required this.controller,
    required this.section,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.selected,
    required this.onSelected,
    required this.onContinue,
  });

  final GaussController controller;
  final StudySectionDefinition section;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool selected;
  final VoidCallback onSelected;
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
    return CustomPaint(
      key: ValueKey('orbit-chapter-${section.id}'),
      painter: _OrbitChapterRailPainter(
        isFirst: isFirst,
        isLast: isLast,
        selected: selected,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: GaussSpacing.space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: GaussSpacing.space12),
                child: _OrbitIndexRing(value: index + 1),
              ),
            ),
            const SizedBox(width: GaussSpacing.space8),
            Expanded(
              child: Semantics(
                container: true,
                button: !selected,
                selected: selected,
                label:
                    'Chapter ${index + 1}. ${section.title}. $reflected of $total charted. Current session ${currentIndex + 1} of ${nodes.length}.',
                child: InkWell(
                  onTap: selected ? null : onSelected,
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: GaussMotion.resolve(
                      context,
                      GaussMotion.standard,
                    ),
                    constraints: const BoxConstraints(minHeight: 76),
                    padding: const EdgeInsets.all(GaussSpacing.space12),
                    decoration: BoxDecoration(
                      color: selected
                          ? GaussColors.brass.withValues(alpha: .13)
                          : GaussColors.deepInk.withValues(alpha: .32),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? GaussColors.brass.withValues(alpha: .72)
                            : GaussColors.hairline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: GaussColors.ivory,
                            fontSize: GaussTypeScale.body,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: GaussSpacing.space4),
                        Text(
                          section.subtitle,
                          style: const TextStyle(
                            color: GaussColors.muted,
                            fontSize: GaussTypeScale.caption,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: GaussSpacing.space8),
                        Wrap(
                          spacing: GaussSpacing.space8,
                          runSpacing: GaussSpacing.space4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              '$reflected / $total charted',
                              softWrap: false,
                              style: const TextStyle(
                                color: GaussColors.signalBright,
                                fontSize: GaussTypeScale.metadata,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'SESSION ${currentIndex + 1} / ${nodes.length}',
                              softWrap: false,
                              style: const TextStyle(
                                color: GaussColors.brassLight,
                                fontSize: GaussTypeScale.insignia,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: GaussSpacing.space8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(GaussRadii.pill),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: GaussColors.abyss.withValues(
                              alpha: .78,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(height: GaussSpacing.space12),
                          Wrap(
                            spacing: GaussSpacing.space8,
                            runSpacing: GaussSpacing.space8,
                            children: [
                              _NavigatorMetric(
                                label: 'NEXT SESSION',
                                value:
                                    '${currentSnapshot.reflected} / ${currentNode.questionCount}',
                              ),
                              _NavigatorMetric(
                                label: 'TOPIC',
                                value: currentNode.topic.label,
                                rtlValue: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: GaussSpacing.space12),
                          FilledButton.icon(
                            key: const ValueKey('orbit-navigator-continue'),
                            onPressed: onContinue,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            icon: const Icon(Icons.explore_rounded),
                            label: const Text('Continue here'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigatorMetric extends StatelessWidget {
  const _NavigatorMetric({
    required this.label,
    required this.value,
    this.rtlValue = false,
  });

  final String label;
  final String value;
  final bool rtlValue;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 32),
    padding: const EdgeInsets.symmetric(
      horizontal: GaussSpacing.space8,
      vertical: GaussSpacing.space4,
    ),
    decoration: BoxDecoration(
      color: GaussColors.abyss.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          softWrap: false,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: GaussTypeScale.insignia,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Directionality(
          textDirection: rtlValue ? TextDirection.rtl : TextDirection.ltr,
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: GaussTypeScale.metadata,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrbitChapterRailPainter extends CustomPainter {
  const _OrbitChapterRailPainter({
    required this.isFirst,
    required this.isLast,
    required this.selected,
  });

  final bool isFirst;
  final bool isLast;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    const x = 24.0;
    const ringCenter = 32.0;
    final paint = Paint()
      ..color = (selected ? GaussColors.brass : GaussColors.hairline)
          .withValues(alpha: selected ? .7 : .82)
      ..strokeWidth = selected ? 2 : 1.2
      ..strokeCap = StrokeCap.round;
    if (!isFirst) {
      canvas.drawLine(
        const Offset(x, 0),
        const Offset(x, ringCenter - 20),
        paint,
      );
    }
    if (!isLast) {
      canvas.drawLine(
        const Offset(x, ringCenter + 20),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitChapterRailPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.selected != selected;
}

class _SubjectSwitch extends StatelessWidget {
  const _SubjectSwitch({
    required this.subject,
    required this.onSubject,
    required this.compact,
  });

  final Subject subject;
  final ValueChanged<Subject> onSubject;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mathSelected = subject == Subject.math;
    return Semantics(
      container: true,
      label: 'Study path subject',
      child: SizedBox(
        key: const ValueKey('map-subject-dual-orbit'),
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
  List<double> _nodeY = const [];
  int _landmarkWindow = 0;
  int _controlWindowEnd = -1;
  String? _positionedSectionId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_refreshLandmarkWindow);
  }

  @override
  void didUpdateWidget(covariant _StudyPathStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) {
      // The next layout owns the new route geometry. Let build schedule one
      // exact camera placement after those coordinates exist instead of
      // blindly resetting to offset zero and visually disagreeing with the
      // restored/selected learning topic.
      _positionedSectionId = null;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_refreshLandmarkWindow);
    _scrollController.dispose();
    super.dispose();
  }

  /// Keep the full route geometry alive, but defer the expensive decorative
  /// landmark rasters until they are near the visible scroll window. The
  /// buffer avoids visible pop-in while preventing distant map art from
  /// competing with the first useful frame and its local question data.
  void _refreshLandmarkWindow() {
    if (!_scrollController.hasClients) return;
    final nextWindow = (_scrollController.offset / 220).floor();
    final safeBottom =
        _scrollController.offset +
        _scrollController.position.viewportDimension -
        widget.bottomObstruction -
        52;
    final nextControlEnd = _nodeY.lastIndexWhere((y) => y <= safeBottom);
    if (nextWindow == _landmarkWindow && nextControlEnd == _controlWindowEnd) {
      return;
    }
    setState(() {
      _landmarkWindow = nextWindow;
      _controlWindowEnd = nextControlEnd;
    });
  }

  bool _isLandmarkNearViewport(
    _LandmarkGeometry landmark,
    double viewportHeight,
  ) {
    final top = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final buffer = math.min(160.0, viewportHeight * .24);
    return landmark.top + landmark.size >= top - buffer &&
        landmark.top <= top + viewportHeight + buffer;
  }

  /// A five-question route can contain hundreds of real sessions. Keep its
  /// geometry deterministic, but materialize only the instruments and labels
  /// near the visible scroll window. The long path remains continuous without
  /// making every distant session part of the first-frame widget cost.
  bool _isNodeNearViewport(
    Offset position,
    double viewportHeight,
    double nodeSize,
  ) {
    final top = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final buffer = math.max(360.0, viewportHeight * .85);
    return position.dy + nodeSize >= top - buffer &&
        position.dy - nodeSize <= top + viewportHeight + buffer;
  }

  /// Keep live instruments and their labels wholly above the floating mission
  /// controls while allowing the route painter and astronomical stage to run
  /// continuously behind the glass. This avoids both a dead footer band and
  /// half-visible/tappable lesson nodes.
  bool _isNodeClearOfOverlay(
    Offset position,
    double viewportHeight,
    double nodeSize,
  ) {
    if (widget.bottomObstruction <= 0) return true;
    final top = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final safeBottom = top + viewportHeight - widget.bottomObstruction;
    // 52dp covers the clamped two-tier phone label while keeping the opening
    // lesson visible in the 320dp / 200% text stress layout.
    final nodeAndLabelExtent = math.max(nodeSize / 2, 52.0);
    return position.dy + nodeAndLabelExtent <= safeBottom;
  }

  void _positionNode(int index, {required bool animate}) {
    if (!_scrollController.hasClients || _nodeY.isEmpty) return;
    final safe = index.clamp(0, _nodeY.length - 1);
    final visibleHeight = math.max(
      160.0,
      _scrollController.position.viewportDimension - widget.bottomObstruction,
    );
    final target = (_nodeY[safe] - visibleHeight / 2).clamp(
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
      final geometry = _PathGeometry.build(
        width: constraints.maxWidth,
        nodes: widget.nodes,
        textScale: MediaQuery.textScalerOf(context).scale(1),
      );
      final visibleTop = _scrollController.hasClients
          ? _scrollController.offset
          : 0.0;
      _nodeY = geometry.positions.map((position) => position.dy).toList();
      if (_positionedSectionId != widget.section.id) {
        _positionedSectionId = widget.section.id;
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
      return SingleChildScrollView(
        key: const ValueKey('map-study-path-scroll'),
        controller: _scrollController,
        padding: EdgeInsets.only(
          bottom: widget.bottomObstruction + GaussSpacing.space32,
        ),
        child: SizedBox(
          width: constraints.maxWidth,
          height: geometry.height,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _StageInstrumentPainter(
                      current: geometry.positions[widget.currentIndex],
                      nodeSize: geometry.nodeSize,
                      visibleTop: visibleTop,
                      visibleHeight: constraints.maxHeight,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ContinuousPathPainter(
                    positions: geometry.positions,
                    completed: [
                      for (final node in widget.nodes)
                        widget.controller.study.shelf(node.key).reflected >=
                            node.questionCount,
                    ],
                    currentIndex: widget.currentIndex,
                    visibleTop: visibleTop,
                    visibleHeight: constraints.maxHeight,
                  ),
                ),
              ),
              for (final landmark in geometry.landmarks)
                if (_isLandmarkNearViewport(landmark, constraints.maxHeight))
                  _PathLandmark(landmark: landmark),
              for (final header in geometry.unitHeaders)
                Positioned(
                  key: ValueKey('map-section-gate-${header.unitNumber}'),
                  left: 12,
                  right: 12,
                  top: header.y,
                  child: _SectionGate(
                    topic: header.topic,
                    unitNumber: header.unitNumber,
                    reflected: widget.controller.study
                        .topic(header.topic.key)
                        .reflected,
                  ),
                ),
              for (var index = 0; index < widget.nodes.length; index++)
                if (_isNodeNearViewport(
                      geometry.positions[index],
                      constraints.maxHeight,
                      geometry.nodeSize,
                    ) &&
                    _isNodeClearOfOverlay(
                      geometry.positions[index],
                      constraints.maxHeight,
                      geometry.nodeSize,
                    ))
                  Positioned(
                    left: geometry.positions[index].dx - geometry.nodeSize / 2,
                    top: geometry.positions[index].dy - geometry.nodeSize / 2,
                    child: _StudyNode(
                      node: widget.nodes[index],
                      studyLabel: widget.controller.studySetLabel(
                        widget.nodes[index],
                      ),
                      size: geometry.nodeSize,
                      snapshot: widget.controller.study.shelf(
                        widget.nodes[index].key,
                      ),
                      current: index == widget.currentIndex,
                      selected: widget.nodes[index].key == widget.selectedKey,
                      onPressed: () => widget.onSelected(widget.nodes[index]),
                    ),
                  ),
              for (var index = 0; index < widget.nodes.length; index++)
                if (_isNodeNearViewport(
                      geometry.positions[index],
                      constraints.maxHeight,
                      geometry.nodeSize,
                    ) &&
                    _isNodeClearOfOverlay(
                      geometry.positions[index],
                      constraints.maxHeight,
                      geometry.nodeSize,
                    ))
                  _PathNodeLabel(
                    node: widget.nodes[index],
                    studyLabel: widget.controller.studySetLabel(
                      widget.nodes[index],
                    ),
                    snapshot: widget.controller.study.shelf(
                      widget.nodes[index].key,
                    ),
                    position: geometry.positions[index],
                    nodeSize: geometry.nodeSize,
                    stageWidth: constraints.maxWidth,
                    isCurrent: index == widget.currentIndex,
                    selected: widget.nodes[index].key == widget.selectedKey,
                  ),
            ],
          ),
        ),
      );
    },
  );
}

class _PathGeometry {
  const _PathGeometry({
    required this.positions,
    required this.unitHeaders,
    required this.landmarks,
    required this.nodeSize,
    required this.height,
  });

  final List<Offset> positions;
  final List<_UnitHeaderGeometry> unitHeaders;
  final List<_LandmarkGeometry> landmarks;
  final double nodeSize;
  final double height;

  static _PathGeometry build({
    required double width,
    required List<StudyPathNode> nodes,
    required double textScale,
  }) {
    final compact = width < 560;
    final expanded = width >= 760;
    final scale = textScale.clamp(1.0, 2.0).toDouble();
    final nodeSize = compact
        ? 72.0
        : expanded
        ? 108.0
        : 96.0;
    final center = width / 2;
    final amplitude = math.min(
      width *
          (compact
              ? .25
              : expanded
              ? .34
              : .31),
      expanded ? 270.0 : 225.0,
    );
    final positions = <Offset>[];
    final headers = <_UnitHeaderGeometry>[];
    final landmarks = <_LandmarkGeometry>[];
    // Every curriculum unit has a real visual threshold.  A route is easier
    // to read as one continuous expedition when a small celestial gate
    // announces the conceptual shift before the next constellation begins.
    // This reserve grows with text instead of letting live Persian labels
    // collide with the first instrument at accessibility sizes.
    // Keep the opening instrument visually clear of the floating mission dock
    // on the shortest supported phone while still letting the route rail
    // continue beneath the glass. The two-pixel top allowance is deliberate:
    // the 72dp control remains fully visible and its aura may softly crop.
    var y = compact ? 38.0 : 28.0;
    var unitNumber = 0;
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      if (node.beginsUnit) {
        unitNumber++;
        // On phones, Chapter 1 is already live inside the Orbit selector.
        // Omitting that duplicated gate gives the actual route first-frame
        // priority while later chapter thresholds remain explicit landmarks.
        final chapterLivesInSelector = compact && index == 0;
        if (!chapterLivesInSelector) {
          y += index == 0
              ? 10
              : compact
              ? 62 + 18 * (scale - 1)
              : 96 + 22 * (scale - 1);
          final accessibilityCompact = compact && scale >= 1.55;
          final gateHeight = compact
              ? accessibilityCompact
                    // The live 200% chapter identity is three stacked rows
                    // (index/name, title, progress). Its geometry must reserve
                    // the same physical space that _SectionGate paints; a
                    // 90dp shortcut allowed the following lesson node to be
                    // laid out inside the gate on real Android.
                    ? 174.0
                    : 98 + 20 * (scale - 1)
              : 82 + 28 * (scale - 1);
          headers.add(
            _UnitHeaderGeometry(
              topic: node.topic,
              unitNumber: unitNumber,
              y: y,
            ),
          );
          y +=
              gateHeight +
              (compact
                  ? accessibilityCompact
                        ? 14
                        : 44 - 6 * (scale - 1)
                  : 52);
        }
      }
      final phase = index * 1.2 + unitNumber * .5;
      final x = center + math.sin(phase) * amplitude;
      positions.add(Offset(x, y));
      final openingLandmark = index == 0;
      final intervalLandmark = index > 2 && index % 6 == 4;
      if (openingLandmark || intervalLandmark) {
        final placeStart = x >= center;
        final edge = compact
            ? 4.0
            : expanded
            ? 22.0
            : 12.0;
        final landmarkSize = openingLandmark
            ? compact
                  ? 128.0
                  : expanded
                  ? 210.0
                  : 168.0
            : compact
            ? 104.0
            : expanded
            ? 176.0
            : 146.0;
        landmarks.add(
          _LandmarkGeometry(
            top: openingLandmark
                ? y + (compact ? 20 : -4)
                : y - (compact ? 36 : 50),
            start: placeStart ? edge : null,
            end: placeStart ? null : edge,
            size: landmarkSize,
            kind: openingLandmark ? 0 : 1 + (index ~/ 6) % 2,
          ),
        );
      }
      y += compact
          ? 96 + 32 * (scale - 1)
          : expanded
          ? 154
          : 146;
    }
    return _PathGeometry(
      positions: positions,
      unitHeaders: headers,
      landmarks: landmarks,
      nodeSize: nodeSize,
      height: y + 150,
    );
  }
}

class _UnitHeaderGeometry {
  const _UnitHeaderGeometry({
    required this.topic,
    required this.unitNumber,
    required this.y,
  });

  final TopicDescriptor topic;
  final int unitNumber;
  final double y;
}

class _LandmarkGeometry {
  const _LandmarkGeometry({
    required this.top,
    required this.start,
    required this.end,
    required this.size,
    required this.kind,
  });

  final double top;
  final double? start;
  final double? end;
  final double size;
  final int kind;
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

      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: accessibilityCompact ? 1.45 : 1.75,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Semantics(
              container: true,
              label:
                  'Chapter $unitNumber. ${topic.label}. $reflected of ${topic.questionCount} questions charted.',
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GaussColors.deepInk.withValues(alpha: .94),
                      GaussColors.abyss.withValues(alpha: .82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: GaussColors.brass.withValues(alpha: .42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GaussColors.abyss.withValues(alpha: .44),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
  const _PathLandmark({required this.landmark});

  final _LandmarkGeometry landmark;

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
      top: landmark.top,
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
                    cacheWidth: 640,
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
    required this.visibleTop,
    required this.visibleHeight,
  });

  final Offset current;
  final double nodeSize;
  final double visibleTop;
  final double visibleHeight;

  @override
  void paint(Canvas canvas, Size size) {
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
        .max(330.0, ((visibleTop - 380) / 720).floor() * 720 + 330)
        .toDouble();
    final lastCenter = math
        .min(size.height + 300, visibleTop + visibleHeight + 380)
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
  }

  @override
  bool shouldRepaint(covariant _StageInstrumentPainter oldDelegate) =>
      oldDelegate.current != current ||
      oldDelegate.nodeSize != nodeSize ||
      oldDelegate.visibleTop != visibleTop ||
      oldDelegate.visibleHeight != visibleHeight;
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
    final width = math.min(
      compact
          ? largeText
                ? 146.0
                : emphasized
                ? 132.0
                : 124.0
          : 156.0,
      math.max(compact ? 112.0 : 126.0, stageWidth * (compact ? .4 : .27)),
    );
    final rightPreferred =
        position.dx + nodeSize * .58 + width <= stageWidth - 6;
    final left = rightPreferred
        ? position.dx + nodeSize * .58
        : math.max(6.0, position.dx - nodeSize * .58 - width);
    final anchor = Container(
      width: emphasized ? 6 : 4,
      height: emphasized ? 6 : 4,
      decoration: BoxDecoration(
        color: emphasized
            ? GaussColors.signalBright
            : GaussColors.brassLight.withValues(alpha: .66),
        shape: BoxShape.circle,
      ),
    );
    return Positioned(
      key: ValueKey('map-node-label-${node.key}'),
      left: left,
      top: position.dy - (compact ? 22 : 30),
      width: width,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            opacity: emphasized ? 1 : .86,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.35,
              child: AnimatedContainer(
                duration: GaussMotion.resolve(context, GaussMotion.micro),
                curve: Curves.easeOutCubic,
                padding: EdgeInsetsDirectional.fromSTEB(
                  emphasized ? 7 : 4,
                  emphasized ? 5 : 3,
                  emphasized ? 7 : 4,
                  emphasized ? 5 : 3,
                ),
                decoration: BoxDecoration(
                  color: GaussColors.deepInk.withValues(
                    alpha: emphasized ? .64 : .16,
                  ),
                  borderRadius: BorderRadius.circular(emphasized ? 14 : 10),
                  border: Border.all(
                    color:
                        (emphasized
                                ? GaussColors.signalBright
                                : GaussColors.brass)
                            .withValues(alpha: emphasized ? .3 : .045),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (rightPreferred) ...[
                      anchor,
                      const SizedBox(width: GaussSpacing.space8),
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
                                  : GaussColors.fog,
                              fontSize: compact ? (emphasized ? 10.5 : 10) : 13,
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
                            '${snapshot.reflected} / ${node.questionCount} CHARTED',
                            textAlign: rightPreferred
                                ? TextAlign.start
                                : TextAlign.end,
                            softWrap: true,
                            style: TextStyle(
                              color: emphasized
                                  ? GaussColors.signalBright
                                  : GaussColors.signal.withValues(alpha: .86),
                              fontSize: compact ? 8.5 : GaussTypeScale.insignia,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!rightPreferred) ...[
                      const SizedBox(width: GaussSpacing.space8),
                      anchor,
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

class _StudyNode extends StatelessWidget {
  const _StudyNode({
    required this.node,
    required this.studyLabel,
    required this.size,
    required this.snapshot,
    required this.current,
    required this.selected,
    required this.onPressed,
  });

  final StudyPathNode node;
  final String studyLabel;
  final double size;
  final StudyTopicSnapshot snapshot;
  final bool current;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final progress = (snapshot.reflected / node.questionCount).clamp(0.0, 1.0);
    final complete = snapshot.reflected >= node.questionCount;
    final accent = complete
        ? GaussColors.signalBright
        : current || selected
        ? GaussColors.brassLight
        : node.topic.subject == Subject.math
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
          scale: selected ? 1.09 : 1,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (current || selected)
                  CustomPaint(
                    size: Size.square(size * 1.18),
                    painter: _CurrentNodeAuraPainter(
                      accent: accent,
                      selected: selected,
                    ),
                  ),
                Image.asset(
                  'assets/visual/nodes/topic_shell.png',
                  width: size * .96,
                  height: size * .96,
                  cacheWidth: 360,
                  filterQuality: FilterQuality.medium,
                ),
                CustomPaint(
                  size: Size.square(size * .88),
                  painter: _NodeProgressPainter(
                    color: accent,
                    progress: progress,
                    emphasized: current || selected,
                  ),
                ),
                _NodeGlyphCore(
                  topicKey: node.topic.key,
                  accent: accent,
                  emphasized: current || selected,
                  nodeSize: size,
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
                    child: _NodeStatePin(color: GaussColors.signalBright),
                  )
                else if (snapshot.revisit > 0)
                  const PositionedDirectional(
                    start: 2,
                    bottom: 3,
                    child: _NodeStatePin(color: GaussColors.warning),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The topic mark belongs in a mounted instrument core, not directly on top
/// of the textured shell.  The shallow glass/lens makes every vector glyph
/// read as a deliberate part of the node at phone scale.
class _NodeGlyphCore extends StatelessWidget {
  const _NodeGlyphCore({
    required this.topicKey,
    required this.accent,
    required this.emphasized,
    required this.nodeSize,
  });

  final String topicKey;
  final Color accent;
  final bool emphasized;
  final double nodeSize;

  @override
  Widget build(BuildContext context) {
    final coreSize = (nodeSize * (emphasized ? .42 : .38))
        .clamp(28.0, 38.0)
        .toDouble();
    return Container(
      width: coreSize,
      height: coreSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: emphasized ? .28 : .2),
            GaussColors.deepInk.withValues(alpha: .98),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: .72), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: emphasized ? .23 : .12),
            blurRadius: emphasized ? 10 : 7,
          ),
        ],
      ),
      child: TopicGlyph(
        topicKey: topicKey,
        color: accent,
        size: coreSize * .52,
      ),
    );
  }
}

class _NodeProgressPainter extends CustomPainter {
  const _NodeProgressPainter({
    required this.color,
    required this.progress,
    required this.emphasized,
  });

  final Color color;
  final double progress;
  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(2),
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = emphasized ? 2.2 : 1.2
        ..color = color.withValues(alpha: emphasized ? .62 : .2),
    );
    if (progress > 0) {
      canvas.drawArc(
        rect.deflate(2),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.2
          ..color = GaussColors.signalBright,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NodeProgressPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.emphasized != emphasized;
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
    final glow = Paint()
      ..color = accent.withValues(alpha: selected ? .2 : .15)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    canvas.drawCircle(center, size.width * .34, glow);
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

class _NodeStatePin extends StatelessWidget {
  const _NodeStatePin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 11,
    height: 11,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: GaussColors.deepInk,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 1.5),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .35), blurRadius: 6),
      ],
    ),
    child: Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}

class _ContinuousPathPainter extends CustomPainter {
  const _ContinuousPathPainter({
    required this.positions,
    required this.completed,
    required this.currentIndex,
    required this.visibleTop,
    required this.visibleHeight,
  });

  final List<Offset> positions;
  final List<bool> completed;
  final int currentIndex;
  final double visibleTop;
  final double visibleHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;
    final paintTop = visibleTop - 300;
    final paintBottom = visibleTop + visibleHeight + 300;
    for (var index = 0; index < positions.length - 1; index++) {
      final isComplete = completed[index];
      final isCurrentLead = index == currentIndex;
      final segment = _segment(positions[index], positions[index + 1]);
      final bounds = Rect.fromPoints(
        positions[index],
        positions[index + 1],
      ).inflate(18);
      if (bounds.bottom < paintTop || bounds.top > paintBottom) continue;
      final metric = segment.computeMetrics().single;

      // The route is an inlaid celestial rail: a deep shadow makes it sit in
      // the sky, the thin brass line keeps future travel legible, and active
      // segments receive a restrained energy current rather than a flat line.
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xD803090B),
      );
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round
          ..color = GaussColors.brass.withValues(alpha: .48),
      );

      if (isComplete || isCurrentLead) {
        final accent = isCurrentLead
            ? GaussColors.brassLight
            : GaussColors.signalBright;
        if (isCurrentLead || index >= currentIndex - 2) {
          canvas.drawPath(
            segment,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = isCurrentLead ? 13 : 8
              ..strokeCap = StrokeCap.round
              ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8)
              ..color = accent.withValues(alpha: isCurrentLead ? .22 : .12),
          );
        }
        canvas.drawPath(
          segment,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isCurrentLead ? 4 : 3
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: .38),
                accent.withValues(alpha: .94),
                accent.withValues(alpha: .48),
              ],
            ).createShader(bounds),
        );
      } else {
        _drawFutureDashes(canvas, metric);
      }

      if (isCurrentLead) {
        for (var marker = 1; marker <= 3; marker++) {
          final tangent = metric.getTangentForOffset(
            metric.length * marker / 4,
          );
          if (tangent == null) continue;
          canvas.drawCircle(
            tangent.position,
            2.2,
            Paint()
              ..color = GaussColors.brassLight.withValues(alpha: .88)
              ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1),
          );
        }
      }
    }
  }

  Path _segment(Offset start, Offset end) {
    final middleY = (start.dy + end.dy) / 2;
    final bend = (end.dx - start.dx) * .24;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + bend,
        middleY,
        end.dx - bend,
        middleY,
        end.dx,
        end.dy,
      );
  }

  void _drawFutureDashes(Canvas canvas, ui.PathMetric metric) {
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.brassLight.withValues(alpha: .46);
    for (var distance = 9.0; distance < metric.length; distance += 14) {
      canvas.drawPath(
        metric.extractPath(distance, math.min(distance + 3.2, metric.length)),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContinuousPathPainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.completed != completed ||
      oldDelegate.currentIndex != currentIndex ||
      oldDelegate.visibleTop != visibleTop ||
      oldDelegate.visibleHeight != visibleHeight;
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
    return LayoutBuilder(
      builder: (context, _) {
        Widget emblem() => ExcludeSemantics(
          child: _StudyDockEmblem(
            topicKey: node.topic.key,
            isCurrent: isCurrent,
            isComplete: isComplete,
          ),
        );

        Widget copy() => ClipRRect(
          key: const ValueKey('map-study-dock-copy'),
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: DecoratedBox(
              key: const ValueKey('map-study-dock-plaque'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GaussColors.deepInk.withValues(alpha: .48),
                    GaussColors.ink.withValues(alpha: .62),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: GaussColors.brassLight.withValues(alpha: .2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Wrap(
                        spacing: GaussSpacing.space8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isComplete
                                  ? GaussColors.signalBright
                                  : isCurrent
                                  ? GaussColors.brassLight
                                  : GaussColors.fog,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isComplete
                                              ? GaussColors.signalBright
                                              : GaussColors.brassLight)
                                          .withValues(alpha: .3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            visualStatus,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GaussColors.brassLight,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .72,
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                      if (!accessible) ...[
                        const SizedBox(height: 2),
                        Text(
                          node.topic.label,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
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

        Widget readings() => ExcludeSemantics(
          child: Align(
            alignment: Alignment.center,
            child: Row(
              key: const ValueKey('map-study-dock-readings'),
              children: [
                Expanded(
                  child: _FiveQuestionTrack(
                    reflected: snapshot.reflected,
                    complete: isComplete,
                  ),
                ),
                const SizedBox(width: GaussSpacing.space8),
                Text(
                  'LESSON ${node.partIndex + 1} OF ${node.partCount}',
                  softWrap: false,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .45,
                  ),
                ),
                if (snapshot.revisit > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Icon(
                      Icons.bookmark_outline_rounded,
                      size: 16,
                      color: GaussColors.signalBright,
                    ),
                  ),
              ],
            ),
          ),
        );

        final mainRow = Row(
          key: const ValueKey('map-study-dock-main-row'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 50, height: 50, child: Center(child: emblem())),
            const SizedBox(width: 6),
            Expanded(child: copy()),
            const SizedBox(width: 6),
            SizedBox(
              width: 50,
              height: 50,
              child: _StudyDockAction(onPressed: onOpen),
            ),
          ],
        );

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
                  const Positioned(
                    left: 40,
                    right: 40,
                    top: 24,
                    child: ExcludeSemantics(
                      child: SizedBox(
                        height: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                GaussColors.brass,
                                GaussColors.signalBright,
                                GaussColors.brass,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      mainRow,
                      if (!accessible) ...[
                        const SizedBox(height: 5),
                        Padding(
                          // The reading remains visually subordinate without
                          // being squeezed between the two 48dp instruments.
                          // It sits below them, so using the available width
                          // is both clearer and safer at 320dp.
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 3),
                          child: readings(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? GaussColors.ink.withValues(alpha: .8),
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
      ),
    ),
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
