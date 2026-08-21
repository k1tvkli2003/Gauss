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
