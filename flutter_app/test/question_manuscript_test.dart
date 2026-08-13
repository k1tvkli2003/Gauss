import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/widgets/question_manuscript.dart';
import 'package:gauss/widgets/scratchpad.dart';
import 'package:gauss/widgets/theorem_lens.dart';

void main() {
  testWidgets(
    'manuscript reflows at 320dp 200 percent with English tools and 48dp targets',
    (tester) async {
      final ink = ScratchInkController();
      addTearDown(ink.dispose);
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: QuestionManuscript(
                  ink: ink,
                  questionNumber: 1,
                  difficulty: 'Hard',
                  onExpandInk: () {},
                  onClearInk: ink.clear,
                  onRestoreInk: ink.restoreLastClear,
                  prompt: const Text(
                    'اگر 12 باشد، مقدار را پیدا کنید.',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: GaussColors.parchmentInk),
                  ),
                  answers: Column(
                    children: List.generate(
                      4,
                      (index) => ManuscriptChoiceShell(
                        tone: TheoremChoiceTone.neutral,
                        emblem: Text(String.fromCharCode(65 + index)),
                        onTap: () {},
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: GaussColors.parchmentInk,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('QUESTION 1'), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final label in <String>[
        'Finger pen',
        'Touch scroll',
        'Undo last stroke',
        'Open full scratchpad',
        'Stroke eraser',
        'Clear ink',
      ]) {
        final control = find.bySemanticsLabel(label);
        expect(control, findsOneWidget, reason: label);
        final rect = tester.getRect(control);
        expect(rect.width, greaterThanOrEqualTo(48), reason: label);
        expect(rect.height, greaterThanOrEqualTo(48), reason: label);
        expect(rect.left, greaterThanOrEqualTo(0), reason: label);
        expect(rect.right, lessThanOrEqualTo(320), reason: label);
      }
    },
  );

  testWidgets('finger pen and stroke eraser are functional', (tester) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    await tester.binding.setSurfaceSize(const Size(411, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuestionManuscript(
              ink: ink,
              questionNumber: 2,
              difficulty: 'Above average',
              onExpandInk: () {},
              onClearInk: ink.clear,
              onRestoreInk: ink.restoreLastClear,
              prompt: const SizedBox(height: 80),
              answers: const SizedBox(height: 80),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('manuscript-pen-tool')));
    await tester.pump();
    final writing = tester.getRect(
      find.byKey(const ValueKey('question-manuscript-writing-space')),
    );
    final strokeStart = writing.centerLeft + const Offset(30, 0);
    final finger = await tester.startGesture(
      strokeStart,
      pointer: 501,
      kind: PointerDeviceKind.touch,
    );
    await finger.moveBy(const Offset(80, 4));
    await finger.up();
    await tester.pump();
    expect(ink.strokeCount, 1);

    await tester.tap(find.byKey(const ValueKey('manuscript-eraser-tool')));
    await tester.pump();
    final eraser = await tester.startGesture(
      strokeStart,
      pointer: 502,
      kind: PointerDeviceKind.touch,
    );
    await eraser.up();
    await tester.pump();
    expect(ink.strokeCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal phone keeps the manuscript tools on its left spine', (
    tester,
  ) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    await tester.binding.setSurfaceSize(const Size(411, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: QuestionManuscript(
              ink: ink,
              questionNumber: 1,
              difficulty: 'Hard',
              onExpandInk: () {},
              onClearInk: ink.clear,
              onRestoreInk: ink.restoreLastClear,
              prompt: const SizedBox(height: 120),
              answers: const SizedBox(height: 320),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pen = tester.getRect(
      find.byKey(const ValueKey('manuscript-pen-tool')),
    );
    final pan = tester.getRect(
      find.byKey(const ValueKey('manuscript-pan-tool')),
    );
    final question = tester.getRect(
      find.byKey(const ValueKey('question-manuscript-number')),
    );
    expect(pan.top, greaterThan(pen.bottom));
    expect(pen.right, lessThan(question.left));
    expect(tester.takeException(), isNull);
  });
}
