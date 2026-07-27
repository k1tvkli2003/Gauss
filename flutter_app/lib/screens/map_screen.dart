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
  bool? _tourWasVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sectionId ??= GaussStudyCurriculum.forSubject(_subject).first.id;
  }

  void _selectSubject(GaussController controller, Subject subject) {
    if (_subject == subject) return;
    final firstSection = GaussStudyCurriculum.forSubject(subject).first;
    final firstTopic = controller.topics.firstWhere(
      (topic) => topic.key == firstSection.topicKeys.first,
    );
    setState(() {
      _subject = subject;
      _sectionId = firstSection.id;
      _selectedNodeKey = null;
    });
    controller.selectTopic(firstTopic.key);
  }

  void _selectSection(
    GaussController controller,
    StudySectionDefinition section,
  ) {
    if (_sectionId == section.id) return;
    final firstTopic = controller.topics.firstWhere(
      (topic) => topic.key == section.topicKeys.first,
    );
    setState(() {
      _sectionId = section.id;
      _selectedNodeKey = null;
    });
    controller.selectTopic(firstTopic.key);
  }

  void _selectNode(GaussController controller, StudyPathNode node) {
    setState(() => _selectedNodeKey = node.key);
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
              final dockBottom = GaussMetrics.mapDockBottom(window);
              final bottomObstruction = GaussMetrics.mapBottomObstruction(
                window,
              );
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
                                onSubject: (subject) =>
                                    _selectSubject(controller, subject),
                                onSection: (value) =>
                                    _selectSection(controller, value),
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
                                bottomObstruction: bottomObstruction,
                                onSelected: (node) =>
                                    _selectNode(controller, node),
                              ),
                            ),
                          ],
                        ),
                        PositionedDirectional(
                          end: 14,
                          bottom: showInspector
                              ? 18
                              : dockBottom +
                                    GaussMetrics.mapDockHeight +
                                    GaussMetrics.mapOverlayGap,
                          child: _JumpToCurrentButton(
                            onPressed: () => _pathKey.currentState?.jumpToNode(
                              effectiveCurrent,
                            ),
                          ),
                        ),
                        if (!showInspector)
                          PositionedDirectional(
                            start: 12,
                            end: 12,
                            bottom: dockBottom,
                            child: _StudyDock(
                              node: selected,
                              snapshot: controller.study.shelf(selected.key),
                              isCurrent:
                                  selected.key == nodes[effectiveCurrent].key,
                              onOpen: () => _openNode(context, selected),
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

Future<void> _openNode(
  BuildContext context,
  StudyPathNode node,
) => context.push(
  '/study/chapter/${node.topic.key}?offset=${node.offset}&count=${GaussStudyCurriculum.batchSize}',
);

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
    required this.onSubject,
    required this.onSection,
  });

  final GaussController controller;
  final Subject subject;
  final List<StudySectionDefinition> sections;
  final StudySectionDefinition section;
  final ValueChanged<Subject> onSubject;
  final ValueChanged<StudySectionDefinition> onSection;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: _GlassFrame(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final roomy = constraints.maxWidth >= 740;
          final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.75;
          final condensed = compact && largeText;
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (condensed)
                    const TheoremStarMark(size: 36)
                  else
                    GaussWordmark(width: compact ? 96 : 124),
                  SizedBox(width: condensed ? 6 : 12),
                  if (roomy)
                    const Expanded(
                      child: Text(
                        'ORBIT OF KNOWLEDGE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: GaussColors.fog,
                          fontSize: GaussTypeScale.insignia,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    )
                  else if (compact)
                    Expanded(
                      child: Center(
                        child: _MapProgressCrest(
                          charted: sectionReflected,
                          total: sectionTotal,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  _SubjectSwitch(
                    subject: subject,
                    onSubject: onSubject,
                    compact: compact,
                  ),
                  const SizedBox(width: 8),
                  if (!condensed) ...[
                    _HeaderMetric(
                      value: '${controller.study.totalReflected}',
                      label: compact ? 'MARKS' : 'CHARTED',
                      color: GaussColors.signalBright,
                    ),
                    const SizedBox(width: 7),
                  ],
                  _HeaderMetric(
                    value: '${controller.gamification.level}',
                    label: compact ? 'LVL' : 'LEVEL',
                    color: GaussColors.brassLight,
                  ),
                  if (roomy) ...[
                    const SizedBox(width: 7),
                    _HeaderMetric(
                      value: '${controller.gamification.totalXp}',
                      label: 'XP',
                      color: GaussColors.ivory,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              _OrbitSelector(
                section: section,
                sectionIndex: sections.indexOf(section) + 1,
                sectionCount: sections.length,
                reflected: sectionReflected,
                total: sectionTotal,
                compact: compact,
                onPressed: () => _openSectionPicker(context),
              ),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _openSectionPicker(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _SectionPickerSheet(
          sections: sections,
          selected: section,
          onSelected: (value) {
            Navigator.of(sheetContext).pop();
            onSection(value);
          },
        ),
      );
}

class _OrbitSelector extends StatelessWidget {
  const _OrbitSelector({
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.reflected,
    required this.total,
    required this.compact,
    required this.onPressed,
  });

  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final int reflected;
  final int total;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Current orbit $sectionIndex of $sectionCount. ${section.title}. $reflected of $total charted.',
    hint: 'Double tap to choose another orbit.',
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: GaussMetrics.minTouchTarget,
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: GaussColors.deepInk.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .34)),
        ),
        child: Row(
          children: [
            _OrbitIndexRing(value: sectionIndex),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    compact
                        ? 'ORBIT $sectionIndex'
                        : 'CURRENT ORBIT · $sectionIndex OF $sectionCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.brassLight,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .85,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: GaussColors.ivory,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$reflected / $total',
                  style: const TextStyle(
                    color: GaussColors.signalBright,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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

/// A deliberately compact, live progress crest for the phone HUD.  The
/// theorem star remains the selected identity mark, while the reading beneath
/// it is bound to the real local study state rather than baked into artwork.
class _MapProgressCrest extends StatelessWidget {
  const _MapProgressCrest({required this.charted, required this.total});

  final int charted;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$charted of $total questions charted',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 47,
          height: 47,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GaussColors.deepInk.withValues(alpha: .76),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .46)),
            boxShadow: [
              BoxShadow(
                color: GaussColors.signal.withValues(alpha: .12),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const TheoremStarMark(size: 35),
        ),
        const SizedBox(height: 2),
        Text(
          '$charted / $total',
          style: const TextStyle(
            color: GaussColors.signalBright,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
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
    child: Text(
      '$value',
      style: const TextStyle(
        color: GaussColors.ivory,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _SectionPickerSheet extends StatelessWidget {
  const _SectionPickerSheet({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<StudySectionDefinition> sections;
  final StudySectionDefinition selected;
  final ValueChanged<StudySectionDefinition> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: _GlassFrame(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: GaussColors.fog.withValues(alpha: .44),
                  borderRadius: BorderRadius.circular(GaussRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'CHOOSE AN ORBIT',
              style: TextStyle(
                color: GaussColors.brassLight,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final item = sections[index];
                  final isSelected = item.id == selected.id;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Orbit ${index + 1}. ${item.title}',
                    child: InkWell(
                      onTap: () => onSelected(item),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 58),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GaussColors.brass.withValues(alpha: .13)
                              : GaussColors.deepInk.withValues(alpha: .54),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? GaussColors.brass
                                : GaussColors.hairline,
                          ),
                        ),
                        child: Row(
                          children: [
                            _OrbitIndexRing(value: index + 1),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: GaussColors.ivory,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
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
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: GaussColors.signalBright,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: GaussColors.abyss.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SubjectButton(
          label: compact ? 'M' : 'Math',
          selected: subject == Subject.math,
          onPressed: () => onSubject(Subject.math),
        ),
        _SubjectButton(
          label: compact ? 'P' : 'Physics',
          selected: subject == Subject.physics,
          onPressed: () => onSubject(Subject.physics),
        ),
      ],
    ),
  );
}

class _SubjectButton extends StatelessWidget {
  const _SubjectButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 170),
        constraints: const BoxConstraints(
          minWidth: GaussMetrics.minTouchTarget,
          minHeight: GaussMetrics.minTouchTarget,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
          style: TextStyle(
            color: selected ? GaussColors.brassLight : GaussColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(
      minWidth: 54,
      minHeight: GaussMetrics.minTouchTarget,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: GaussColors.abyss.withValues(alpha: .56),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: GaussTypeScale.insignia,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
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

  @override
  void didUpdateWidget(covariant _StudyPathStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void jumpToNode(int index) {
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
    _scrollController.animateTo(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
    );
  }

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
      );
      _nodeY = geometry.positions.map((position) => position.dy).toList();
      return SingleChildScrollView(
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
                  ),
                ),
              ),
              for (final landmark in geometry.landmarks)
                _PathLandmark(landmark: landmark),
              if (constraints.maxWidth >= 560)
                for (final header in geometry.unitHeaders)
                  Positioned(
                    left: 18,
                    right: 18,
                    top: header.y,
                    child: _UnitBanner(
                      topic: header.topic,
                      unitNumber: header.unitNumber,
                      reflected: widget.controller.study
                          .topic(header.topic.key)
                          .reflected,
                    ),
                  ),
              for (var index = 0; index < widget.nodes.length; index++)
                Positioned(
                  left: geometry.positions[index].dx - geometry.nodeSize / 2,
                  top: geometry.positions[index].dy - geometry.nodeSize / 2,
                  child: _StudyNode(
                    node: widget.nodes[index],
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
                _PathNodeLabel(
                  node: widget.nodes[index],
                  snapshot: widget.controller.study.shelf(
                    widget.nodes[index].key,
                  ),
                  position: geometry.positions[index],
                  nodeSize: geometry.nodeSize,
                  stageWidth: constraints.maxWidth,
                  isCurrent: index == widget.currentIndex,
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
  }) {
    final compact = width < 560;
    final expanded = width >= 760;
    final nodeSize = compact
        ? 78.0
        : expanded
        ? 100.0
        : 90.0;
    final center = width / 2;
    final amplitude = math.min(
      width *
          (compact
              ? .28
              : expanded
              ? .34
              : .31),
      expanded ? 270.0 : 225.0,
    );
    final positions = <Offset>[];
    final headers = <_UnitHeaderGeometry>[];
    final landmarks = <_LandmarkGeometry>[];
    var y = compact ? 188.0 : 194.0;
    var unitNumber = 0;
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      if (node.beginsUnit) {
        unitNumber++;
        y += index == 0
            ? compact
                  ? 76
                  : 84
            : compact
            ? 118
            : 128;
        headers.add(
          _UnitHeaderGeometry(
            topic: node.topic,
            unitNumber: unitNumber,
            y: y - (compact ? 83 : 90),
          ),
        );
      }
      final phase = index * .84 + unitNumber * .28;
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
                  ? 168.0
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
                ? y + (compact ? 10 : -4)
                : y - (compact ? 36 : 50),
            start: placeStart ? edge : null,
            end: placeStart ? null : edge,
            size: landmarkSize,
            kind: openingLandmark ? 0 : 1 + (index ~/ 6) % 2,
          ),
        );
      }
      y += compact
          ? 106
          : expanded
          ? 128
          : 122;
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

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({
    required this.topic,
    required this.unitNumber,
    required this.reflected,
  });

  final TopicDescriptor topic;
  final int unitNumber;
  final int reflected;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: GaussColors.deepInk.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Text(
              'UNIT $unitNumber',
              style: const TextStyle(
                color: GaussColors.brassLight,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: .9,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Directionality(
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
            ),
            const SizedBox(width: 8),
            Text(
              '$reflected / ${topic.questionCount}',
              style: const TextStyle(
                color: GaussColors.fog,
                fontSize: GaussTypeScale.insignia,
              ),
            ),
          ],
        ),
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
  });

  final Offset current;
  final double nodeSize;

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

    for (var centerY = 330.0; centerY < size.height + 300; centerY += 720) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The reference route keeps the names attached to their instruments, instead
/// of making people infer every destination from an icon.  This stays live so
/// Persian curriculum labels and real local progress never get frozen into a
/// decorative map image.
class _PathNodeLabel extends StatelessWidget {
  const _PathNodeLabel({
    required this.node,
    required this.snapshot,
    required this.position,
    required this.nodeSize,
    required this.stageWidth,
    required this.isCurrent,
  });

  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final Offset position;
  final double nodeSize;
  final double stageWidth;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final compact = stageWidth < 560;
    final width = compact ? 128.0 : 150.0;
    final rightPreferred =
        position.dx + nodeSize * .57 + width <= stageWidth - 5;
    final left = rightPreferred
        ? position.dx + nodeSize * .57
        : math.max(5.0, position.dx - nodeSize * .57 - width);
    final title = node.beginsUnit ? node.topic.label : node.setLabel;
    return Positioned(
      left: left,
      top: position.dy - (compact ? 31 : 34),
      width: width,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            opacity: isCurrent ? 1 : .9,
            child: AnimatedContainer(
              duration: GaussMotion.resolve(context, GaussMotion.micro),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsetsDirectional.fromSTEB(9, 6, 9, 6),
              decoration: BoxDecoration(
                color: GaussColors.deepInk.withValues(
                  alpha: isCurrent ? .84 : .68,
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color:
                      (isCurrent ? GaussColors.signalBright : GaussColors.brass)
                          .withValues(alpha: isCurrent ? .48 : .22),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: rightPreferred ? 4 : 0,
                      end: rightPreferred ? 0 : 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            title,
                            textAlign: TextAlign.start,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? GaussColors.ivory
                                  : GaussColors.fog,
                              fontSize: compact ? 12 : 13.5,
                              height: 1.28,
                              fontWeight: isCurrent
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${snapshot.reflected} / ${node.questionCount}',
                          style: TextStyle(
                            color: isCurrent
                                ? GaussColors.signalBright
                                : GaussColors.signal.withValues(alpha: .86),
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: rightPreferred
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: 2,
                      height: isCurrent ? 31 : 23,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? GaussColors.signalBright
                            : GaussColors.brassLight.withValues(alpha: .68),
                        borderRadius: BorderRadius.circular(GaussRadii.pill),
                      ),
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

class _StudyNode extends StatelessWidget {
  const _StudyNode({
    required this.node,
    required this.size,
    required this.snapshot,
    required this.current,
    required this.selected,
    required this.onPressed,
  });

  final StudyPathNode node;
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
          '${node.topic.label}. ${node.setLabel}. ${snapshot.reflected} of ${node.questionCount} reflected. ${snapshot.revisit} marked for revisit.',
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
                  width: size,
                  height: size,
                  cacheWidth: 360,
                  filterQuality: FilterQuality.medium,
                ),
                CustomPaint(
                  size: Size.square(size * .79),
                  painter: _NodeProgressPainter(
                    color: accent,
                    progress: progress,
                    emphasized: current || selected,
                  ),
                ),
                TopicGlyph(
                  topicKey: node.topic.key,
                  color: accent,
                  size: size * .31,
                ),
                PositionedDirectional(
                  end: 3,
                  top: 2,
                  child: _NodeNumber(value: node.partIndex + 1),
                ),
                if (complete)
                  const PositionedDirectional(
                    start: 2,
                    bottom: 3,
                    child: _NodeBadge(
                      icon: Icons.check_rounded,
                      color: GaussColors.signalBright,
                    ),
                  )
                else if (snapshot.revisit > 0)
                  const PositionedDirectional(
                    start: 2,
                    bottom: 3,
                    child: _NodeBadge(
                      icon: Icons.bookmark_outline_rounded,
                      color: GaussColors.warning,
                    ),
                  )
                else if (current)
                  const PositionedDirectional(
                    start: 2,
                    bottom: 3,
                    child: _NodeBadge(
                      icon: Icons.auto_stories_outlined,
                      color: GaussColors.brassLight,
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

class _NodeBadge extends StatelessWidget {
  const _NodeBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 25,
    height: 25,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: GaussColors.deepInk,
      shape: BoxShape.circle,
      border: Border.all(color: color),
    ),
    child: Icon(icon, size: 14, color: color),
  );
}

class _ContinuousPathPainter extends CustomPainter {
  const _ContinuousPathPainter({
    required this.positions,
    required this.completed,
    required this.currentIndex,
  });

  final List<Offset> positions;
  final List<bool> completed;
  final int currentIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;
    final path = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (var index = 1; index < positions.length; index++) {
      final previous = positions[index - 1];
      final current = positions[index];
      final middleY = (previous.dy + current.dy) / 2;
      path.cubicTo(
        previous.dx,
        middleY,
        current.dx,
        middleY,
        current.dx,
        current.dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xC803090B),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..color = GaussColors.brass.withValues(alpha: .46),
    );
    for (var index = 0; index < positions.length - 1; index++) {
      final isComplete = completed[index];
      final isCurrentLead = index == currentIndex;
      if (!isComplete && !isCurrentLead) continue;
      final segment = Path()..moveTo(positions[index].dx, positions[index].dy);
      final next = positions[index + 1];
      final middleY = (positions[index].dy + next.dy) / 2;
      segment.cubicTo(
        positions[index].dx,
        middleY,
        next.dx,
        middleY,
        next.dx,
        next.dy,
      );
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrentLead ? 12 : 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7)
          ..color =
              (isCurrentLead ? GaussColors.brassLight : GaussColors.signal)
                  .withValues(alpha: isCurrentLead ? .25 : .14),
      );
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrentLead ? 4.6 : 3.4
          ..strokeCap = StrokeCap.round
          ..color =
              (isCurrentLead
                      ? GaussColors.brassLight
                      : GaussColors.signalBright)
                  .withValues(alpha: isCurrentLead ? .86 : .74),
      );
      if (isCurrentLead) {
        for (var marker = 1; marker <= 3; marker++) {
          final t = marker / 4;
          final y = positions[index].dy + (next.dy - positions[index].dy) * t;
          final x = positions[index].dx + (next.dx - positions[index].dx) * t;
          canvas.drawCircle(
            Offset(x, y),
            2.1,
            Paint()..color = GaussColors.brassLight.withValues(alpha: .82),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ContinuousPathPainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.completed != completed ||
      oldDelegate.currentIndex != currentIndex;
}

class _StudyDock extends StatelessWidget {
  const _StudyDock({
    required this.node,
    required this.snapshot,
    required this.isCurrent,
    required this.onOpen,
  });

  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final bool isCurrent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isComplete = snapshot.reflected >= node.questionCount;
    final status = isComplete
        ? 'SET COMPLETE'
        : isCurrent
        ? 'CURRENT MISSION'
        : 'SELECTED SET';
    final detail =
        '${node.setLabel} · ${snapshot.reflected} / '
        '${node.questionCount} charted'
        '${snapshot.revisit > 0 ? ' · ${snapshot.revisit} revisit' : ''}';
    return _GlassFrame(
      radius: 22,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 350;
          final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.55;
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
              children: [
                _MissionDockEmblem(
                  topicKey: node.topic.key,
                  isCurrent: isCurrent,
                  isComplete: isComplete,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    container: true,
                    label:
                        '$status. ${node.topic.label}. ${snapshot.reflected} of '
                        '${node.questionCount} questions charted.',
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
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
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: GaussColors.brassLight,
                                    fontSize: GaussTypeScale.insignia,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.05,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              node.topic.label,
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GaussColors.ivory,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (!largeText) ...[
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GaussColors.muted,
                                fontSize: GaussTypeScale.insignia,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(narrow ? 76 : 92, 48),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: narrow ? 9 : 12,
                    ),
                  ),
                  icon: const Icon(Icons.auto_stories_outlined, size: 18),
                  label: const Text('Study'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissionDockEmblem extends StatelessWidget {
  const _MissionDockEmblem({
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
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GaussColors.deepInk.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .14), blurRadius: 14),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCurrent || isComplete)
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .34)),
              ),
            ),
          TopicGlyph(topicKey: topicKey, color: accent, size: 29),
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
    required this.onOpen,
  });

  final StudySectionDefinition section;
  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final StudyTopicSnapshot topicSnapshot;
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
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            node.topic.label,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
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
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('Open study set'),
              ),
              const SizedBox(height: 9),
              const Text(
                'Choose a hypothesis, reveal the reference answer, then record your own reflection. Nothing is scored.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GaussColors.ink.withValues(alpha: .8),
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
