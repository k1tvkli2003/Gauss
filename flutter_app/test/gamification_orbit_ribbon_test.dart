import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/gamification_catalog.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/widgets/gamification_orbit_ribbon.dart';

void main() {
  testWidgets('renders truthful private progress and earned milestone state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpRibbon(tester, summary: _summary());
    await tester.pumpAndSettle();

    expect(find.text('PRIVATE ORBIT'), findsOneWidget);
    expect(find.text('ON DEVICE  •  36 XP TODAY'), findsOneWidget);
    expect(find.text('4 DAYS'), findsOneWidget);
    expect(find.text('DAILY STREAK'), findsOneWidget);
    expect(find.text('LEVEL 3'), findsOneWidget);
    expect(find.textContaining('EARNED SEAL'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Private offline progress')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Earned experience never disappears')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        RegExp('league|leaderboard|hearts|shop', caseSensitive: false),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('reflows at 320dp and 200 percent text without clipping', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpRibbon(
      tester,
      summary: _summary(),
      textScale: 2,
      reducedMotion: true,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final ribbon = find.byKey(const ValueKey('gamification-orbit-ribbon'));
    expect(tester.getSize(ribbon).width, 320);
    for (final text in tester.widgetList<Text>(
      find.descendant(of: ribbon, matching: find.byType(Text)),
    )) {
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
    for (final animation in tester.widgetList<TweenAnimationBuilder<double>>(
      find.descendant(
        of: ribbon,
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    )) {
      expect(animation.duration, Duration.zero);
    }
  });

  testWidgets('optional quest and milestone targets stay tappable at 48dp', (
    tester,
  ) async {
    var questTaps = 0;
    var milestoneTaps = 0;
    await _pumpRibbon(
      tester,
      summary: _summary(),
      onQuestPressed: () => questTaps++,
      onMilestonePressed: () => milestoneTaps++,
    );
    await tester.pumpAndSettle();

    final quest = find.byKey(const ValueKey('gamification-quest-segment'));
    final milestone = find.byKey(
      const ValueKey('gamification-milestone-segment'),
    );
    expect(tester.getSize(quest).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(milestone).height, greaterThanOrEqualTo(48));

    await tester.tap(quest);
    await tester.tap(milestone);
    expect(questTaps, 1);
    expect(milestoneTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and zero progress remain calm and well defined', (
    tester,
  ) async {
    const summary = GamificationSummary(
      totalXp: 0,
      todayXp: 0,
      level: 1,
      levelProgress: 0,
      streak: 0,
      quest: DailyQuest(
        title: 'Chart ten reflections',
        progress: 0,
        target: 10,
        rewardXp: 40,
        completed: false,
      ),
      achievements: [],
    );
    await _pumpRibbon(tester, summary: summary);
    await tester.pumpAndSettle();

    expect(find.text('Begin whenever you are ready'), findsOneWidget);
    expect(find.text('Your first seal is ahead'), findsOneWidget);
    expect(find.textContaining('no rush'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one missed day is presented as a humane grace state', (
    tester,
  ) async {
    const summary = GamificationSummary(
      totalXp: 190,
      todayXp: 0,
      level: 2,
      levelProgress: .2,
      streak: 3,
      streakGraceUsed: true,
      quest: DailyQuest(
        title: 'Chart ten reflections',
        progress: 0,
        target: 10,
        rewardXp: 40,
        completed: false,
      ),
      achievements: [],
    );
    final semantics = tester.ensureSemantics();
    await _pumpRibbon(tester, summary: summary);
    await tester.pumpAndSettle();

    expect(
      find.text('Grace day active · earned XP stays safe'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('calm grace day is bridging the orbit')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

GamificationSummary _summary() => GamificationSummary(
  totalXp: 610,
  todayXp: 36,
  level: 3,
  levelProgress: .42,
  streak: 4,
  quest: const DailyQuest(
    title: 'Chart ten reflections',
    progress: 7,
    target: 10,
    rewardXp: 40,
    completed: false,
  ),
  achievements: GaussGamificationCatalog.evaluate({
    AchievementMetric.correctAnswers: 120,
    AchievementMetric.correctedMistakes: 12,
    AchievementMetric.masteredTopics: 2,
    AchievementMetric.goldChallenges: 0,
    AchievementMetric.studyRhythm: 4,
    AchievementMetric.completedMissions: 8,
    AchievementMetric.practicedSubjects: 2,
  }),
);

Future<void> _pumpRibbon(
  WidgetTester tester, {
  required GamificationSummary summary,
  double textScale = 1,
  bool reducedMotion = false,
  VoidCallback? onQuestPressed,
  VoidCallback? onMilestonePressed,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildGaussTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQueryData(
        size: tester.view.physicalSize / tester.view.devicePixelRatio,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reducedMotion,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: GamificationOrbitRibbon(
          summary: summary,
          onQuestPressed: onQuestPressed,
          onMilestonePressed: onMilestonePressed,
        ),
      ),
    ),
  ),
);
