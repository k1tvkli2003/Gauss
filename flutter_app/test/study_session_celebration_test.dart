import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/widgets/study_session_celebration.dart';

void main() {
  testWidgets('shows every authoritative milestone in one truthful receipt', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var continued = 0;
    var stayed = 0;

    await _pumpCelebration(
      tester,
      outcome: _outcome(
        setCompleted: true,
        unitCompleted: true,
        dailyQuestCompleted: true,
        levelBefore: 3,
        levelAfter: 4,
      ),
      onPrimary: () => continued++,
      onStay: () => stayed++,
    );

    expect(find.text('Unit charted'), findsOneWidget);
    expect(find.text('Five-question orbit complete'), findsOneWidget);
    expect(find.text('Unit orbit complete'), findsOneWidget);
    expect(find.text('Today’s observation recorded'), findsOneWidget);
    expect(find.text('Level 4 reached'), findsOneWidget);
    expect(find.text('+73 XP'), findsOneWidget);
    expect(find.text('913 XP'), findsOneWidget);
    expect(find.text('Question charted'), findsOneWidget);
    expect(find.text('Study set complete'), findsOneWidget);
    expect(find.text('Unit complete'), findsOneWidget);
    expect(find.text('Daily observation'), findsOneWidget);
    expect(find.textContaining('Share'), findsNothing);
    expect(find.textContaining('League'), findsNothing);
    expect(find.textContaining('Heart'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('study-celebration-primary')),
    );
    await tester.tap(find.byKey(const ValueKey('study-celebration-primary')));
    expect(continued, 1);
    await tester.tap(find.byKey(const ValueKey('study-celebration-stay')));
    expect(stayed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not invent quest, unit, or level milestones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpCelebration(
      tester,
      outcome: _outcome(
        setCompleted: true,
        unitCompleted: false,
        dailyQuestCompleted: false,
        levelBefore: 3,
        levelAfter: 3,
      ),
    );

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Five-question orbit complete'), findsOneWidget);
    expect(find.text('Unit orbit complete'), findsNothing);
    expect(find.text('Daily observation complete'), findsNothing);
    expect(find.text('Level 3 reached'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a capped daily receipt never pretends a five-question set ended',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCelebration(
        tester,
        outcome: _outcome(
          setCompleted: false,
          unitCompleted: false,
          dailyQuestCompleted: true,
          levelBefore: 3,
          levelAfter: 3,
          lines: const [],
          xpEarned: 0,
        ),
        textScale: 2,
        reducedMotion: true,
        primaryLabel: 'Keep charting',
      );

      expect(find.text('Daily observation complete'), findsOneWidget);
      expect(find.text('DAILY OBSERVATION'), findsOneWidget);
      expect(find.text('TODAY  ·  CHARTED'), findsOneWidget);
      expect(find.text('5 / 5  ·  ORBIT CHARTED'), findsNothing);
      expect(find.text('Five-question orbit complete'), findsNothing);
      expect(find.text('XP cap met'), findsOneWidget);
      expect(
        find.text('Milestone recorded. Today’s reward cap was already met.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320dp, 200% text, RTL, and reduced motion stay scroll-safe', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpCelebration(
      tester,
      outcome: _outcome(
        setCompleted: true,
        unitCompleted: true,
        dailyQuestCompleted: true,
        levelBefore: 8,
        levelAfter: 9,
      ),
      textScale: 2,
      direction: TextDirection.rtl,
      reducedMotion: true,
      primaryLabel: 'Continue next five-question session',
      onStay: () {},
    );

    expect(
      find.byKey(const ValueKey('study-session-celebration-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('five-star-orbit-visual')),
      findsOneWidget,
    );
    expect(find.text('5 / 5  ·  ORBIT CHARTED'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('study-celebration-primary')),
    );
    await tester.pump();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('study-celebration-primary')))
          .height,
      greaterThanOrEqualTo(48),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('study-celebration-stay')),
    );
    await tester.pump();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('study-celebration-stay')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet composition preserves the live receipt and actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpCelebration(
      tester,
      outcome: _outcome(
        setCompleted: true,
        unitCompleted: false,
        dailyQuestCompleted: true,
        levelBefore: 2,
        levelAfter: 2,
      ),
      onStay: () {},
    );

    expect(
      find.byKey(const ValueKey('five-star-orbit-visual')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('study-reward-receipt')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('study-milestone-ledger')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('study-celebration-primary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCelebration(
  WidgetTester tester, {
  required StudyReflectionOutcome outcome,
  String primaryLabel = 'Continue next session',
  VoidCallback? onPrimary,
  VoidCallback? onStay,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  bool reducedMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Scaffold(
        body: StudySessionCelebration(
          outcome: outcome,
          primaryLabel: primaryLabel,
          onPrimary: onPrimary ?? () {},
          onStay: onStay,
        ),
      ),
    ),
  );
  await tester.pump();
  if (!reducedMotion) {
    await tester.pump(const Duration(milliseconds: 1400));
  }
}

StudyReflectionOutcome _outcome({
  required bool setCompleted,
  required bool unitCompleted,
  required bool dailyQuestCompleted,
  required int levelBefore,
  required int levelAfter,
  List<RewardLine> lines = const [
    RewardLine(
      eventId: 'question_reflected:q-5',
      ruleVersion: 2,
      reason: 'Question charted',
      amount: 8,
      category: 'practice',
    ),
    RewardLine(
      eventId: 'set_completed:sets:0:5',
      ruleVersion: 2,
      reason: 'Study set complete',
      amount: 15,
      category: 'mastery',
    ),
    RewardLine(
      eventId: 'unit_completed:sets',
      ruleVersion: 2,
      reason: 'Unit complete',
      amount: 20,
      category: 'mastery',
    ),
    RewardLine(
      eventId: 'daily_study_completed:2026-08-05',
      ruleVersion: 2,
      reason: 'Daily observation',
      amount: 30,
      category: 'bonus',
    ),
  ],
  int xpEarned = 73,
  int totalXp = 913,
}) => StudyReflectionOutcome(
  record: StudyRecord(
    questionId: 'q-5',
    topicKey: 'sets',
    shelfKey: 'sets:0:5',
    hypothesisChoiceIndex: null,
    hypothesisMatched: null,
    reflection: StudyReflection.clear,
    firstReflectedAt: DateTime(2026, 8, 5),
    updatedAt: DateTime(2026, 8, 5),
  ),
  lines: lines,
  setCompleted: setCompleted,
  unitCompleted: unitCompleted,
  dailyQuestCompleted: dailyQuestCompleted,
  xpEarned: xpEarned,
  totalXp: totalXp,
  levelBefore: levelBefore,
  levelAfter: levelAfter,
);
