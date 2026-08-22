import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/models.dart';
import '../domain/study_curriculum.dart';

@immutable
final class GaussPathGeometry {
  const GaussPathGeometry({
    required this.positions,
    required this.tangents,
    required this.unitHeaders,
    required this.landmarks,
    required this.bands,
    required this.nodeSize,
    required this.height,
  });

  final List<Offset> positions;

  /// Unit-y tangent vectors sampled from the authored orbital curve.
  /// Keeping them with the geometry lets separately painted lazy bands share
  /// the exact same curve direction at every lesson station.
  final List<Offset> tangents;
  final List<GaussUnitHeaderGeometry> unitHeaders;
  final List<GaussLandmarkGeometry> landmarks;
  final List<GaussPathBand> bands;
  final double nodeSize;
  final double height;

  /// A continuous large-radius orbital curve, not straight chords joined at
  /// lesson stations. The stored analytic tangents make every cubic segment
  /// meet its neighbours without elbows while preserving visible, gentle
  /// curvature between nodes.
  Path pathForSegment(int index) {
    assert(index >= 0 && index < positions.length - 1);
    final path = Path();
    _appendSegment(path, index, moveToStart: true);
    return path;
  }

  /// Builds one uninterrupted rail for a contiguous lazy-render band. This
  /// avoids round-capped mini-lines between stations while allowing active
  /// progress overlays to keep their own state-specific styling.
  Path pathForSegments(Iterable<int> indices) {
    final path = Path();
    int? previous;
    for (final index in indices) {
      assert(index >= 0 && index < positions.length - 1);
      _appendSegment(path, index, moveToStart: previous != index - 1);
      previous = index;
    }
    return path;
  }

  void _appendSegment(Path path, int index, {required bool moveToStart}) {
    final start = positions[index];
    final end = positions[index + 1];
    final thirdHeight = (end.dy - start.dy) / 3;
    final control1 = start + tangents[index] * thirdHeight;
    final control2 = end - tangents[index + 1] * thirdHeight;
    if (moveToStart) path.moveTo(start.dx, start.dy);
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
  }

  static GaussPathGeometry build({
    required double width,
    required List<StudyPathNode> nodes,
    required double textScale,
  }) {
    final compact = width < 560;
    final expanded = width >= 760;
    final scale = textScale.clamp(1.0, 2.0).toDouble();
    final nodeSize = compact
        ? 76.0
        : expanded
        ? 110.0
        : 94.0;
    final center = width / 2;
    final amplitude = math.min(
      width *
          (compact
              ? .27
              : expanded
              ? .31
              : .29),
      expanded ? 246.0 : 184.0,
    );
    final positions = <Offset>[];
    final tangents = <Offset>[];
    final headers = <GaussUnitHeaderGeometry>[];
    final landmarks = <GaussLandmarkGeometry>[];
    // The compact first chapter lives in Orbit Navigator, so it has no unit
    // gate to create vertical clearance. Reserve the complete emphasized
    // station envelope here (including its 1.28x aura and selected scale),
    // not merely the 76dp image box; otherwise the first orbit ring touches
    // the fixed Orbit header even though the node centre technically fits.
    var y = compact ? 72.0 : 40.0;
    var unitNumber = 0;

    // One slow orbital wave spans many micro-lessons. Its radius is hundreds
    // of logical pixels, so it reads like a small window onto a much larger
    // celestial circle instead of a zig-zag made from short straight lines.
    // A restrained second harmonic removes sterile repetition without
    // introducing kinks or changing the large-radius character.
    final wavelength = compact
        ? 1120.0
        : expanded
        ? 2000.0
        : 1380.0;
    final angularRate = math.pi * 2 / wavelength;
    const routePhase = -.25;
    double routeX(double routeY) {
      final angle = routeY * angularRate + routePhase;
      final orbit = .92 * math.sin(angle) + .08 * math.sin(2 * angle + .7);
      return center + amplitude * orbit;
    }

    Offset routeTangent(double routeY) {
      final angle = routeY * angularRate + routePhase;
      final derivative =
          amplitude *
          angularRate *
          (.92 * math.cos(angle) + .16 * math.cos(2 * angle + .7));
      return Offset(derivative, 1);
    }

    const compactCadence = <double>[120, 110, 132, 116, 128, 108, 136, 118];
    const regularCadence = <double>[148, 136, 162, 142, 154, 134, 166, 146];

    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      if (node.beginsUnit) {
        unitNumber++;
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
                    ? 174.0
                    : 100 + 26 * (scale - 1)
              : 82 + 28 * (scale - 1);
          headers.add(
            GaussUnitHeaderGeometry(
              topic: node.topic,
              unitNumber: unitNumber,
              nodeIndex: index,
              y: y,
              height: gateHeight,
            ),
          );
          y +=
              gateHeight +
              (compact
                  ? accessibilityCompact
                        ? 14
                        : 50
                  : 52);
        }
      }

      final x = routeX(y);
      positions.add(Offset(x, y));
      tangents.add(routeTangent(y));
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
          GaussLandmarkGeometry(
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
      final cadence = compact
          ? compactCadence[index % compactCadence.length]
          : regularCadence[index % regularCadence.length] + (expanded ? 12 : 0);
      // The extra first-station header clearance is recovered inside the
      // first rail segment so every later lesson retains its proven position
      // and bottom-HUD clearance.
      final firstRailRecovery = compact && index == 0 ? 8.0 : 0.0;
      y +=
          cadence -
          firstRailRecovery +
          (compact ? 32 : 22) * (scale - 1);
    }

    // Finish the authored scene at its last real visual, not one full cadence
    // plus an arbitrary footer reservoir beyond it. The viewport adds the
    // live HUD obstruction separately, so retaining the post-last cadence
    // here strands the final lesson near the top of an otherwise empty
    // screen at max scroll.
    final lastNodeBottom = positions.isEmpty
        ? 0.0
        : positions.last.dy + nodeSize / 2;
    final lastHeaderBottom = headers.fold<double>(
      0,
      (bottom, header) => math.max(bottom, header.y + header.height),
    );
    final lastLandmarkBottom = landmarks.fold<double>(
      0,
      (bottom, landmark) => math.max(bottom, landmark.top + landmark.size),
    );
    final height =
        math.max(
          lastNodeBottom,
          math.max(lastHeaderBottom, lastLandmarkBottom),
        ) +
        (compact ? 32 : 40);
    final bands = GaussPathBand.partition(
      positions: positions,
      headers: headers,
      landmarks: landmarks,
      nodeSize: nodeSize,
      sceneHeight: height,
      compact: compact,
    );
    return GaussPathGeometry(
      positions: List.unmodifiable(positions),
      tangents: List.unmodifiable(tangents),
      unitHeaders: List.unmodifiable(headers),
      landmarks: List.unmodifiable(landmarks),
      bands: List.unmodifiable(bands),
      nodeSize: nodeSize,
      height: height,
    );
  }
}

@immutable
final class GaussUnitHeaderGeometry {
  const GaussUnitHeaderGeometry({
    required this.topic,
    required this.unitNumber,
    required this.nodeIndex,
    required this.y,
    required this.height,
  });

  final TopicDescriptor topic;
  final int unitNumber;
  final int nodeIndex;
  final double y;
  final double height;
}

@immutable
final class GaussLandmarkGeometry {
  const GaussLandmarkGeometry({
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

@immutable
final class GaussPathBand {
  const GaussPathBand({
    required this.index,
    required this.top,
    required this.bottom,
    required this.nodeIndices,
    required this.headerIndices,
    required this.landmarkIndices,
    required this.segmentIndices,
  });

  final int index;
  final double top;
  final double bottom;
  final List<int> nodeIndices;
  final List<int> headerIndices;
  final List<int> landmarkIndices;
  final List<int> segmentIndices;

  double get height => bottom - top;

  Offset localize(Offset global) => Offset(global.dx, global.dy - top);

  static List<GaussPathBand> partition({
    required List<Offset> positions,
    required List<GaussUnitHeaderGeometry> headers,
    required List<GaussLandmarkGeometry> landmarks,
    required double nodeSize,
    required double sceneHeight,
    required bool compact,
  }) {
    if (sceneHeight <= 0) return const [];
    final protected = <_ProtectedInterval>[
      for (final position in positions)
        _ProtectedInterval(
          position.dy - (nodeSize / 2 + 8),
          position.dy + (nodeSize / 2 + 8),
        ),
      for (final header in headers)
        _ProtectedInterval(header.y - 12, header.y + header.height + 12),
      for (final landmark in landmarks)
        _ProtectedInterval(landmark.top - 8, landmark.top + landmark.size + 8),
    ]..sort((a, b) => a.start.compareTo(b.start));

    final targetExtent = compact ? 620.0 : 760.0;
    const minimumExtent = 360.0;
    final boundaries = <double>[0];
    var start = 0.0;
    while (start + targetExtent < sceneHeight) {
      var boundary = start + targetExtent;
      for (var pass = 0; pass < protected.length + 1; pass++) {
        final collision = protected.cast<_ProtectedInterval?>().firstWhere(
          (interval) => interval!.contains(boundary),
          orElse: () => null,
        );
        if (collision == null) break;
        final before = collision.start - 16;
        final after = collision.end + 16;
        boundary = before - start >= minimumExtent ? before : after;
      }
      if (sceneHeight - boundary < minimumExtent * .65) break;
      if (boundary <= start + minimumExtent * .65) {
        boundary = start + targetExtent;
      }
      boundaries.add(boundary.clamp(start + 1, sceneHeight).toDouble());
      start = boundaries.last;
    }
    boundaries.add(sceneHeight);

    return [
      for (var bandIndex = 0; bandIndex < boundaries.length - 1; bandIndex++)
        _buildBand(
          index: bandIndex,
          top: boundaries[bandIndex],
          bottom: boundaries[bandIndex + 1],
          positions: positions,
          headers: headers,
          landmarks: landmarks,
        ),
    ];
  }

  static GaussPathBand _buildBand({
    required int index,
    required double top,
    required double bottom,
    required List<Offset> positions,
    required List<GaussUnitHeaderGeometry> headers,
    required List<GaussLandmarkGeometry> landmarks,
  }) => GaussPathBand(
    index: index,
    top: top,
    bottom: bottom,
    nodeIndices: List.unmodifiable([
      for (var item = 0; item < positions.length; item++)
        if (_owns(positions[item].dy, top, bottom)) item,
    ]),
    headerIndices: List.unmodifiable([
      for (var item = 0; item < headers.length; item++)
        if (_owns(headers[item].y + headers[item].height / 2, top, bottom))
          item,
    ]),
    landmarkIndices: List.unmodifiable([
      for (var item = 0; item < landmarks.length; item++)
        if (_owns(landmarks[item].top + landmarks[item].size / 2, top, bottom))
          item,
    ]),
    segmentIndices: List.unmodifiable([
      for (var item = 0; item < positions.length - 1; item++)
        if (math.max(positions[item].dy, positions[item + 1].dy) >= top - 24 &&
            math.min(positions[item].dy, positions[item + 1].dy) <= bottom + 24)
          item,
    ]),
  );

  static bool _owns(double value, double top, double bottom) =>
      value >= top && value < bottom;
}

final class _ProtectedInterval {
  const _ProtectedInterval(this.start, this.end);

  final double start;
  final double end;

  bool contains(double value) => value > start && value < end;
}

/// Small LRU cache keyed by the only inputs that can alter deterministic path
/// geometry. It survives selection/progress rebuilds without retaining an
/// unbounded number of course layouts.
final class GaussPathGeometryCache {
  GaussPathGeometryCache({this.maxEntries = 8}) : assert(maxEntries > 0);

  final int maxEntries;
  final LinkedHashMap<_GaussPathGeometryKey, GaussPathGeometry> _entries =
      LinkedHashMap();

  int hits = 0;
  int misses = 0;

  GaussPathGeometry resolve({
    required String sectionId,
    required double width,
    required List<StudyPathNode> nodes,
    required double textScale,
  }) {
    final normalizedWidth = (width * 2).round() / 2;
    final normalizedScale = textScaleBucket(textScale);
    final key = _GaussPathGeometryKey(
      sectionId: sectionId,
      width: normalizedWidth,
      textScale: normalizedScale,
      nodeSignature: Object.hashAll([
        for (final node in nodes)
          Object.hash(
            node.key,
            node.topic.key,
            node.partIndex,
            node.partCount,
            node.questionCount,
          ),
      ]),
    );
    final cached = _entries.remove(key);
    if (cached != null) {
      hits++;
      _entries[key] = cached;
      return cached;
    }
    misses++;
    final geometry = GaussPathGeometry.build(
      width: normalizedWidth,
      nodes: nodes,
      textScale: normalizedScale,
    );
    _entries[key] = geometry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return geometry;
  }

  int get length => _entries.length;

  void clear() => _entries.clear();

  static double textScaleBucket(double value) {
    final scale = value.clamp(1.0, 2.0).toDouble();
    if (scale <= 1) return 1;
    if (scale <= 1.25) return 1.25;
    if (scale < 1.55) return 1.55;
    return 2;
  }
}

@immutable
final class _GaussPathGeometryKey {
  const _GaussPathGeometryKey({
    required this.sectionId,
    required this.width,
    required this.textScale,
    required this.nodeSignature,
  });

  final String sectionId;
  final double width;
  final double textScale;
  final int nodeSignature;

  @override
  bool operator ==(Object other) =>
      other is _GaussPathGeometryKey &&
      other.sectionId == sectionId &&
      other.width == width &&
      other.textScale == textScale &&
      other.nodeSignature == nodeSignature;

  @override
  int get hashCode => Object.hash(sectionId, width, textScale, nodeSignature);
}
