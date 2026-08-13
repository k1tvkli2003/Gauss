import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/widgets/map_gamification_hud.dart';

void main() {
  testWidgets('shows truthful daily loop with humane grace semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpHud(tester, summary: _summary(streakGraceUsed: true));
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget);
    expect(find.text('DAY STREAK'), findsOneWidget);
    expect(find.text('1-DAY GRACE ACTIVE'), findsOneWidget);
    expect(find.text('34 XP'), findsOneWidget);
    expect(find.text('7/10'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('6 day streak.*One day grace.*never erased'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        RegExp(
          'league|leaderboard|heart|share|shop|subscription',
          caseSensitive: false,
        ),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('reflows at 320dp and 200 percent text without truncation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpHud(
      tester,
      summary: _summary(streakGraceUsed: false),
      textScale: 2,
      reducedMotion: true,
    );
    await tester.pump();

    final hud = find.byKey(const ValueKey('map-gamification-hud'));
    expect(tester.getSize(hud).width, 320);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('map-daily-streak'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('map-today-xp'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('map-today-xp'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('map-daily-quest'))).dy,
      ),
    );
    for (final text in tester.widgetList<Text>(
      find.descendant(of: hud, matching: find.byType(Text)),
    )) {
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.maxLines, isNull);
    }
    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('map-quest-progress')),
    );
    expect(animation.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone sheet width keeps every English label whole', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpHud(
      tester,
      summary: _summary(streakGraceUsed: false),
      onPressed: () {},
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('map-daily-streak'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('map-today-xp'))).dy,
      ),
    );
    for (final label in const [
      'DAY STREAK',
      'DAILY RHYTHM',
      'SAVED ON DEVICE',
      'DAILY QUEST',
    ]) {
      expect(
        tester.getSize(find.text(label)).height,
        lessThan(20),
        reason: '$label must remain one physical line at phone-sheet width.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional whole HUD action is at least 48dp and responds', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await _pumpHud(
      tester,
      summary: _summary(streakGraceUsed: false),
      onPressed: () => taps++,
    );
    await tester.pumpAndSettle();

    final hud = find.byKey(const ValueKey('map-gamification-hud'));
    expect(tester.getSize(hud).height, greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel(RegExp('Private daily progress')),
      findsOneWidget,
    );
    await tester.tap(hud);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('zero target and complete quest remain finite and calm', (
    tester,
  ) async {
    const summary = GamificationSummary(
      totalXp: 0,
      todayXp: 0,
      level: 1,
      levelProgress: 0,
      streak: 0,
      quest: DailyQuest(
        title: 'Rest day chart',
        progress: 0,
        target: 0,
        rewardXp: 0,
        completed: true,
      ),
      achievements: [],
    );
    await _pumpHud(tester, summary: summary);
    await tester.pumpAndSettle();

    expect(find.text('COMPLETE'), findsOneWidget);
    expect(find.text('REWARD RECORDED'), findsOneWidget);
    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.value, 1);
    expect(tester.takeException(), isNull);
  });
}

GamificationSummary _summary({required bool streakGraceUsed}) =>
    GamificationSummary(
      totalXp: 734,
      todayXp: 34,
      level: 4,
      levelProgress: .36,
      streak: 6,
      streakGraceUsed: streakGraceUsed,
      quest: const DailyQuest(
        title: 'Chart ten reflections',
        progress: 7,
        target: 10,
        rewardXp: 40,
        completed: false,
      ),
      achievements: const [],
    );

Future<void> _pumpHud(
  WidgetTester tester, {
  required GamificationSummary summary,
  double textScale = 1,
  bool reducedMotion = false,
  VoidCallback? onPressed,
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
        child: MapGamificationHud(summary: summary, onPressed: onPressed),
      ),
    ),
  ),
);
