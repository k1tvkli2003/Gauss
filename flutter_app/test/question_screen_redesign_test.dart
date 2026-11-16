import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/features/manuscript/question_manuscript.dart';
import 'package:gauss/features/manuscript/question_progress_rail.dart';
import 'package:gauss/features/manuscript/theorem_lens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

Widget _host(
  Widget child, {
  double textScale = 1,
  bool reducedMotion = false,
}) => MaterialApp(
  theme: buildGaussTheme(),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reducedMotion,
    ),
    child: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

Color _segmentColor(WidgetTester tester, int step) {
  final box = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('question-progress-segment-$step')),
  );
  return (box.decoration! as ShapeDecoration).color!;
}

void main() {
  testWidgets('session meter colors each recorded result', (tester) async {
    await tester.pumpWidget(
      _host(
        const QuestionProgressRail(
          index: 2,
          total: 5,
          label: 'Sets',
          outcomes: {0: true, 1: false},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_segmentColor(tester, 0), GaussColors.signalBright);
    expect(_segmentColor(tester, 1), GaussColors.error);
    expect(_segmentColor(tester, 2), GaussColors.brassLight);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('1 of 2 answered correctly')),
      findsOneWidget,
    );
    // The current question also reads by shape: its segment is wider.
    final current = tester.getSize(
      find.byKey(const ValueKey('question-progress-segment-2')),
    );
    final next = tester.getSize(
      find.byKey(const ValueKey('question-progress-segment-3')),
    );
    expect(current.width, greaterThan(next.width));
  });

  testWidgets('choice number sits on the reading side of RTL content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ManuscriptChoiceShell(
          key: const ValueKey('choice'),
          tone: TheoremChoiceTone.neutral,
          emblem: const Text('2'),
          onTap: () {},
          child: const Text('دو', textDirection: TextDirection.rtl),
        ),
      ),
    );
    final row = tester.getRect(find.byKey(const ValueKey('choice')));
    final number = tester.getRect(find.text('2'));
    expect(number.center.dx, greaterThan(row.center.dx));
    expect(tester.getSize(find.byType(InkWell)).height, greaterThan(48));
  });

  testWidgets('a checked choice settles without throwing under reduced '
      'motion', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManuscriptChoiceShell(
          tone: TheoremChoiceTone.positive,
          emblem: Icon(Icons.check_rounded),
          onTap: null,
          child: Text('x'),
        ),
        reducedMotion: true,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
