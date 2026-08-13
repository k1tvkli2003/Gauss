import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/widgets/content_blocks.dart';
import 'package:gauss/widgets/scratchpad.dart';

void main() {
  testWidgets(
    'stylus and eraser enter ink on down, pressure stays bounded, undo is immediate',
    (tester) async {
      final ink = ScratchInkController();
      addTearDown(ink.dispose);
      final plate = await _pumpInkPlate(tester, ink);
      expect(find.byKey(const ValueKey('inline-pen-halo')), findsNothing);

      final stylus = await tester.startGesture(
        plate.topLeft + const Offset(30, 45),
        pointer: 101,
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();
      expect(
        ink.strokeCount,
        1,
        reason: 'pen-down must leave a visible dot without waiting for motion',
      );
      await stylus.up();

      final eraser = await tester.startGesture(
        plate.topLeft + const Offset(65, 70),
        pointer: 102,
        kind: PointerDeviceKind.invertedStylus,
      );
      await tester.pump();
      expect(ink.strokeCount, 2);
      await eraser.cancel();
      await tester.pump();
      expect(
        ink.strokeCount,
        1,
        reason: 'cancel must roll back only the live eraser-end stroke',
      );

      final pressurePen = await tester.createGesture(
        pointer: 103,
        kind: PointerDeviceKind.stylus,
      );
      final pressureStart = plate.topLeft + const Offset(80, 90);
      final pressureEnd = pressureStart + const Offset(130, 35);
      await pressurePen.downWithCustomEvent(
        pressureStart,
        PointerDownEvent(
          pointer: 103,
          position: pressureStart,
          kind: PointerDeviceKind.stylus,
          pressure: 0,
          pressureMin: 0,
          pressureMax: 1,
        ),
      );
      await pressurePen.updateWithCustomEvent(
        PointerMoveEvent(
          pointer: 103,
          position: pressureEnd,
          delta: pressureEnd - pressureStart,
          kind: PointerDeviceKind.stylus,
          pressure: 1,
          pressureMin: 0,
          pressureMax: 1,
        ),
      );
      await pressurePen.up();
      await tester.pumpAndSettle();

      expect(ink.strokeCount, 2);
      expect(ink.recordedWidths, isNotEmpty);
      expect(ink.recordedWidths.every((width) => width >= .8), isTrue);
      expect(ink.recordedWidths.every((width) => width <= 7), isTrue);

      await tester.tap(find.byTooltip('Undo last stroke'));
      await tester.pumpAndSettle();
      expect(ink.strokeCount, 1);
      expect(find.byKey(const ValueKey('inline-pen-halo')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('inline-ink-clear')));
      await tester.pumpAndSettle();
      expect(ink.isEmpty, isTrue);
      expect(find.byKey(const ValueKey('inline-pen-halo')), findsNothing);
      expect(find.byKey(const ValueKey('inline-ink-restore')), findsOneWidget);
      expect(find.text('Restore ink'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('inline-ink-restore')));
      await tester.pumpAndSettle();
      expect(ink.strokeCount, 1);
      expect(find.byKey(const ValueKey('inline-pen-halo')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('inline-ink-clear')));
      await tester.pump();
      expect(find.byKey(const ValueKey('inline-ink-restore')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('inline-ink-restore')), findsNothing);
      expect(ink.canUndo, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'finger scrolls normally but a palm cannot scroll or interrupt live pen ink',
    (tester) async {
      final ink = ScratchInkController();
      final scroll = ScrollController();
      var answerTaps = 0;
      addTearDown(ink.dispose);
      addTearDown(scroll.dispose);
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  SizedBox(
                    width: 320,
                    child: InlineQuestionScratch(
                      controller: ink,
                      child: Container(
                        key: const ValueKey('question-with-answer'),
                        height: 220,
                        color: GaussColors.parchment,
                        alignment: Alignment.center,
                        child: FilledButton(
                          onPressed: () => answerTaps++,
                          child: const Text('Answer control'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 720),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final plate = tester.getRect(
        find.byKey(const ValueKey('question-with-answer')),
      );

      await tester.tap(find.text('Answer control'));
      expect(
        answerTaps,
        1,
        reason: 'pen-ready overlay must not eat answer taps',
      );

      await tester.dragFrom(
        plate.topLeft + const Offset(24, 35),
        const Offset(0, -100),
      );
      await tester.pump();
      expect(scroll.offset, greaterThan(0));
      expect(ink.isEmpty, isTrue);
      scroll.jumpTo(0);
      await tester.pump();

      final pen = await tester.startGesture(
        plate.topLeft + const Offset(35, 45),
        pointer: 111,
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();
      expect(ink.strokeCount, 1);

      final palm = await tester.startGesture(
        plate.topLeft + const Offset(90, 75),
        pointer: 112,
        kind: PointerDeviceKind.touch,
      );
      await palm.moveBy(const Offset(0, -120));
      await tester.pump();
      expect(
        scroll.offset,
        0,
        reason: 'touch contact during live pen ink must not move the page',
      );
      expect(
        ink.strokeCount,
        1,
        reason: 'the palm must neither draw nor replace the pen stroke',
      );
      await palm.up();
      await pen.moveBy(const Offset(110, 30));
      await pen.up();
      await tester.pump();
      expect(ink.strokeCount, 1);

      await tester.tap(find.text('Answer control'));
      expect(answerTaps, 2, reason: 'answer taps recover as soon as pen lifts');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Pen Halo reflows accessibly and expanded ink stays on the question',
    (tester) async {
      final ink = ScratchInkController();
      addTearDown(ink.dispose);
      final plate = await _pumpInkPlate(tester, ink);

      final pen = await tester.startGesture(
        plate.center,
        pointer: 121,
        kind: PointerDeviceKind.stylus,
      );
      await pen.moveBy(const Offset(72, 18));
      await pen.up();
      await tester.pumpAndSettle();

      final halo = find.byKey(const ValueKey('inline-pen-halo'));
      expect(halo, findsOneWidget);
      expect(find.bySemanticsLabel('Pen controls'), findsOneWidget);
      const labels = [
        'Undo last stroke',
        'Pen thickness',
        'Expand ink workspace',
        'Clear question ink',
      ];
      final controlRects = <Rect>[];
      for (final label in labels) {
        final control = find.bySemanticsLabel(label);
        expect(control, findsOneWidget, reason: label);
        final rect = tester.getRect(control);
        expect(rect.width, greaterThanOrEqualTo(48), reason: label);
        expect(rect.height, greaterThanOrEqualTo(48), reason: label);
        expect(rect.left, greaterThanOrEqualTo(0), reason: label);
        expect(rect.right, lessThanOrEqualTo(320), reason: label);
        controlRects.add(rect);
      }
      for (var first = 0; first < controlRects.length; first++) {
        for (var second = first + 1; second < controlRects.length; second++) {
          expect(
            controlRects[first].overlaps(controlRects[second]),
            isFalse,
            reason: 'Halo controls must not collide at 320dp and 200% text.',
          );
        }
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('inline-ink-expand')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scratchpad-sheet')), findsOneWidget);
      expect(find.text('Scratchpad'), findsOneWidget);
      expect(ink.strokeCount, 1);
      expect(tester.takeException(), isNull);

      final deepCanvas = tester.getRect(
        find.byKey(const ValueKey('scratchpad-ink-canvas')),
      );
      final deepPen = await tester.startGesture(
        deepCanvas.center,
        pointer: 122,
        kind: PointerDeviceKind.stylus,
      );
      await deepPen.moveBy(const Offset(54, -28));
      await deepPen.up();
      await tester.pump();
      expect(ink.strokeCount, 2);

      await tester.tap(find.byTooltip('Close scratchpad'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scratchpad-sheet')), findsNothing);
      expect(find.byKey(const ValueKey('inline-pen-halo')), findsOneWidget);
      expect(ink.strokeCount, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion reveals the Halo without a transition frame', (
    tester,
  ) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    final plate = await _pumpInkPlate(tester, ink, disableAnimations: true);

    final pen = await tester.startGesture(
      plate.center,
      pointer: 131,
      kind: PointerDeviceKind.stylus,
    );
    await pen.up();
    await tester.pump();

    expect(find.byKey(const ValueKey('inline-pen-halo')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('inline-pen-halo'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mixed RTL text keeps visual order and long math scrolls at 320dp 200 percent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(2),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ContentBlocksView(
                  blocks: [
                    TextBlock(r'قبل $x+1$ بعد'),
                    TextBlock(
                      r'$A \cap (B \cup C) \cap (D \cup E) \cap (F \cup G) \cap (H \cup I) \cap (J \cup K)$',
                    ),
                    TextBlock(
                      r'پاسخ: $$\frac{(a+b+c+d+e+f+g+h)^2}{x_1+x_2+x_3+x_4+x_5+x_6+x_7+x_8}$$',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final before = tester.getRect(find.text('قبل '));
      final formula = tester.getRect(
        find.byKey(const ValueKey('inline-math-1')),
      );
      final after = tester.getRect(find.text(' بعد'));
      expect(
        before.center.dx,
        greaterThan(formula.center.dx),
        reason: 'before=$before formula=$formula after=$after',
      );
      expect(
        after.top,
        greaterThan(formula.bottom),
        reason: 'before=$before formula=$formula after=$after',
      );

      final longFormula = tester.getRect(
        find.byKey(const ValueKey('inline-math-0')).last,
      );
      expect(longFormula.width, lessThanOrEqualTo(288));
      expect(
        tester
            .widget<SingleChildScrollView>(
              find.byKey(const ValueKey('inline-math-0')).last,
            )
            .scrollDirection,
        Axis.horizontal,
      );
      final longDisplay = find.byKey(const ValueKey('display-math-1'));
      expect(find.text('پاسخ: '), findsOneWidget);
      expect(tester.getRect(longDisplay).width, lessThanOrEqualTo(288));
      expect(
        tester.widget<SingleChildScrollView>(longDisplay).scrollDirection,
        Axis.horizontal,
      );
      expect(
        find.byIcon(Icons.swipe_rounded),
        findsWidgets,
        reason: 'Overflowing formulas need a visible horizontal-scroll cue.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid formula and missing media fail visibly without throwing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ContentBlocksView(
                blocks: [
                  TextBlock(r'فرمول ناسالم: $\notARealGaussCommand{1}$ پایان'),
                  ImageBlock(
                    asset: 'missing-focus-pen-fixture.png',
                    alt: 'نمودار منبع در دسترس نیست',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('math-error-1')), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('media-error-missing-focus-pen-fixture.png')),
        findsOneWidget,
      );
      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.text('نمودار منبع در دسترس نیست'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<Rect> _pumpInkPlate(
  WidgetTester tester,
  ScratchInkController ink, {
  bool disableAnimations = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 560));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 560),
          textScaler: TextScaler.linear(2),
        ).copyWith(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 288,
              child: InlineQuestionScratch(
                controller: ink,
                child: Container(
                  key: const ValueKey('ink-test-plate'),
                  height: 220,
                  color: GaussColors.parchment,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getRect(find.byKey(const ValueKey('ink-test-plate')));
}
