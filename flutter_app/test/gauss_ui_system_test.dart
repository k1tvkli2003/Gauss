import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_design_system.dart';
import 'package:gauss/app/gauss_experience_spec.dart';
import 'package:gauss/app/gauss_theme.dart';

void main() {
  test(
    'design ramps are ordered and every interaction tier is at least 48dp',
    () {
      expect(const [
        GaussSpacing.space4,
        GaussSpacing.space8,
        GaussSpacing.space12,
        GaussSpacing.space16,
        GaussSpacing.space20,
        GaussSpacing.space24,
        GaussSpacing.space32,
        GaussSpacing.space40,
        GaussSpacing.space48,
        GaussSpacing.space56,
        GaussSpacing.space64,
      ], orderedEquals(const [4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64]));
      expect(const [
        GaussTypeScale.insignia,
        GaussTypeScale.caption,
        GaussTypeScale.metadata,
        GaussTypeScale.body,
        GaussTypeScale.bodyLarge,
        GaussTypeScale.title,
        GaussTypeScale.titleLarge,
        GaussTypeScale.headline,
        GaussTypeScale.display,
      ], orderedEquals(const [10, 11, 12, 14, 16, 18, 22, 28, 36]));
      for (final target in const [
        GaussHitTargets.minimum,
        GaussHitTargets.standard,
        GaussHitTargets.prominent,
        GaussHitTargets.hero,
      ]) {
        expect(target, greaterThanOrEqualTo(48));
      }
      expect(GaussMetrics.minTouchTarget, GaussHitTargets.minimum);
    },
  );

  test(
    'two-axis composition contracts cover narrow phone and tablet layouts',
    () {
      final narrow = GaussViewport.fromSize(const Size(320, 568));
      final portraitTablet = GaussViewport.fromSize(const Size(800, 1280));
      final landscapeTablet = GaussViewport.fromSize(const Size(1280, 800));

      expect(narrow.widthClass, GaussWindowClass.compact);
      expect(narrow.supportsTwoPane, isFalse);
      expect(portraitTablet.widthClass, GaussWindowClass.medium);
      expect(portraitTablet.isPortrait, isTrue);
      expect(landscapeTablet.supportsThreePane, isTrue);
      // The mission review workspace splits only in a three-pane landscape
      // window that keeps a readable stage height, and never at 200% text.
      expect(
        GaussComposition.usesQuestionSplit(
          viewport: landscapeTablet,
          textScale: 1,
          availableHeight: GaussBreakpoints.mediumHeight,
        ),
        isTrue,
      );
      expect(
        GaussComposition.usesQuestionSplit(
          viewport: landscapeTablet,
          textScale: GaussComposition.requiredMaximumTextScale,
          availableHeight: GaussBreakpoints.mediumHeight,
        ),
        isFalse,
      );
      expect(
        GaussComposition.usesQuestionSplit(
          viewport: portraitTablet,
          textScale: 1,
          availableHeight: GaussBreakpoints.mediumHeight,
        ),
        isFalse,
        reason: 'portrait windows keep the single-column manuscript',
      );
      expect(
        GaussComposition.usesQuestionSplit(
          viewport: landscapeTablet,
          textScale: 1,
          availableHeight: GaussBreakpoints.mediumHeight - 1,
        ),
        isFalse,
        reason: 'a chrome-reduced stage keeps the single-column manuscript',
      );
      expect(
        GaussComposition.mapTabletPathFraction +
            GaussComposition.mapTabletInspectorFraction,
        closeTo(1, .0001),
      );
      // The verified pane steps stay monotonic and the wide step only exists
      // beyond its threshold.
      expect(
        GaussComposition.questionSupportPaneWidth,
        lessThan(GaussComposition.questionSupportPaneWideWidth),
      );
      expect(
        GaussComposition.questionSupportPaneWideWidth,
        lessThan(GaussComposition.questionSupportPaneWideAt),
      );
      expect(GaussComposition.mapPhonePathMinFraction, greaterThan(.5));
      expect(GaussComposition.mapPhoneOverlayMaxFraction, lessThan(.25));
    },
  );

  test(
    'production manifests keep live truth semantic and raster art decorative',
    () {
      final ids = GaussProductionManifest.all.map((layer) => layer.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(GaussProductionManifest.map, isNotEmpty);
      expect(GaussProductionManifest.question, isNotEmpty);

      for (final layer in GaussProductionManifest.all) {
        if (layer.interactive) {
          expect(
            layer.kind,
            anyOf(GaussLayerKind.liveSemantic, GaussLayerKind.hybrid),
            reason: '${layer.id} cannot flatten an interaction into pixels',
          );
          expect(layer.semantic, isTrue, reason: layer.id);
        }
        if (layer.kind == GaussLayerKind.raster) {
          expect(layer.interactive, isFalse, reason: layer.id);
          expect(layer.semantic, isFalse, reason: layer.id);
        }
        for (final asset in layer.assetPaths) {
          expect(
            File(asset).existsSync(),
            isTrue,
            reason: '$asset (${layer.id})',
          );
        }
      }

      final ink = GaussProductionManifest.question.singleWhere(
        (layer) => layer.id == 'question.ink',
      );
      expect(ink.repaintPolicy, GaussRepaintPolicy.inkStroke);
      expect(ink.plane, GaussZPlane.content);
    },
  );

  test(
    'acceptance positions bind all required viewport families and key states',
    () {
      final shots = GaussAcceptanceMatrix.shots;
      final ids = shots.map((shot) => shot.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        shots.any(
          (shot) => shot.logicalSize == const Size(320, 568) &&
              shot.textScale == GaussComposition.requiredMaximumTextScale,
        ),
        isTrue,
        reason: 'the acceptance matrix must cover the required maximum text',
      );
      expect(
        shots.any(
          (shot) =>
              shot.surface == GaussShowpieceSurface.map &&
              shot.anchor == 'first-node',
        ),
        isTrue,
      );
      expect(
        shots.any(
          (shot) =>
              shot.surface == GaussShowpieceSurface.map &&
              shot.anchor == 'middle-node',
        ),
        isTrue,
      );
      expect(
        shots.any(
          (shot) =>
              shot.surface == GaussShowpieceSurface.map &&
              shot.anchor == 'last-node',
        ),
        isTrue,
      );
      expect(
        shots.any(
          (shot) =>
              shot.surface == GaussShowpieceSurface.question &&
              shot.anchor == 'question-5' &&
              shot.state == 'completion',
        ),
        isTrue,
      );
      expect(
        shots.any(
          (shot) =>
              shot.logicalSize == const Size(1280, 800) &&
              shot.state.contains('solution-pane'),
        ),
        isTrue,
      );
    },
  );

  test('core dark and parchment text pairs meet normal-text contrast', () {
    expect(_contrast(GaussColors.ivory, GaussColors.abyss), greaterThan(7));
    expect(_contrast(GaussColors.ivory, GaussColors.ink), greaterThan(7));
    expect(
      _contrast(GaussColors.parchmentInk, GaussColors.parchment),
      greaterThan(7),
    );
    expect(
      _contrast(GaussColors.fog, GaussColors.panelHigh),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(GaussColors.brassLight, GaussColors.deepInk),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(GaussColors.signalBright, GaussColors.deepInk),
      greaterThanOrEqualTo(4.5),
    );
  });

  test(
    'motion vocabulary stays brief and reserves ceremony for completion',
    () {
      expect(GaussMotion.micro, lessThan(GaussMotion.standard));
      expect(GaussMotion.standard, lessThan(GaussMotion.feedback));
      expect(GaussMotion.feedback, lessThan(GaussMotion.emphasized));
      expect(GaussMotion.emphasized, lessThan(GaussMotion.spatial));
      expect(GaussMotion.spatial, lessThan(GaussMotion.ceremonial));
      expect(GaussMotion.ceremonial, lessThan(const Duration(seconds: 1)));
    },
  );
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + .05) / (darker + .05);
}
