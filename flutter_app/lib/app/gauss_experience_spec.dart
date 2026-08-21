import 'package:flutter/widgets.dart';

/// The two showpiece surfaces whose accepted visual references are binding.
enum GaussShowpieceSurface { map, question }

/// How a visual layer is produced.
enum GaussLayerKind {
  /// Decorative pixels with no embedded product truth or interaction.
  raster,

  /// Resolution-independent geometry painted from live state.
  vector,

  /// Selectable, focusable, readable Flutter content.
  liveSemantic,

  /// A decorative asset composed with live state and a semantic equivalent.
  hybrid,
}

/// The narrowest owner that may invalidate a layer.
enum GaussRepaintPolicy {
  staticScene,
  viewportBand,
  stateBoundary,
  inkStroke,
  transientOverlay,
}

/// Back-to-front production order. Adjacent planes may share a repaint
/// boundary only when their invalidation policy is identical.
enum GaussZPlane { atmosphere, material, route, content, chrome, transient }

@immutable
final class GaussLayerSpec {
  const GaussLayerSpec({
    required this.id,
    required this.surface,
    required this.kind,
    required this.plane,
    required this.repaintPolicy,
    required this.semantic,
    required this.interactive,
    this.assetPaths = const [],
  });

  final String id;
  final GaussShowpieceSurface surface;
  final GaussLayerKind kind;
  final GaussZPlane plane;
  final GaussRepaintPolicy repaintPolicy;
  final bool semantic;
  final bool interactive;
  final List<String> assetPaths;
}

/// Binding production manifest for the accepted Celestial Expedition Map and
/// Writable Astral Manuscript. It prevents a future implementation from
/// flattening live data into screenshots or attaching expensive effects to a
/// whole scrolling scene.
abstract final class GaussProductionManifest {
  static const map = <GaussLayerSpec>[
    GaussLayerSpec(
      id: 'map.atmosphere',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.raster,
      plane: GaussZPlane.atmosphere,
      repaintPolicy: GaussRepaintPolicy.staticScene,
      semantic: false,
      interactive: false,
      assetPaths: ['assets/visual/map/orrery_atmosphere_portrait.png'],
    ),
    GaussLayerSpec(
      id: 'map.celestial-grid',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.vector,
      plane: GaussZPlane.material,
      repaintPolicy: GaussRepaintPolicy.viewportBand,
      semantic: false,
      interactive: false,
    ),
    GaussLayerSpec(
      id: 'map.continuous-route',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.vector,
      plane: GaussZPlane.route,
      repaintPolicy: GaussRepaintPolicy.viewportBand,
      semantic: false,
      interactive: false,
    ),
    GaussLayerSpec(
      id: 'map.landmarks',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.raster,
      plane: GaussZPlane.route,
      repaintPolicy: GaussRepaintPolicy.viewportBand,
      semantic: false,
      interactive: false,
      assetPaths: [
        'assets/visual/map/theorem_engine.png',
        'assets/visual/nodes/boss_observatory.png',
      ],
    ),
    GaussLayerSpec(
      id: 'map.lesson-instruments',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.hybrid,
      plane: GaussZPlane.content,
      repaintPolicy: GaussRepaintPolicy.viewportBand,
      semantic: true,
      interactive: true,
      assetPaths: ['assets/visual/nodes/topic_shell.png'],
    ),
    GaussLayerSpec(
      id: 'map.chapter-annotations',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.content,
      repaintPolicy: GaussRepaintPolicy.viewportBand,
      semantic: true,
      interactive: false,
    ),
    GaussLayerSpec(
      id: 'map.orbit-navigator',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.chrome,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
    ),
    GaussLayerSpec(
      id: 'map.mission-compass',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.hybrid,
      plane: GaussZPlane.chrome,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
      assetPaths: ['assets/visual/brand/theorem_star.svg'],
    ),
    GaussLayerSpec(
      id: 'map.navigation',
      surface: GaussShowpieceSurface.map,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.chrome,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
    ),
  ];

  static const question = <GaussLayerSpec>[
    GaussLayerSpec(
      id: 'question.atmosphere',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.raster,
      plane: GaussZPlane.atmosphere,
      repaintPolicy: GaussRepaintPolicy.staticScene,
      semantic: false,
      interactive: false,
      assetPaths: ['assets/visual/map/orrery_atmosphere_portrait.png'],
    ),
    GaussLayerSpec(
      id: 'question.parchment',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.raster,
      plane: GaussZPlane.material,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: false,
      interactive: false,
      assetPaths: ['assets/visual/question/manuscript_parchment_v1.png'],
    ),
    GaussLayerSpec(
      id: 'question.progress',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.chrome,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: false,
    ),
    GaussLayerSpec(
      id: 'question.prompt-and-media',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.hybrid,
      plane: GaussZPlane.content,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: false,
    ),
    GaussLayerSpec(
      id: 'question.ink',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.hybrid,
      plane: GaussZPlane.content,
      repaintPolicy: GaussRepaintPolicy.inkStroke,
      semantic: true,
      interactive: true,
    ),
    GaussLayerSpec(
      id: 'question.context-tools',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.chrome,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
    ),
    GaussLayerSpec(
      id: 'question.answer-rails',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.content,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
    ),
    GaussLayerSpec(
      id: 'question.solve-instrument',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.chrome,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
    ),
    GaussLayerSpec(
      id: 'question.solution-and-reflection',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.liveSemantic,
      plane: GaussZPlane.content,
      repaintPolicy: GaussRepaintPolicy.stateBoundary,
      semantic: true,
      interactive: true,
    ),
    GaussLayerSpec(
      id: 'question.completion',
      surface: GaussShowpieceSurface.question,
      kind: GaussLayerKind.hybrid,
      plane: GaussZPlane.transient,
      repaintPolicy: GaussRepaintPolicy.transientOverlay,
      semantic: true,
      interactive: true,
      assetPaths: ['assets/visual/mascot/mira_correct.png'],
    ),
  ];

  static const all = <GaussLayerSpec>[...map, ...question];
}

enum GaussMapAcceptanceState {
  loading,
  offlineReady,
  current,
  selected,
  completed,
  locked,
  allMastered,
  empty,
  error,
}

enum GaussQuestionAcceptanceState {
  loading,
  prompt,
  inkActive,
  choiceSelected,
  checking,
  correct,
  incorrect,
  sourceWarning,
  solution,
  completion,
  saveError,
}

@immutable
final class GaussAcceptanceShot {
  const GaussAcceptanceShot({
    required this.id,
    required this.surface,
    required this.logicalSize,
    required this.textScale,
    required this.state,
    required this.anchor,
  });

  final String id;
  final GaussShowpieceSurface surface;
  final Size logicalSize;
  final double textScale;
  final String state;
  final String anchor;
}

/// Screenshot positions that later phase gates must close against the same
/// revision and viewport. They are intentionally declarative so capture tools
/// and tests can consume the same list.
abstract final class GaussAcceptanceMatrix {
  static const shots = <GaussAcceptanceShot>[
    GaussAcceptanceShot(
      id: 'map-phone-start',
      surface: GaussShowpieceSurface.map,
      logicalSize: Size(360, 800),
      textScale: 1,
      state: 'current',
      anchor: 'first-node',
    ),
    GaussAcceptanceShot(
      id: 'map-phone-middle-selected',
      surface: GaussShowpieceSurface.map,
      logicalSize: Size(390, 844),
      textScale: 1,
      state: 'selected',
      anchor: 'middle-node',
    ),
    GaussAcceptanceShot(
      id: 'map-phone-end-completed',
      surface: GaussShowpieceSurface.map,
      logicalSize: Size(430, 932),
      textScale: 1,
      state: 'completed',
      anchor: 'last-node',
    ),
    GaussAcceptanceShot(
      id: 'map-narrow-accessible',
      surface: GaussShowpieceSurface.map,
      logicalSize: Size(320, 568),
      textScale: 2,
      state: 'current',
      anchor: 'first-node',
    ),
    GaussAcceptanceShot(
      id: 'map-tablet-portrait',
      surface: GaussShowpieceSurface.map,
      logicalSize: Size(800, 1280),
      textScale: 1,
      state: 'selected',
      anchor: 'middle-node',
    ),
    GaussAcceptanceShot(
      id: 'map-tablet-landscape',
      surface: GaussShowpieceSurface.map,
      logicalSize: Size(1280, 800),
      textScale: 1,
      state: 'selected+inspector',
      anchor: 'middle-node',
    ),
    GaussAcceptanceShot(
      id: 'question-phone-prompt',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(390, 844),
      textScale: 1,
      state: 'prompt',
      anchor: 'question-1',
    ),
    GaussAcceptanceShot(
      id: 'question-phone-ink',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(390, 844),
      textScale: 1,
      state: 'inkActive',
      anchor: 'question-1',
    ),
    GaussAcceptanceShot(
      id: 'question-phone-feedback',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(430, 932),
      textScale: 1,
      state: 'incorrect+solution',
      anchor: 'question-1',
    ),
    GaussAcceptanceShot(
      id: 'question-narrow-accessible',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(320, 568),
      textScale: 2,
      state: 'long-prompt',
      anchor: 'question-1',
    ),
    GaussAcceptanceShot(
      id: 'question-tablet-portrait',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(800, 1280),
      textScale: 1,
      state: 'choiceSelected',
      anchor: 'question-1',
    ),
    GaussAcceptanceShot(
      id: 'question-tablet-landscape',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(1280, 800),
      textScale: 1,
      state: 'incorrect+solution-pane',
      anchor: 'question-1',
    ),
    GaussAcceptanceShot(
      id: 'question-five-completion',
      surface: GaussShowpieceSurface.question,
      logicalSize: Size(390, 844),
      textScale: 1,
      state: 'completion',
      anchor: 'question-5',
    ),
  ];
}
