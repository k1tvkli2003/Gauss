// Renders a fast synthetic stylus stroke for visual review. Opt-in:
//   GAUSS_CAPTURE_DIR=/abs/out flutter test test/visual/ink_capture_test.dart
@Tags(['capture'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/features/manuscript/scratchpad.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

final _outDir = Platform.environment['GAUSS_CAPTURE_DIR'];

void main() {
  testWidgets('capture fast ink stroke', (tester) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    final key = GlobalKey();
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: InlineQuestionScratch(
              controller: ink,
              child: Container(height: 200, color: GaussColors.parchment),
            ),
          ),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(InlineQuestionScratch));
    final pen = await tester.startGesture(
      origin + const Offset(16, 100),
      pointer: 7,
      kind: PointerDeviceKind.stylus,
    );
    // Sparse samples (a fast flick) are where faceting shows.
    for (var i = 1; i <= 18; i++) {
      final x = 16 + i * 15.0;
      final y = 100 + math.sin(i / 2.2) * 60;
      await pen.moveTo(origin + Offset(x, y));
    }
    await pen.up();
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(_outDir!).createSync(recursive: true);
      File('$_outDir/ink.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }, skip: _outDir == null);
}
