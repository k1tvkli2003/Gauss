part of 'map_screen.dart';

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
                    key: ValueKey('map-node-aura-${node.key}'),
                    // The emphasized station itself already scales to 1.13x.
                    // A 1.18x aura keeps its orbital halo outside the metal
                    // body without letting the transformed paint envelope
                    // trespass into compact fixed chrome.
                    size: Size.square(size * 1.18),
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
        Paint()..color = GaussScrims.nodeShadow,
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
