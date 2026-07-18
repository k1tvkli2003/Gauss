import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/screens/archive_screen.dart';
import 'package:gauss/screens/practice_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/widgets/scratchpad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GaussDatabase database;
  late GaussController controller;
  late QuestionBankRepository questionBank;
  late ProgressRepository progress;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    questionBank = QuestionBankRepository();
    progress = ProgressRepository(database);
    controller = GaussController(questionBank, progress);
    await controller.initialize();
    // Decode the first large shard outside the widget test's fake clock. The
    // production repository uses the same rootBundle cache.
    await questionBank.loadTopic(controller.topics.first.key);
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets('study atlas switches between mathematics and physics sections', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      _TestSurface(controller: controller, child: const PracticeScreen()),
    );
    await tester.pump();

    expect(find.text('STUDY OBSERVATORY'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);

    await tester.tap(find.text('Physics'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -720));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('4 focused sections'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline pen is opt-in and clears its drawing immediately', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: Scaffold(
          backgroundColor: GaussColors.parchment,
          body: Center(
            child: SizedBox(
              width: 330,
              child: InlineQuestionScratch(
                child: Container(
                  key: const ValueKey('question-plate'),
                  height: 190,
                  color: GaussColors.parchment,
                  alignment: Alignment.center,
                  child: const Text(
                    'Question plate',
                    style: TextStyle(color: GaussColors.parchmentInk),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final clearFinder = find.widgetWithIcon(
      IconButton,
      Icons.delete_sweep_outlined,
    );
    expect(tester.widget<IconButton>(clearFinder).onPressed, isNull);

    await tester.tap(find.byTooltip('Draw on this question'));
    await tester.pump(const Duration(milliseconds: 180));
    expect(
      find.text(
        'Pen is active · draw on the question, then tap the pen to scroll again.',
      ),
      findsOneWidget,
    );

    final plate = tester.getRect(find.byKey(const ValueKey('question-plate')));
    await tester.dragFrom(
      plate.topLeft + const Offset(40, 50),
      const Offset(120, 55),
    );
    await tester.pump();
    expect(tester.widget<IconButton>(clearFinder).onPressed, isNotNull);

    await tester.tap(clearFinder);
    await tester.pump();
    expect(tester.widget<IconButton>(clearFinder).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study room persists a revisit reflection without scoring', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    final loadedTopic = await questionBank
        .loadTopic(topic.key)
        .timeout(const Duration(seconds: 10));
    expect(loadedTopic, isNotEmpty);
    await progress
        .studyRecords(topicKey: topic.key)
        .timeout(const Duration(seconds: 10));
    await progress
        .studyPosition('${topic.key}:0:20')
        .timeout(const Duration(seconds: 10));
    final preloaded = await controller.loadStudyShelf(topic.key, count: 20);
    expect(preloaded.questions, isNotEmpty);
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 20),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    expect(find.text('STUDY ROOM'), findsOneWidget);
    expect(find.byTooltip('Draw on this question'), findsOneWidget);
    expect(find.text('Reveal the source answer'), findsOneWidget);

    await tester.ensureVisible(find.text('Reveal the source answer'));
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.text('Reveal the source answer'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('How does the concept feel now?'), findsOneWidget);

    await tester.ensureVisible(find.text('Revisit later'));
    await tester.tap(find.text('Revisit later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(controller.study.revisitCount, 1);
    expect(controller.gamification.totalXp, 0);
    expect(find.text('Saved to your revisit orbit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestSurface extends StatelessWidget {
  const _TestSurface({required this.controller, required this.child});

  final GaussController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildGaussTheme(),
    home: GaussScope(
      controller: controller,
      child: Scaffold(body: child),
    ),
  );
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(411, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}
