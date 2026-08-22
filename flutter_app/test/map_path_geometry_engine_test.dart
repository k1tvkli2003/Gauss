import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/widgets/map_path_geometry.dart';

void main() {
  test('long learning routes partition into contiguous lazy bands', () {
    final nodes = _nodes(42);
    final geometry = GaussPathGeometry.build(
      width: 390,
      nodes: nodes,
      textScale: 1,
    );

    expect(geometry.bands.length, greaterThan(4));
    expect(geometry.bands.first.top, 0);
    expect(geometry.bands.last.bottom, geometry.height);
    for (var index = 1; index < geometry.bands.length; index++) {
      expect(geometry.bands[index - 1].bottom, geometry.bands[index].top);
    }

    final ownedNodes = geometry.bands.expand((band) => band.nodeIndices);
    final ownedHeaders = geometry.bands.expand((band) => band.headerIndices);
    final ownedLandmarks = geometry.bands.expand(
      (band) => band.landmarkIndices,
    );
    expect(ownedNodes.toSet(), hasLength(nodes.length));
    expect(ownedNodes, hasLength(nodes.length));
    expect(ownedHeaders.toSet(), hasLength(geometry.unitHeaders.length));
    expect(ownedHeaders, hasLength(geometry.unitHeaders.length));
    expect(ownedLandmarks.toSet(), hasLength(geometry.landmarks.length));
    expect(ownedLandmarks, hasLength(geometry.landmarks.length));

    for (final band in geometry.bands) {
      expect(band.height, greaterThan(0));
      expect(band.height, lessThan(1500));
      for (final nodeIndex in band.nodeIndices) {
        final y = geometry.positions[nodeIndex].dy;
        expect(y, greaterThanOrEqualTo(band.top));
        expect(y, lessThan(band.bottom));
      }
    }

    final paintedSegments = geometry.bands
        .expand((band) => band.segmentIndices)
        .toSet();
    expect(paintedSegments, hasLength(nodes.length - 1));

    final finalVisualBottom = math.max(
      geometry.positions.last.dy + geometry.nodeSize / 2,
      geometry.landmarks.fold<double>(
        0,
        (bottom, landmark) => math.max(bottom, landmark.top + landmark.size),
      ),
    );
    expect(
      geometry.height - finalVisualBottom,
      inInclusiveRange(24, 48),
      reason:
          'The scene may keep a small optical tail, but not a blank cadence '
          'after its final lesson or landmark.',
    );
  });

  test(
    'geometry cache reuses selection rebuilds and bounds retained layouts',
    () {
      final nodes = _nodes(18);
      final cache = GaussPathGeometryCache(maxEntries: 2);
      final first = cache.resolve(
        sectionId: 'math-test',
        width: 390,
        nodes: nodes,
        textScale: 1.1,
      );
      final selectionRebuild = cache.resolve(
        sectionId: 'math-test',
        width: 390,
        nodes: nodes,
        textScale: 1.2,
      );
      expect(identical(first, selectionRebuild), isTrue);
      expect(cache.misses, 1);
      expect(cache.hits, 1);

      cache.resolve(
        sectionId: 'math-test',
        width: 800,
        nodes: nodes,
        textScale: 1,
      );
      cache.resolve(
        sectionId: 'physics-test',
        width: 1280,
        nodes: nodes,
        textScale: 1,
      );
      expect(cache.length, 2);

      final rebuilt = cache.resolve(
        sectionId: 'math-test',
        width: 390,
        nodes: nodes,
        textScale: 1.1,
      );
      expect(identical(first, rebuilt), isFalse);
      expect(cache.length, 2);
    },
  );

  test('text scale buckets are conservative at accessibility boundaries', () {
    expect(GaussPathGeometryCache.textScaleBucket(.8), 1);
    expect(GaussPathGeometryCache.textScaleBucket(1.01), 1.25);
    expect(GaussPathGeometryCache.textScaleBucket(1.25), 1.25);
    expect(GaussPathGeometryCache.textScaleBucket(1.4), 1.55);
    expect(GaussPathGeometryCache.textScaleBucket(1.55), 2);
    expect(GaussPathGeometryCache.textScaleBucket(3), 2);
  });

  test('large-radius route keeps varied lesson cadence inside safe lanes', () {
    final geometry = GaussPathGeometry.build(
      width: 320,
      nodes: _nodes(28),
      textScale: 1,
    );
    final verticalCadence = <int>{
      for (var index = 1; index < geometry.positions.length; index++)
        (geometry.positions[index].dy - geometry.positions[index - 1].dy)
            .round(),
    };
    final horizontalMoves = <int>{
      for (var index = 1; index < geometry.positions.length; index++)
        (geometry.positions[index].dx - geometry.positions[index - 1].dx)
            .round(),
    };

    expect(verticalCadence.length, greaterThan(5));
    expect(horizontalMoves.length, greaterThan(8));
    for (final position in geometry.positions) {
      expect(position.dx, greaterThan(geometry.nodeSize / 2 + 6));
      expect(position.dx, lessThan(320 - geometry.nodeSize / 2 - 6));
    }
  });

  test('orbital curve shares a tangent across every lesson instrument', () {
    final geometry = GaussPathGeometry.build(
      width: 390,
      nodes: _nodes(22),
      textScale: 1,
    );
    for (var index = 1; index < geometry.positions.length - 1; index++) {
      final incomingMetric = geometry
          .pathForSegment(index - 1)
          .computeMetrics()
          .single;
      final outgoingMetric = geometry
          .pathForSegment(index)
          .computeMetrics()
          .single;
      final incoming = incomingMetric.getTangentForOffset(
        math.max(0, incomingMetric.length - .01),
      );
      final outgoing = outgoingMetric.getTangentForOffset(.01);
      expect(incoming, isNotNull);
      expect(outgoing, isNotNull);
      var difference = (incoming!.angle - outgoing!.angle).abs();
      if (difference > math.pi) difference = math.pi * 2 - difference;
      expect(
        difference,
        lessThan(.04),
        reason: 'node $index must not create a visible spline elbow',
      );
    }
  });

  test(
    'orbital route visibly bows between nodes instead of drawing chords',
    () {
      final geometry = GaussPathGeometry.build(
        width: 390,
        nodes: _nodes(26),
        textScale: 1,
      );
      final deviations = <double>[];
      for (var index = 0; index < geometry.positions.length - 1; index++) {
        final start = geometry.positions[index];
        final end = geometry.positions[index + 1];
        final metric = geometry.pathForSegment(index).computeMetrics().single;
        final midpoint = metric
            .getTangentForOffset(metric.length * .5)!
            .position;
        final chord = end - start;
        final distance =
            ((midpoint.dx - start.dx) * chord.dy -
                    (midpoint.dy - start.dy) * chord.dx)
                .abs() /
            chord.distance;
        deviations.add(distance);
      }

      expect(
        deviations.where((distance) => distance >= .8).length,
        greaterThanOrEqualTo((deviations.length * .7).floor()),
        reason: 'most stations need a visible circular bow: $deviations',
      );
      expect(
        deviations.reduce(math.max),
        greaterThan(2.5),
        reason: 'the route needs at least one broad turn per screenful',
      );
      expect(
        geometry
            .pathForSegments(
              List.generate(geometry.positions.length - 1, (index) => index),
            )
            .computeMetrics()
            .length,
        1,
        reason: 'contiguous stations must paint as one rail, not capped lines',
      );
    },
  );
}

List<StudyPathNode> _nodes(int count) => [
  for (var index = 0; index < count; index++)
    StudyPathNode(
      key: 'topic-${index ~/ 5}:${index % 5}:5',
      topic: TopicDescriptor(
        subject: Subject.math,
        key: 'topic-${index ~/ 5}',
        label: 'Topic ${index ~/ 5 + 1}',
        order: index ~/ 5,
        assetPath: '',
        questionCount: 25,
        missionReadyCount: 25,
      ),
      offset: (index % 5) * 5,
      questionCount: 5,
      partIndex: index % 5,
      partCount: 5,
    ),
];
