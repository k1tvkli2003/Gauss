import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/mission_start_guard.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    if (controller.fatalError != null) return const _FatalDatasetView();
    return ColoredBox(
      color: GaussColors.abyss,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showInspector = constraints.maxWidth >= 1040;
          return Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _OrreryMap(
                        controller: controller,
                        radial: showInspector,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 0,
                      child: SafeArea(
                        bottom: false,
                        child: _MapHud(controller: controller),
                      ),
                    ),
                    if (!showInspector)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: _MissionDock(controller: controller),
                      ),
                  ],
                ),
              ),
              if (showInspector)
                SizedBox(
                  width: constraints.maxWidth >= 1320 ? 372 : 342,
                  child: _TopicInspector(controller: controller),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapHud extends StatelessWidget {
  const _MapHud({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      final hasSavedMission = controller.resumableMission != null;
      return _EtchedFrame(
        radius: 20,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 11 : 16,
          vertical: compact ? 9 : 11,
        ),
        child: Row(
          children: [
            GaussWordmark(width: compact ? 106 : 126),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact)
                    const Text(
                      'Chart what you can prove.',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(color: GaussColors.muted, fontSize: 11),
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (hasSavedMission && !compact) ...[
              _SavedMissionChip(onPressed: () => context.push('/resume')),
              const SizedBox(width: 8),
            ],
            if (controller.reviewDueCount > 0 && !compact) ...[
              _ReviewDueChip(
                count: controller.reviewDueCount,
                onPressed: () => context.push('/review?count=10'),
              ),
              const SizedBox(width: 8),
            ],
            _HudMetric(
              label: 'XP',
              value: '${controller.xp}',
              signal: GaussColors.brassLight,
            ),
            if (!compact) ...[
              const SizedBox(width: 7),
              _HudMetric(
                label: 'LEVEL',
                value: '${controller.gamification.level}',
                signal: GaussColors.signalBright,
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _SavedMissionChip extends StatelessWidget {
  const _SavedMissionChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Resume saved mission',
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GaussColors.signal.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(GaussRadii.pill),
          border: Border.all(color: GaussColors.signal.withValues(alpha: .45)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: GaussColors.signalBright),
            SizedBox(width: 4),
            Text(
              'Resume',
              style: TextStyle(
                color: GaussColors.signalBright,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReviewDueChip extends StatelessWidget {
  const _ReviewDueChip({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '$count ${count == 1 ? 'proof is' : 'proofs are'} due for review before they fade.',
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: GaussColors.brass.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(GaussRadii.pill),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TheoremStarMark(size: 17),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: const TextStyle(
                color: GaussColors.brassLight,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.label,
    required this.value,
    required this.signal,
  });

  final String label;
  final String value;
  final Color signal;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 56),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: GaussColors.abyss.withValues(alpha: .52),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: signal,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}

class _OrreryMap extends StatefulWidget {
  const _OrreryMap({required this.controller, required this.radial});

  final GaussController controller;
  final bool radial;

  @override
  State<_OrreryMap> createState() => _OrreryMapState();
}

class _OrreryMapState extends State<_OrreryMap> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (widget.radial) {
        return _RadialScene(
          controller: widget.controller,
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      }
      final sceneWidth = constraints.maxWidth;
      final sceneHeight = math.max(2120.0, constraints.maxHeight + 1250);
      return Scrollbar(
        controller: _scrollController,
        thumbVisibility: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: sceneWidth,
            height: sceneHeight,
            child: _VerticalScene(
              controller: widget.controller,
              size: Size(sceneWidth, sceneHeight),
            ),
          ),
        ),
      );
    },
  );
}

class _SceneBackdrop extends StatelessWidget {
  const _SceneBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/visual/map/orrery_atmosphere_portrait.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        cacheWidth: 1200,
        filterQuality: FilterQuality.medium,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.05,
            colors: [Color(0x0013282A), Color(0x3303090B), Color(0xCC03090B)],
            stops: [0, .68, 1],
          ),
        ),
      ),
      const CustomPaint(painter: _StarDustPainter()),
    ],
  );
}

class _VerticalScene extends StatelessWidget {
  const _VerticalScene({required this.controller, required this.size});

  final GaussController controller;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final positions = _mobilePositions(size, controller.topics.length);
    final completed = [
      for (final topic in controller.topics)
        controller.completedInTopic(topic.key) > 0,
    ];
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: _SceneBackdrop()),
        Positioned.fill(
          child: CustomPaint(
            painter: _ProofPathPainter(
              positions: positions,
              completed: completed,
              radial: false,
            ),
          ),
        ),
        Positioned(
          left: size.width / 2 - 143,
          top: 300,
          child: const _TheoremEngineLandmark(size: 286),
        ),
        Positioned(
          left: size.width / 2 - 126,
          top: 1585,
          child: IgnorePointer(
            child: Opacity(
              opacity: .72,
              child: Image.asset(
                'assets/visual/nodes/boss_observatory.png',
                width: 252,
                cacheWidth: 700,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        for (var i = 0; i < controller.topics.length; i++)
          Positioned(
            left: positions[i].dx - 50,
            top: positions[i].dy - 50,
            child: _TopicNode(
              topic: controller.topics[i],
              index: i,
              size: 100,
              selected: controller.selectedTopicKey == controller.topics[i].key,
              completed: controller.completedInTopic(controller.topics[i].key),
              onPressed: () => controller.selectTopic(controller.topics[i].key),
            ),
          ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 260,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0003090B), GaussColors.abyss],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RadialScene extends StatelessWidget {
  const _RadialScene({required this.controller, required this.size});

  final GaussController controller;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final positions = _radialPositions(size, controller.topics.length);
    final completed = [
      for (final topic in controller.topics)
        controller.completedInTopic(topic.key) > 0,
    ];
    final shortest = math.min(size.width, size.height);
    final nodeSize = (shortest * .105).clamp(78.0, 102.0);
    final engineSize = (shortest * .29).clamp(212.0, 292.0);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: _SceneBackdrop()),
        Positioned.fill(
          child: CustomPaint(
            painter: _ProofPathPainter(
              positions: positions,
              completed: completed,
              radial: true,
            ),
          ),
        ),
        Positioned(
          left: size.width / 2 - engineSize / 2,
          top: size.height * .54 - engineSize / 2,
          child: _TheoremEngineLandmark(size: engineSize),
        ),
        for (var i = 0; i < controller.topics.length; i++)
          Positioned(
            left: positions[i].dx - nodeSize / 2,
            top: positions[i].dy - nodeSize / 2,
            child: _TopicNode(
              topic: controller.topics[i],
              index: i,
              size: nodeSize,
              selected: controller.selectedTopicKey == controller.topics[i].key,
              completed: controller.completedInTopic(controller.topics[i].key),
              onPressed: () => controller.selectTopic(controller.topics[i].key),
            ),
          ),
      ],
    );
  }
}

List<Offset> _mobilePositions(Size size, int count) {
  final result = <Offset>[];
  final firstOrbit = <Offset>[
    Offset(size.width * .25, 184),
    Offset(size.width * .75, 184),
    Offset(size.width * .89, 350),
    Offset(size.width * .78, 590),
    Offset(size.width * .50, 654),
    Offset(size.width * .22, 590),
    Offset(size.width * .11, 350),
  ];
  for (var i = 0; i < math.min(7, count); i++) {
    result.add(firstOrbit[i]);
  }
  const columns = [.19, .5, .81];
  for (var i = 7; i < count; i++) {
    final local = i - 7;
    final row = local ~/ 3;
    var column = local % 3;
    if (row.isOdd) column = 2 - column;
    final wobble = math.sin(row * 1.17) * size.width * .025;
    result.add(Offset(size.width * columns[column] + wobble, 930 + row * 155));
  }
  return result;
}

List<Offset> _radialPositions(Size size, int count) {
  final center = Offset(size.width / 2, size.height * .54);
  final shortest = math.min(size.width, size.height);
  final ringCounts = [7, 11, math.max(0, count - 18)];
  final radii = [shortest * .18, shortest * .275, shortest * .36];
  final result = <Offset>[];
  var index = 0;
  for (var ring = 0; ring < ringCounts.length; ring++) {
    final ringCount = ringCounts[ring];
    if (ringCount == 0) continue;
    final phase = -math.pi / 2 + ring * .12;
    for (var slot = 0; slot < ringCount && index < count; slot++, index++) {
      final angle = phase + math.pi * 2 * slot / ringCount;
      result.add(
        center + Offset(math.cos(angle), math.sin(angle)) * radii[ring],
      );
    }
  }
  return result;
}

class _ProofPathPainter extends CustomPainter {
  const _ProofPathPainter({
    required this.positions,
    required this.completed,
    required this.radial,
  });

  final List<Offset> positions;
  final List<bool> completed;
  final bool radial;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radial ? 1.1 : 2
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.brass.withValues(alpha: radial ? .22 : .28);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radial ? 2.1 : 3
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.brassLight.withValues(alpha: .85);
    final signal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radial ? 1.4 : 2.2
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.signal.withValues(alpha: .72);

    if (radial) {
      final center = Offset(size.width / 2, size.height * .535);
      final shortest = math.min(size.width, size.height);
      for (final factor in const [.205, .315, .415]) {
        canvas.drawCircle(center, shortest * factor, base);
      }
      for (var i = 0; i < positions.length; i++) {
        final vector = positions[i] - center;
        final inner = center + vector * .91;
        final outer = center + vector * 1.035;
        canvas.drawLine(inner, outer, completed[i] ? signal : base);
      }
      return;
    }

    for (var i = 0; i < positions.length - 1; i++) {
      final from = positions[i];
      final to = positions[i + 1];
      final bend = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(
          bend.dx + (i.isEven ? 16 : -16),
          bend.dy,
          to.dx,
          to.dy,
        );
      canvas.drawPath(path, completed[i] ? active : base);
      if (completed[i]) {
        canvas.drawCircle(to, 3.1, Paint()..color = GaussColors.signalBright);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProofPathPainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.completed != completed ||
      oldDelegate.radial != radial;
}

class _StarDustPainter extends CustomPainter {
  const _StarDustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(1847);
    for (
      var i = 0;
      i < math.max(50, (size.width * size.height / 8500).round());
      i++
    ) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = random.nextDouble() * .8 + .18;
      canvas.drawCircle(
        p,
        radius,
        Paint()
          ..color = GaussColors.ivory.withValues(
            alpha: random.nextDouble() * .22 + .05,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TheoremEngineLandmark extends StatelessWidget {
  const _TheoremEngineLandmark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Theorem Engine. Core of your mathematics and physics map.',
    child: SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * .78,
            height: size * .78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GaussColors.brass.withValues(alpha: .2),
                  blurRadius: size * .19,
                  spreadRadius: size * .015,
                ),
                BoxShadow(
                  color: GaussColors.signal.withValues(alpha: .08),
                  blurRadius: size * .28,
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/visual/map/theorem_engine.png',
            width: size,
            height: size,
            cacheWidth: 1200,
            filterQuality: FilterQuality.medium,
          ),
          Positioned(
            bottom: size * .09,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * .065,
                vertical: size * .022,
              ),
              decoration: BoxDecoration(
                color: GaussColors.abyss.withValues(alpha: .84),
                borderRadius: BorderRadius.circular(GaussRadii.pill),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .48),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'THEOREM ENGINE',
                    style: TextStyle(
                      color: GaussColors.ivory,
                      fontSize: (size * .033).clamp(9, 12),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Every solved question lights the map',
                    style: TextStyle(
                      color: GaussColors.muted,
                      fontSize: (size * .025).clamp(7, 9),
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

enum _NodeState { available, current, completed, referenceOnly }

class _TopicNode extends StatelessWidget {
  const _TopicNode({
    required this.topic,
    required this.index,
    required this.size,
    required this.selected,
    required this.completed,
    required this.onPressed,
  });

  final TopicDescriptor topic;
  final int index;
  final double size;
  final bool selected;
  final int completed;
  final VoidCallback onPressed;

  _NodeState get state {
    if (topic.missionReadyCount == 0) return _NodeState.referenceOnly;
    if (selected) return _NodeState.current;
    if (completed > 0) return _NodeState.completed;
    return _NodeState.available;
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final nodeState = state;
    final progress = topic.missionReadyCount == 0
        ? 0.0
        : (completed / topic.missionReadyCount).clamp(0.0, 1.0);
    final accent = switch (nodeState) {
      _NodeState.current => GaussColors.brassLight,
      _NodeState.completed => GaussColors.signalBright,
      _NodeState.referenceOnly => GaussColors.fog,
      _NodeState.available =>
        topic.subject == Subject.math ? GaussColors.brass : GaussColors.ice,
    };
    final semanticState = switch (nodeState) {
      _NodeState.current => 'Current chapter',
      _NodeState.completed => '$completed problems solved here',
      _NodeState.referenceOnly => 'Reference only, no scored set available',
      _NodeState.available => 'Available',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${topic.label}. $semanticState.',
      hint: 'Double tap to inspect this chapter.',
      child: InkResponse(
        onTap: onPressed,
        radius: size * .58,
        containedInkWell: false,
        child: AnimatedScale(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          scale: selected ? 1.08 : 1,
          child: SizedBox(
            width: size,
            height: size + 38,
            child: Column(
              children: [
                SizedBox.square(
                  dimension: size,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (selected)
                        Container(
                          width: size * .82,
                          height: size * .82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: GaussColors.brassLight.withValues(
                                  alpha: .4,
                                ),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ColorFiltered(
                        colorFilter: nodeState == _NodeState.referenceOnly
                            ? const ColorFilter.matrix(<double>[
                                .42,
                                .42,
                                .42,
                                0,
                                0,
                                .42,
                                .42,
                                .42,
                                0,
                                0,
                                .42,
                                .42,
                                .42,
                                0,
                                0,
                                0,
                                0,
                                0,
                                .62,
                                0,
                              ])
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              ),
                        child: Image.asset(
                          'assets/visual/nodes/topic_shell.png',
                          width: size,
                          height: size,
                          cacheWidth: 520,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      CustomPaint(
                        size: Size.square(size * .79),
                        painter: _NodeProgressPainter(
                          color: accent,
                          progress: progress,
                          current: selected,
                        ),
                      ),
                      Positioned(
                        top: size * .25,
                        child: TopicGlyph(
                          topicKey: topic.key,
                          color: accent,
                          size: size * .29,
                        ),
                      ),
                      Positioned(
                        top: size * .08,
                        right: size * .1,
                        child: _NodeNumber(index: index + 1),
                      ),
                      Positioned(
                        bottom: size * .1,
                        left: size * .09,
                        child: _NodeStatus(state: nodeState),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: size * .98),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: GaussColors.abyss.withValues(alpha: .74),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        topic.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: nodeState == _NodeState.referenceOnly
                              ? GaussColors.fog
                              : GaussColors.ivory,
                          fontSize: (size * .085).clamp(9.2, 11.5),
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          height: 1.15,
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

class _NodeProgressPainter extends CustomPainter {
  const _NodeProgressPainter({
    required this.color,
    required this.progress,
    required this.current,
  });

  final Color color;
  final double progress;
  final bool current;

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
        ..strokeWidth = current ? 2.2 : 1.2
        ..color = color.withValues(alpha: current ? .72 : .25),
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
          ..strokeWidth = 3
          ..color = GaussColors.signalBright,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NodeProgressPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.current != current;
}

class _NodeNumber extends StatelessWidget {
  const _NodeNumber({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 23, minHeight: 23),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GaussColors.deepInk,
      border: Border.all(color: GaussColors.brass.withValues(alpha: .58)),
    ),
    child: Text(
      '$index',
      style: const TextStyle(
        color: GaussColors.ivory,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _NodeStatus extends StatelessWidget {
  const _NodeStatus({required this.state});

  final _NodeState state;

  @override
  Widget build(BuildContext context) {
    if (state == _NodeState.available) return const SizedBox.shrink();
    final color = switch (state) {
      _NodeState.current => GaussColors.brassLight,
      _NodeState.completed => GaussColors.signalBright,
      _NodeState.referenceOnly => GaussColors.fog,
      _NodeState.available => Colors.transparent,
    };
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GaussColors.deepInk,
        border: Border.all(color: color),
      ),
      child: state == _NodeState.current
          ? const TheoremStarMark(size: 17)
          : Icon(
              state == _NodeState.completed
                  ? Icons.check_rounded
                  : Icons.shield_outlined,
              size: 14,
              color: color,
            ),
    );
  }
}

class _TopicInspector extends StatelessWidget {
  const _TopicInspector({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) {
    final topic = controller.selectedTopic;
    final completed = controller.completedInTopic(topic.key);
    final progress = topic.missionReadyCount == 0
        ? 0.0
        : (completed / topic.missionReadyCount).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: GaussColors.ink,
        border: Border(left: BorderSide(color: GaussColors.line)),
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'MISSION CHART',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: GaussColors.brassLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  const _OfflineBadge(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SubjectSwitch(
                      subject: Subject.math,
                      active: topic.subject == Subject.math,
                      onPressed: () =>
                          _selectFirstSubject(controller, Subject.math),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SubjectSwitch(
                      subject: Subject.physics,
                      active: topic.subject == Subject.physics,
                      onPressed: () =>
                          _selectFirstSubject(controller, Subject.physics),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GaussColors.deepInk,
                      shape: BoxShape.circle,
                      border: Border.all(color: GaussColors.brass),
                      boxShadow: [
                        BoxShadow(
                          color: GaussColors.brass.withValues(alpha: .13),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: TopicGlyph(
                      topicKey: topic.key,
                      color: GaussColors.brassLight,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHAPTER ${controller.topics.indexOf(topic) + 1}',
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            topic.label,
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
              _MasteryStrip(
                progress: progress,
                completed: completed,
                available: topic.missionReadyCount,
              ),
              const SizedBox(height: 18),
              _EtchedFrame(
                radius: 18,
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WHAT THIS CHAPTER TRAINS',
                      style: TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final item in _focusAreas(topic.key))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: SizedBox.square(
                                dimension: 5,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: GaussColors.signal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  color: GaussColors.muted,
                                  fontSize: 12,
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
              if (controller.resumableMission != null) ...[
                OutlinedButton.icon(
                  onPressed: () => context.push('/resume'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume saved mission'),
                ),
                const SizedBox(height: 9),
              ],
              if (topic.preservedArchiveCount > 0) ...[
                OutlinedButton.icon(
                  onPressed: () => context.push('/archive/${topic.key}'),
                  icon: const Icon(Icons.menu_book_outlined, size: 19),
                  label: Text(
                    'Reading room · ${topic.preservedArchiveCount} preserved',
                  ),
                ),
                const SizedBox(height: 9),
              ],
              FilledButton(
                onPressed: topic.missionReadyCount == 0
                    ? null
                    : () => _startMission(context, controller, topic),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topic.missionReadyCount == 0
                          ? 'No scored set yet'
                          : 'Start mission',
                    ),
                    const SizedBox(width: 9),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                topic.missionReadyCount == 0
                    ? 'This chapter remains safely preserved in your offline library.'
                    : 'A focused set drawn from ${topic.questionCount} offline questions.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: GaussColors.fog, fontSize: 10.5),
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
    required this.active,
    required this.onPressed,
  });

  final Subject subject;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: active,
    label: subject == Subject.math ? 'Math chapters' : 'Physics chapters',
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? GaussColors.brass.withValues(alpha: .12)
              : GaussColors.deepInk,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? GaussColors.brass : GaussColors.hairline,
          ),
        ),
        child: Text(
          subject == Subject.math ? 'Math' : 'Physics',
          style: TextStyle(
            color: active ? GaussColors.brassLight : GaussColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

class _MasteryStrip extends StatelessWidget {
  const _MasteryStrip({
    required this.progress,
    required this.completed,
    required this.available,
  });

  final double progress;
  final int completed;
  final int available;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Text(
            'Solved here',
            style: TextStyle(color: GaussColors.muted, fontSize: 12),
          ),
          const Spacer(),
          Text(
            available == 0 ? 'Reference only' : '$completed solved',
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        child: LinearProgressIndicator(value: progress, minHeight: 8),
      ),
    ],
  );
}

class _MissionDock extends StatelessWidget {
  const _MissionDock({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) {
    final topic = controller.selectedTopic;
    final completed = controller.completedInTopic(topic.key);
    return _EtchedFrame(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GaussColors.deepInk,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GaussColors.brass),
            ),
            child: TopicGlyph(
              topicKey: topic.key,
              color: GaussColors.brassLight,
              size: 31,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    topic.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GaussColors.ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.missionReadyCount == 0
                      ? 'Reference only'
                      : '$completed solved · ${topic.questionCount} in library',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GaussColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          FilledButton(
            onPressed: topic.missionReadyCount == 0
                ? (topic.preservedArchiveCount == 0
                      ? null
                      : () => context.push('/archive/${topic.key}'))
                : () => _startMission(context, controller, topic),
            style: FilledButton.styleFrom(
              minimumSize: const Size(84, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(topic.missionReadyCount == 0 ? 'Read' : 'Start'),
          ),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Offline. All content is available.',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: GaussColors.signal.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        border: Border.all(color: GaussColors.signal.withValues(alpha: .26)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GaussColors.signalBright,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: GaussColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EtchedFrame extends StatelessWidget {
  const _EtchedFrame({
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
      color: GaussColors.ink.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: GaussColors.line),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GaussColors.panelHigh.withValues(alpha: .95),
          GaussColors.ink.withValues(alpha: .97),
        ],
      ),
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

Future<void> _startMission(
  BuildContext context,
  GaussController controller,
  TopicDescriptor topic,
) async {
  final confirmed = await confirmMissionReplacement(
    context,
    controller.resumableMission,
  );
  if (confirmed && context.mounted) {
    await context.push('/mission/${topic.key}');
  }
}

void _selectFirstSubject(GaussController controller, Subject subject) {
  final first = controller.topics.firstWhere(
    (topic) => topic.subject == subject,
  );
  controller.selectTopic(first.key);
}

List<String> _focusAreas(String key) {
  if (key.contains('function') || key.contains('derivative')) {
    return const [
      'Reading structure from equations and graphs',
      'Choosing a rigorous solution path',
      'Checking edge cases before committing',
    ];
  }
  if (key.contains('geometry') || key.contains('trigonometry')) {
    return const [
      'Translating diagrams into exact relationships',
      'Selecting the decisive theorem',
      'Verifying every construction step',
    ];
  }
  if (key.contains('probability') || key.contains('statistics')) {
    return const [
      'Defining the sample space precisely',
      'Separating signal from distracting data',
      'Testing whether the result is plausible',
    ];
  }
  if (key.contains('electric') || key.contains('magnet')) {
    return const [
      'Mapping physical quantities to a model',
      'Tracking direction, sign, and units',
      'Validating the model against the scenario',
    ];
  }
  if (key.contains('motion') || key.contains('dynamic')) {
    return const [
      'Choosing a useful frame of reference',
      'Connecting motion diagrams and equations',
      'Checking signs, units, and limiting cases',
    ];
  }
  return const [
    'Recognizing the governing structure',
    'Building a clear chain of reasoning',
    'Checking the conclusion independently',
  ];
}

class _FatalDatasetView extends StatelessWidget {
  const _FatalDatasetView();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _EtchedFrame(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TheoremStarMark(size: 62, monochrome: true),
              const SizedBox(height: 18),
              Text(
                'The observatory could not verify its archive.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your offline questions and local progress were left untouched. Restart Gauss to try the verification again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GaussColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
