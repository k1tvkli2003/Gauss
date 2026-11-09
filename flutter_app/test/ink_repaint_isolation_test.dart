import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/features/manuscript/scratchpad.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

class _CountingPainter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  testWidgets('pen samples repaint the ink layer, never the question', (
    tester,
  ) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    final content = _CountingPainter();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: Scaffold(
          body: InlineQuestionScratch(
            controller: ink,
            child: CustomPaint(
              painter: content,
              child: const SizedBox(height: 240, width: 320),
            ),
          ),
        ),
      ),
    );
    final before = content.paints;
    final origin = tester.getTopLeft(find.byType(InlineQuestionScratch));
    final pen = await tester.startGesture(
      origin + const Offset(20, 40),
      pointer: 3,
      kind: PointerDeviceKind.stylus,
    );
    for (var i = 1; i <= 30; i++) {
      await pen.moveTo(origin + Offset(20 + i * 8.0, 40 + (i % 5) * 6.0));
      await tester.pump();
    }
    await pen.up();
    await tester.pump();
    expect(ink.strokeCount, 1);
    expect(content.paints, before, reason: 'question content stayed cached');
  });
}
