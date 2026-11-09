part of 'map_screen.dart';

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
