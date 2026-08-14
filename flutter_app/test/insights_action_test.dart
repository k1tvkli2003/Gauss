import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/screens/insights_screen.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('incomplete daily observation explains and opens its next step', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    try {
      late final _QuestFixture fixture;
      await tester.runAsync(() async {
        fixture = await _QuestFixture.create(
          quest: const DailyQuest(
            title: 'Chart ten reflections',
            progress: 3,
            target: 10,
            rewardXp: 40,
            completed: false,
          ),
          todayXp: 12,
        );
      });
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pump();
      await _scrollUntil(
        tester,
        find.byKey(const ValueKey('gamification-quest-segment')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('gamification-quest-segment')),
      );
      await tester.pump();

      expect(find.text('TODAY · QUEST'), findsOneWidget);
      expect(find.text('7 reflections remain · no rush'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Today quest. Chart ten reflections. 3 of 10. 12 experience today. 7 reflections remain · no rush.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('gamification-quest-segment')))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('gamification-quest-segment')),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUDY DESTINATION'), findsOneWidget);
      expect(fixture.router.routeInformationProvider.value.uri.path, '/study');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('completed daily observation becomes a truthful resting state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    try {
      late final _QuestFixture fixture;
      await tester.runAsync(() async {
        fixture = await _QuestFixture.create(
          quest: const DailyQuest(
            title: 'Chart ten reflections',
            progress: 10,
            target: 10,
            rewardXp: 40,
            completed: true,
          ),
          todayXp: 80,
        );
      });
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app(textScale: 2));
      await tester.pump();
      await _scrollUntil(
        tester,
        find.byKey(const ValueKey('gamification-quest-segment')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('gamification-quest-segment')),
      );
      await tester.pump();

      expect(find.text('TODAY · CHARTED'), findsOneWidget);
      expect(find.text('Complete · reward safely recorded'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Today quest. Chart ten reflections. 10 of 10. 80 experience today. Complete · reward safely recorded.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('gamification-quest-segment')))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'observatory keeps a true header axis and readable seals at 320dp 200%',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      late final _QuestFixture fixture;
      await tester.runAsync(() async {
        fixture = await _QuestFixture.create(
          quest: const DailyQuest(
            title: 'Chart ten reflections',
            progress: 0,
            target: 10,
            rewardXp: 40,
            completed: false,
          ),
          todayXp: 0,
        );
      });
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app(textScale: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final axis = tester.getRect(
        find.byKey(const ValueKey('insights-balanced-header-axis')),
      );
      final wordmark = tester.getRect(
        find.byKey(const ValueKey('insights-centered-wordmark')),
      );
      final levelTrack = tester.getRect(
        find.byKey(const ValueKey('insights-level-track')),
      );
      final statusTrack = tester.getRect(
        find.byKey(const ValueKey('insights-status-track')),
      );
      expect(wordmark.center.dx, closeTo(axis.center.dx, .01));
      expect(
        axis.center.dx - levelTrack.center.dx,
        closeTo(statusTrack.center.dx - axis.center.dx, .01),
      );
      expect(levelTrack.size, const Size.square(48));
      expect(statusTrack.size, const Size.square(48));
      expect(
        find.byKey(const ValueKey('insights-tools-action')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('insights-header')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text && widget.overflow == TextOverflow.ellipsis,
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      final proof = find.byKey(
        const ValueKey('achievement-plate-proof_ledger'),
      );
      await _scrollUntil(tester, proof, maxDrags: 36);
      expect(proof, findsOneWidget);
      await tester.ensureVisible(proof);
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.byKey(const ValueKey('achievement-layout-stacked-proof_ledger')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: proof,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text && widget.overflow == TextOverflow.ellipsis,
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _QuestFixture {
  _QuestFixture({
    required this.database,
    required this.controller,
    required this.router,
  });

  final GaussDatabase database;
  final _QuestController controller;
  final GoRouter router;

  static Future<_QuestFixture> create({
    required DailyQuest quest,
    required int todayXp,
  }) async {
    final database = GaussDatabase(NativeDatabase.memory());
    final controller = _QuestController(
      QuestionBankRepository(),
      ProgressRepository(database),
      quest: quest,
      todayXp: todayXp,
    );
    await controller.initialize();
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/insights',
      routes: [
        GoRoute(
          path: '/insights',
          builder: (context, state) => const Scaffold(body: InsightsScreen()),
        ),
        GoRoute(
          path: '/study',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('STUDY DESTINATION'))),
        ),
      ],
    );
    return _QuestFixture(
      database: database,
      controller: controller,
      router: router,
    );
  }

  Widget app({double textScale = 1}) => MaterialApp.router(
    theme: buildGaussTheme(),
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: GaussScope(controller: controller, child: child!),
    ),
  );

  Future<void> dispose() async {
    router.dispose();
    controller.dispose();
    await database.close();
  }
}

class _QuestController extends GaussController {
  _QuestController(
    super.questionBank,
    super.progress, {
    required this.quest,
    required this.todayXp,
  });

  final DailyQuest quest;
  final int todayXp;

  @override
  GamificationSummary get gamification {
    final current = super.gamification;
    return GamificationSummary(
      totalXp: current.totalXp,
      todayXp: todayXp,
      level: current.level,
      levelProgress: current.levelProgress,
      streak: current.streak,
      quest: quest,
      achievements: current.achievements,
    );
  }
}

Future<void> _scrollUntil(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 20,
}) async {
  for (var drag = 0; drag < maxDrags; drag++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pump(const Duration(milliseconds: 60));
  }
}
