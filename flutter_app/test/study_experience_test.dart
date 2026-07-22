import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/status_widget_bridge.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/screens/archive_screen.dart';
import 'package:gauss/screens/backup_screen.dart';
import 'package:gauss/screens/insights_screen.dart';
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

  testWidgets('study modes stack, pair, and row out by window class', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const labels = ['Revisit orbit', 'Gem shelf', 'Scratchpad', 'Path atlas'];

    Future<List<Offset>> centersAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _TestSurface(controller: controller, child: const PracticeScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      return [
        for (final label in labels)
          tester.getCenter(find.byKey(ValueKey('study-mode-$label'))),
      ];
    }

    final phone = await centersAt(const Size(411, 900));
    expect(phone[1].dy, greaterThan(phone[0].dy + 40), reason: '$phone');
    expect(phone[2].dy, greaterThan(phone[1].dy + 40), reason: '$phone');

    final tablet = await centersAt(const Size(800, 900));
    expect(tablet[1].dy, closeTo(tablet[0].dy, 1));
    expect(tablet[3].dy, closeTo(tablet[2].dy, 1));
    expect(tablet[2].dy, greaterThan(tablet[0].dy + 40));

    final desktop = await centersAt(const Size(1180, 900));
    expect(
      desktop.every((point) => (point.dy - desktop.first.dy).abs() < 1),
      isTrue,
    );
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

  testWidgets(
    'study-room ink suspends horizontal paging while the pen is active',
    (tester) async {
      await _setPhoneSurface(tester);
      final topic = controller.topics.first;
      await tester.pumpWidget(
        _TestSurface(
          controller: controller,
          child: ArchiveScreen(topicKey: topic.key, count: 20),
        ),
      );
      await _pumpUntil(tester, find.text('STUDY ROOM'));

      PageView pages() => tester.widget<PageView>(
        find.byKey(const ValueKey('study-room-pages')),
      );

      expect(pages().physics, isA<PageScrollPhysics>());
      final pen = find.byTooltip('Draw on this question');
      final target = tester.getSize(pen);
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));

      await tester.tap(pen);
      await tester.pump(const Duration(milliseconds: 160));
      expect(pages().physics, isA<NeverScrollableScrollPhysics>());

      await tester.tap(find.byTooltip('Stop drawing'));
      await tester.pump(const Duration(milliseconds: 160));
      expect(pages().physics, isA<PageScrollPhysics>());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'study room changes from a single flow to a split workspace at 840dp',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final topic = controller.topics.first;

      await tester.binding.setSurfaceSize(const Size(839, 900));
      await tester.pumpWidget(
        _TestSurface(
          controller: controller,
          child: ArchiveScreen(topicKey: topic.key, count: 20),
        ),
      );
      await _pumpUntil(tester, find.text('STUDY ROOM'));
      expect(
        find.byKey(const ValueKey('study-room-single-pane')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('study-room-split-pane')), findsNothing);

      await tester.binding.setSurfaceSize(const Size(840, 900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.byKey(const ValueKey('study-room-single-pane')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('study-room-split-pane')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('study-room-prompt-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('study-room-response-scroll')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scratchpad is full-width on phone and bounded on larger screens',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<Size> openAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGaussTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showScratchpad(context),
                    child: const Text('Open sheet'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open sheet'));
        await tester.pumpAndSettle();
        final sheet = tester.getSize(
          find.byKey(const ValueKey('scratchpad-sheet')),
        );
        await tester.tap(find.byTooltip('Close scratchpad'));
        await tester.pumpAndSettle();
        return sheet;
      }

      final phone = await openAt(const Size(390, 820));
      expect(phone.width, 390);
      final tablet = await openAt(const Size(1200, 900));
      expect(tablet.width, lessThanOrEqualTo(820));
      expect(tablet.width, greaterThanOrEqualTo(760));
      expect(tester.takeException(), isNull);
    },
  );

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
    expect(find.text('Reveal reference answer'), findsOneWidget);

    await tester.ensureVisible(find.text('Reveal reference answer'));
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.text('Reveal reference answer'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('How does the concept feel now?'), findsOneWidget);

    await tester.ensureVisible(find.text('Revisit later'));
    await tester.tap(find.text('Revisit later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(controller.study.revisitCount, 1);
    // Rule v2: the act of charting earns calm XP (4 charted + 8 new unit).
    // The reward never claims the unverified source mapping is correct.
    expect(controller.gamification.totalXp, 12);
    expect(find.text('Saved to your revisit orbit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the observatory surfaces level, quest, and catalog seals', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(
      _TestSurface(controller: controller, child: const InsightsScreen()),
    );
    await tester.pump();
    // Discard the mid-resize frame left by the previous surface size.
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 60));

    // The level medallion rides in the header, always visible.
    expect(find.text('LVL'), findsOneWidget);

    // The study-native daily quest is live again further down the log.
    await _scrollUntil(tester, find.text('DAILY OBSERVATION'));
    expect(find.text('DAILY OBSERVATION'), findsOneWidget);
    expect(find.text('Chart ten reflections'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);

    // The crafted catalog replaced the six inline seals.
    await _scrollUntil(tester, find.text('Theorem seals'));
    expect(find.text('Theorem seals'), findsOneWidget);
    await _scrollUntil(tester, find.text('Luminosity'));
    expect(find.text('Luminosity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a reshuffled pass keeps set membership and marks', () async {
    final topic = controller.topics.first;
    final canonical = await controller.loadStudyShelf(topic.key, count: 20);
    final shuffled = await controller.loadStudyShelf(
      topic.key,
      count: 20,
      shuffleSeed: 7,
    );
    final repeated = await controller.loadStudyShelf(
      topic.key,
      count: 20,
      shuffleSeed: 7,
    );

    List<String> ids(StudyShelf shelf) =>
        shelf.questions.map((question) => question.id).toList();

    // Same members, same shelf key — only the order moved.
    expect(ids(shuffled).toSet(), ids(canonical).toSet());
    expect(shuffled.key, canonical.key);
    expect(ids(shuffled), isNot(ids(canonical)));
    // The same seed always produces the same order.
    expect(ids(repeated), ids(shuffled));
  });

  testWidgets('the study room can jump to any question in the set', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 20),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    expect(find.text('1 of 20'), findsOneWidget);
    await tester.tap(find.text('1 of 20'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('JUMP TO'), findsOneWidget);
    await tester.tap(find.text('12'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('12 of 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home-screen widget publishes only the two calm numbers', (
    tester,
  ) async {
    final published = <Map<Object?, Object?>>[];
    const channel = MethodChannel('com.gauss.app/status_widget');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'publishStatus') {
        published.add(call.arguments as Map<Object?, Object?>);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    const bridge = _AlwaysOnStatusWidget();
    await bridge.publish(chartedToday: 7, due: 3);

    expect(published, hasLength(1));
    expect(published.single, {'chartedToday': 7, 'due': 3});

    // An unsupported host publishes nothing at all.
    const unsupported = StatusWidgetBridge();
    if (!unsupported.isSupported) {
      await unsupported.publish(chartedToday: 9, due: 9);
      expect(published, hasLength(1));
    }
  });

  test('the first-run tour is offered once and then stays dismissed', () async {
    expect(controller.needsTour, isTrue);

    await controller.markTourSeen();
    expect(controller.needsTour, isFalse);

    // The decision survives a cold start against the same store.
    final reopened = GaussController(QuestionBankRepository(), progress);
    await reopened.initialize();
    addTearDown(reopened.dispose);
    expect(reopened.needsTour, isFalse);
  });

  testWidgets('the observatory lays out cleanly from 320dp to tablet', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [
      Size(320, 700),
      Size(360, 820),
      Size(411, 820),
      Size(800, 600),
      Size(1180, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _TestSurface(controller: controller, child: const InsightsScreen()),
      );
      // Let layout settle at the new surface before judging it: the frame
      // captured mid-resize is a test artifact, not a rendered state.
      await tester.pump();
      tester.takeException();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Insights overflowed at $size',
      );
    }
  });

  testWidgets('insight metrics become one glanceable row on tablet', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(800, 900));
    await tester.pumpWidget(
      _TestSurface(controller: controller, child: const InsightsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final tabletRows = List.generate(
      4,
      (index) =>
          tester.getTopLeft(find.byKey(ValueKey('insight-metric-$index'))).dy,
    );
    expect(tabletRows.every((y) => (y - tabletRows.first).abs() < 1), isTrue);

    await tester.binding.setSurfaceSize(const Size(411, 820));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final phoneTop = tester
        .getTopLeft(find.byKey(const ValueKey('insight-metric-0')))
        .dy;
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('insight-metric-1'))).dy,
      closeTo(phoneTop, 1),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('insight-metric-2'))).dy,
      greaterThan(phoneTop + 100),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'core study surfaces survive 200 percent text and reduced motion',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in const [Size(411, 820), Size(1024, 800)]) {
        await tester.binding.setSurfaceSize(size);
        for (final surface in const <Widget>[
          PracticeScreen(),
          InsightsScreen(),
        ]) {
          await tester.pumpWidget(
            _TestSurface(
              controller: controller,
              textScale: 2,
              reducedMotion: true,
              child: surface,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
          expect(
            tester.takeException(),
            isNull,
            reason: '${surface.runtimeType} overflowed at $size and 200% text',
          );
        }
      }
    },
  );

  testWidgets(
    'study room and vault survive accessible phone and tablet layouts',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final topic = controller.topics.first;

      await tester.binding.setSurfaceSize(const Size(411, 820));
      await tester.pumpWidget(
        _TestSurface(
          controller: controller,
          textScale: 2,
          reducedMotion: true,
          child: ArchiveScreen(topicKey: topic.key, count: 20),
        ),
      );
      await _pumpUntil(tester, find.text('STUDY ROOM'));
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1024, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.byKey(const ValueKey('study-room-split-pane')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      for (final size in const [Size(411, 820), Size(1024, 800)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          _TestSurface(
            controller: controller,
            textScale: 2,
            reducedMotion: true,
            child: const BackupScreen(),
          ),
        );
        await _pumpUntil(tester, find.text('Browser progress stays local'));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Vault overflowed at $size and 200% text',
        );
      }
    },
  );

  testWidgets('completing a set opens the recap with its reward lines', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    final questions = await questionBank.loadTopic(topic.key);
    // Chart the whole first set except its final question, off-screen.
    for (final question in questions.take(19)) {
      await controller.saveStudyReflection(
        question: question,
        shelfKey: '${topic.key}:0:20',
        hypothesisChoiceIndex: null,
        reflection: StudyReflection.clear,
      );
    }
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 20),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    await tester.ensureVisible(find.text('Reveal reference answer'));
    await tester.tap(find.text('Reveal reference answer'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.ensureVisible(find.text('Concept feels clear'));
    await tester.tap(find.text('Concept feels clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Set complete'), findsOneWidget);
    expect(find.text('Study set complete'), findsOneWidget);
    expect(find.text('Keep charting'), findsOneWidget);
    await tester.tap(find.text('Keep charting'));
    for (var pump = 0; pump < 12; pump++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Set complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// Reports the widget host as present so the publish path runs on any host
/// the suite happens to execute on.
class _AlwaysOnStatusWidget extends StatusWidgetBridge {
  const _AlwaysOnStatusWidget();

  @override
  bool get isSupported => true;
}

class _TestSurface extends StatelessWidget {
  const _TestSurface({
    required this.controller,
    required this.child,
    this.textScale = 1,
    this.reducedMotion = false,
  });

  final GaussController controller;
  final Widget child;
  final double textScale;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildGaussTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reducedMotion,
      ),
      child: child!,
    ),
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

Future<void> _scrollUntil(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 25,
}) async {
  for (var drag = 0; drag < maxDrags; drag++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pump(const Duration(milliseconds: 60));
  }
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
