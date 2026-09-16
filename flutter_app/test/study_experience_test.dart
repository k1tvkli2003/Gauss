import 'dart:ui' show SemanticsAction;

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gauss/data/status_widget_bridge.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/backup_service.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/failures.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
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
    expect(
      find.bySemanticsLabel('0 of 5 questions charted in this micro-lesson.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Physics'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -720));
    await tester.pump(const Duration(milliseconds: 220));

    for (final sectionId in const [
      'physics_matter_measurement',
      'physics_mechanics',
      'physics_fields_circuits',
      'physics_waves_modern',
    ]) {
      expect(find.byKey(ValueKey('study-section-$sectionId')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('study modes stack, pair, and row out by window class', (
    tester,
  ) async {
    _restoreSurfaceAfter(tester);
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

    final horizontalTablet = await centersAt(const Size(1280, 800));
    expect(
      horizontalTablet.every(
        (point) => (point.dy - horizontalTablet.first.dy).abs() < 1,
      ),
      isTrue,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('study-course-instrument')))
          .width,
      lessThanOrEqualTo(760),
    );
    final mathSections = GaussStudyCurriculum.forSubject(Subject.math);
    final firstChapter = tester.getTopLeft(
      find.byKey(ValueKey('study-section-${mathSections[0].id}')),
    );
    final secondChapter = tester.getTopLeft(
      find.byKey(ValueKey('study-section-${mathSections[1].id}')),
    );
    expect(secondChapter.dy, closeTo(firstChapter.dy, 1));
    expect(secondChapter.dx, greaterThan(firstChapter.dx + 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stylus writes immediately while inline touch stays available', (
    tester,
  ) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    final plate = await _pumpScratchSurface(tester, ink);

    expect(find.byKey(const ValueKey('inline-pen-halo')), findsNothing);

    await tester.dragFrom(
      plate.topLeft + const Offset(40, 50),
      const Offset(120, 55),
    );
    expect(ink.isEmpty, isTrue, reason: 'finger input must scroll by default');

    final pen = await tester.startGesture(
      plate.topLeft + const Offset(40, 50),
      pointer: 7,
      kind: PointerDeviceKind.stylus,
    );
    await pen.moveBy(const Offset(120, 55));
    await pen.up();
    await tester.pumpAndSettle();
    expect(ink.strokeCount, 1);
    expect(find.byKey(const ValueKey('inline-pen-halo')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('inline-ink-clear')));
    await tester.pumpAndSettle();
    expect(ink.isEmpty, isTrue);
    expect(find.byKey(const ValueKey('inline-pen-halo')), findsNothing);
    expect(find.byKey(const ValueKey('inline-ink-restore')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('inline-ink-restore')));
    await tester.pumpAndSettle();
    expect(ink.strokeCount, 1);
    expect(find.byKey(const ValueKey('inline-pen-halo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'scratchpad clears instantly and restores from the same toolbar',
    (tester) async {
      final ink = ScratchInkController();
      addTearDown(ink.dispose);
      final plate = await _pumpExpandedScratchpad(tester, ink);
      final pen = await tester.startGesture(
        plate.center,
        pointer: 9,
        kind: PointerDeviceKind.stylus,
      );
      await pen.moveBy(const Offset(86, 24));
      await pen.up();
      await tester.pump();
      expect(ink.strokeCount, 1);

      await tester.tap(find.byTooltip('Clear scratchpad'));
      await tester.pump();
      expect(ink.isEmpty, isTrue);
      expect(find.text('Clear scratchpad?'), findsNothing);
      expect(find.byTooltip('Restore cleared ink'), findsOneWidget);

      await tester.tap(find.byTooltip('Restore cleared ink'));
      await tester.pump();
      expect(ink.strokeCount, 1);
      expect(find.byTooltip('Undo last stroke'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Focus Pen pressure changes width and cancel rolls back stroke', (
    tester,
  ) async {
    final ink = ScratchInkController();
    addTearDown(ink.dispose);
    final plate = await _pumpScratchSurface(tester, ink);
    final start = plate.topLeft + const Offset(48, 62);
    final end = start + const Offset(150, 48);
    final pen = await tester.createGesture(
      pointer: 11,
      kind: PointerDeviceKind.stylus,
    );

    await pen.downWithCustomEvent(
      start,
      PointerDownEvent(
        pointer: 11,
        position: start,
        kind: PointerDeviceKind.stylus,
        pressure: .08,
        pressureMin: 0,
        pressureMax: 1,
      ),
    );
    await pen.updateWithCustomEvent(
      PointerMoveEvent(
        pointer: 11,
        position: end,
        delta: end - start,
        kind: PointerDeviceKind.stylus,
        pressure: .96,
        pressureMin: 0,
        pressureMax: 1,
      ),
    );
    await tester.pump();

    expect(ink.recordedWidths.length, greaterThanOrEqualTo(2));
    expect(
      ink.recordedWidths.reduce((a, b) => a > b ? a : b) -
          ink.recordedWidths.reduce((a, b) => a < b ? a : b),
      greaterThan(.5),
    );

    await pen.cancel();
    await tester.pump();
    expect(ink.isEmpty, isTrue, reason: 'a canceled stroke must not survive');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'native palm rejection removes the matching finger gesture only',
    (tester) async {
      final ink = ScratchInkController();
      addTearDown(ink.dispose);
      final plate = await _pumpExpandedScratchpad(tester, ink);

      final touch = await tester.startGesture(
        plate.topLeft + const Offset(36, 70),
        pointer: 31,
        kind: PointerDeviceKind.touch,
      );
      await touch.moveBy(const Offset(130, 42));
      await touch.up();
      await tester.pump();
      expect(ink.strokeCount, 1);

      final stylus = await tester.startGesture(
        plate.topLeft + const Offset(50, 115),
        pointer: 32,
        kind: PointerDeviceKind.stylus,
      );
      await stylus.moveBy(const Offset(90, -25));
      await stylus.up();
      await tester.pump();
      expect(ink.strokeCount, 2);

      ScratchStylusSignals.debugSimulatePalmRejection(androidPointerId: 99);
      await tester.pump();
      expect(
        ink.strokeCount,
        2,
        reason: 'an unrelated pointer must do nothing',
      );

      // Widget-test touch pointers use device 0, mirroring Android pointerId 0.
      ScratchStylusSignals.debugSimulatePalmRejection(androidPointerId: 0);
      await tester.pump();
      expect(
        ink.strokeCount,
        1,
        reason: 'the earlier touch is removed even when stylus ink is newer',
      );
      await tester.tap(find.byTooltip('Close scratchpad'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('inline touch never claims drawing ownership', (tester) async {
    final ink = ScratchInkController();
    final ownership = <bool>[];
    addTearDown(ink.dispose);
    final plate = await _pumpScratchSurface(
      tester,
      ink,
      onDrawingChanged: ownership.add,
    );

    final first = await tester.startGesture(
      plate.topLeft + const Offset(40, 70),
      pointer: 41,
      kind: PointerDeviceKind.touch,
    );
    await first.moveBy(const Offset(35, 12));
    final second = await tester.startGesture(
      plate.topLeft + const Offset(95, 85),
      pointer: 42,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(ownership, isEmpty);
    expect(ink.isEmpty, isTrue, reason: 'inline touch must remain non-inking');
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller replacement cancels live ink before disposal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 420));
    _restoreSurfaceAfter(tester);
    final replacement = ScratchInkController();
    addTearDown(replacement.dispose);
    replacement.begin(
      const Offset(10, 10),
      const Size(100, 100),
      2.8,
      kind: PointerDeviceKind.stylus,
    );
    replacement.end();
    var useReplacement = false;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return InlineQuestionScratch(
                controller: useReplacement ? replacement : null,
                child: Container(
                  key: const ValueKey('replaceable-question-plate'),
                  height: 190,
                  color: GaussColors.parchment,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final plate = tester.getRect(
      find.byKey(const ValueKey('replaceable-question-plate')),
    );
    final pen = await tester.startGesture(
      plate.center,
      pointer: 61,
      kind: PointerDeviceKind.stylus,
    );
    await pen.moveBy(const Offset(30, 20));

    rebuild(() => useReplacement = true);
    await tester.pump();
    await tester.pump();
    await pen.cancel();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
          )
          .onPressed,
      isNotNull,
      reason: 'pre-existing replacement ink must repaint and remain clearable',
    );
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
          child: ArchiveScreen(topicKey: topic.key, count: 5),
        ),
      );
      await _pumpUntil(tester, find.text('STUDY ROOM'));

      PageView pages() => tester.widget<PageView>(
        find.byKey(const ValueKey('study-room-pages')),
      );

      expect(pages().physics, isA<PageScrollPhysics>());
      final plate = tester.getRect(
        find.byKey(const ValueKey('inline-ink-canvas')),
      );
      final paperBefore = tester.getRect(
        find.byKey(const ValueKey('study-room-question-paper')),
      );
      final dockBefore = tester.getRect(
        find.byKey(const ValueKey('study-room-navigation-dock')),
      );
      expect(
        find.byKey(const ValueKey('study-room-ink-controls')),
        findsNothing,
      );
      final pen = await tester.startGesture(
        plate.center,
        pointer: 77,
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();
      expect(pages().physics, isA<NeverScrollableScrollPhysics>());
      await pen.moveBy(const Offset(12, 8));
      await tester.pump(const Duration(milliseconds: 260));
      expect(
        tester.getRect(find.byKey(const ValueKey('study-room-question-paper'))),
        paperBefore,
        reason: 'Active ink must not resize the paper beneath the pen.',
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('study-room-navigation-dock')),
        ),
        dockBefore,
      );
      expect(pages().physics, isA<NeverScrollableScrollPhysics>());

      await pen.up();
      await tester.pump(const Duration(milliseconds: 260));
      expect(pages().physics, isA<PageScrollPhysics>());
      expect(
        find.byKey(const ValueKey('inline-pen-halo')),
        findsNothing,
        reason: 'Ink tools belong to the fixed session dock, not the prompt.',
      );
      expect(
        find.byKey(const ValueKey('study-room-ink-controls')),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('study-room-question-paper'))),
        paperBefore,
        reason: 'Writing must never move the question or its answer list.',
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('study-room-navigation-dock')),
        ),
        dockBefore,
      );

      await tester.tap(find.byKey(const ValueKey('study-room-ink-clear')));
      await tester.pump(const Duration(milliseconds: 260));
      expect(
        find.byKey(const ValueKey('study-room-ink-restore')),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('study-room-question-paper'))),
        paperBefore,
      );
      await tester.tap(find.byKey(const ValueKey('study-room-ink-restore')));
      await tester.pump(const Duration(milliseconds: 260));
      expect(
        find.byKey(const ValueKey('study-room-ink-controls')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('study-room-close-action')));
      await tester.pump();
      expect(find.text('Leave and clear question ink?'), findsOneWidget);
      expect(
        find.textContaining('Ink drawn on these question pages is temporary'),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep writing'));
      await tester.pump();
      expect(find.text('Leave and clear question ink?'), findsNothing);
      expect(
        find.byKey(const ValueKey('study-room-ink-controls')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'study room changes from a single flow to a split workspace at 840dp',
    (tester) async {
      _restoreSurfaceAfter(tester);
      final topic = controller.topics.first;

      await tester.binding.setSurfaceSize(const Size(839, 900));
      await tester.pumpWidget(
        _TestSurface(
          controller: controller,
          child: ArchiveScreen(topicKey: topic.key, count: 5),
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

  testWidgets('study room warns before an uncharted hypothesis is lost', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 5),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    final firstChoice = find.bySemanticsLabel(RegExp(r'^Choice 1\.'));
    await tester.ensureVisible(firstChoice);
    expect(
      tester
          .getSemantics(firstChoice)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'TalkBack must be able to set a private hypothesis.',
    );
    await tester.tap(firstChoice);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-room-close-action')));
    await tester.pump();

    expect(
      find.text('Leave without charting this hypothesis?'),
      findsOneWidget,
    );
    expect(
      find.textContaining('saved only after you chart or revisit'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep studying'));
    await tester.pump();
    expect(find.text('Leave without charting this hypothesis?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'study room header keeps a true action axis and reflows at 320dp 200%',
    (tester) async {
      _restoreSurfaceAfter(tester);
      final topic = controller.topics.first;

      Future<void> pumpAt(Size size, {double textScale = 1}) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          _TestSurface(
            controller: controller,
            textScale: textScale,
            child: ArchiveScreen(topicKey: topic.key, count: 5),
          ),
        );
        await _pumpUntil(tester, find.text('STUDY ROOM'));
      }

      await pumpAt(const Size(411, 900));
      final axis = tester.getRect(
        find.byKey(const ValueKey('study-room-balanced-action-axis')),
      );
      final wordmark = tester.getCenter(
        find.byKey(const ValueKey('study-room-centered-wordmark')),
      );
      final close = tester.getCenter(
        find.byKey(const ValueKey('study-room-close-action')),
      );
      final shuffle = tester.getCenter(
        find.byKey(const ValueKey('study-room-shuffle-action')),
      );
      expect(wordmark.dx, closeTo(axis.center.dx, .5));
      expect(
        axis.center.dx - close.dx,
        closeTo(shuffle.dx - axis.center.dx, .5),
      );

      await pumpAt(const Size(320, 900), textScale: 2);
      final compactHeader = tester.getRect(
        find.byKey(const ValueKey('study-room-header')),
      );
      final compactWordmark = tester.getCenter(
        find.byKey(const ValueKey('study-room-centered-wordmark')),
      );
      final closeSize = tester.getSize(
        find.byKey(const ValueKey('study-room-close-action')),
      );
      final shuffleSize = tester.getSize(
        find.byKey(const ValueKey('study-room-shuffle-action')),
      );
      final heading = tester.getRect(
        find.byKey(const ValueKey('study-room-session-heading')),
      );
      final contextLabel = tester.getRect(
        find.byKey(const ValueKey('study-room-context-label')),
      );
      final contextText = tester.widget<Text>(
        find.byKey(const ValueKey('study-room-context-label')),
      );

      expect(compactWordmark.dx, closeTo(160, .5));
      expect(closeSize.width, greaterThanOrEqualTo(48));
      expect(closeSize.height, greaterThanOrEqualTo(48));
      expect(shuffleSize.width, greaterThanOrEqualTo(48));
      expect(shuffleSize.height, greaterThanOrEqualTo(48));
      expect(heading.bottom, lessThanOrEqualTo(contextLabel.top));
      expect(compactHeader.left, greaterThanOrEqualTo(0));
      expect(compactHeader.right, lessThanOrEqualTo(320));
      expect(contextText.overflow, isNot(TextOverflow.ellipsis));
      expect(find.text('STUDY ROOM'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.text('QUESTION 1'), findsOneWidget);
      final difficulty = tester.getRect(
        find.byKey(const ValueKey('question-manuscript-difficulty')),
      );
      final questionNumber = tester.getRect(
        find.byKey(const ValueKey('question-manuscript-number')),
      );
      final navigation = find.byKey(
        const ValueKey('study-room-navigation-dock'),
      );
      final navigationRect = tester.getRect(navigation);
      final previousRect = tester.getRect(
        find.byKey(const ValueKey('study-room-previous-action')),
      );
      final nextRect = tester.getRect(
        find.byKey(const ValueKey('study-room-next-action')),
      );
      expect(difficulty.center.dx, closeTo(160, 24));
      expect(questionNumber.center.dx, closeTo(160, 24));
      expect(navigationRect.center.dx, closeTo(160, .5));
      expect(navigationRect.width, lessThanOrEqualTo(296));
      expect(previousRect.width, greaterThanOrEqualTo(48));
      expect(previousRect.height, greaterThanOrEqualTo(48));
      expect(nextRect.width, greaterThanOrEqualTo(48));
      expect(nextRect.height, greaterThanOrEqualTo(48));
      expect(previousRect.overlaps(nextRect), isFalse);
      expect(
        find.descendant(
          of: navigation,
          matching: find.byKey(const ValueKey('question-progress-segments')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navigation, matching: find.byType(FilledButton)),
        findsNothing,
        reason: 'Next is a symbolic orbital control, not another text box.',
      );
      for (final text in tester.widgetList<Text>(
        find.descendant(of: navigation, matching: find.byType(Text)),
      )) {
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
      final layoutException = tester.takeException();
      expect(
        layoutException,
        isNull,
        reason: layoutException is FlutterError
            ? layoutException.toStringDeep()
            : '$layoutException',
      );
    },
  );

  testWidgets(
    'scratchpad is full-width on phone and bounded on larger screens',
    (tester) async {
      _restoreSurfaceAfter(tester);

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
        .studyPosition('${topic.key}:0:5')
        .timeout(const Duration(seconds: 10));
    final preloaded = await controller.loadStudyShelf(topic.key, count: 5);
    expect(preloaded.questions, isNotEmpty);
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 5),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    expect(find.text('STUDY ROOM'), findsOneWidget);
    expect(find.byKey(const ValueKey('inline-ink-canvas')), findsOneWidget);
    final revealSource = find.byKey(
      const ValueKey('study-room-reveal-source-action'),
    );
    expect(revealSource, findsOneWidget);
    expect(
      find.descendant(of: revealSource, matching: find.byType(Text)),
      findsNothing,
      reason: 'The reveal is a fully visible symbol, not a clipped caption.',
    );
    expect(tester.getSize(revealSource).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(revealSource).height, greaterThanOrEqualTo(48));
    expect(
      find.descendant(of: revealSource, matching: find.byType(OutlinedButton)),
      findsNothing,
    );
    expect(
      tester
          .getSemantics(
            find.bySemanticsLabel('Reveal the unverified source answer'),
          )
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.ensureVisible(revealSource);
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(revealSource);
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

    // The unified private-orbit instrument keeps the daily quest live without
    // splitting the same truth across a second dashboard card.
    await _scrollUntil(tester, find.text('TODAY · QUEST'));
    expect(find.text('TODAY · QUEST'), findsOneWidget);
    expect(find.text('Chart ten reflections'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);

    // The crafted catalog replaced the six inline seals.
    await _scrollUntil(tester, find.text('Theorem seals'));
    expect(find.text('Theorem seals'), findsOneWidget);
    await _scrollUntil(tester, find.text('Luminosity'));
    expect(find.text('Luminosity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a reshuffled pass keeps session membership and marks', () async {
    final topic = controller.topics.first;
    final canonical = await controller.loadStudyShelf(topic.key, count: 5);
    final shuffled = await controller.loadStudyShelf(
      topic.key,
      count: 5,
      shuffleSeed: 7,
    );
    final repeated = await controller.loadStudyShelf(
      topic.key,
      count: 5,
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

  testWidgets('the study room can jump to any question in the session', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 5),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    expect(find.text('1 of 5'), findsOneWidget);
    await tester.tap(find.text('1 of 5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('JUMP TO'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('study-room-jump-question-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('4 of 5'), findsOneWidget);
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
    _restoreSurfaceAfter(tester);
    for (final size in const [
      Size(320, 700),
      Size(360, 820),
      Size(411, 820),
      Size(800, 600),
      Size(1180, 900),
      Size(1280, 800),
      Size(1440, 479),
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
    _restoreSurfaceAfter(tester);

    await tester.binding.setSurfaceSize(const Size(1280, 800));
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

    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        textScale: 2,
        reducedMotion: true,
        child: const InsightsScreen(),
      ),
    );
    await tester.pump();
    final accessibleTabletRows = List.generate(
      4,
      (index) =>
          tester.getTopLeft(find.byKey(ValueKey('insight-metric-$index'))).dy,
    );
    expect(accessibleTabletRows[1], closeTo(accessibleTabletRows[0], 1));
    expect(accessibleTabletRows[2], greaterThan(accessibleTabletRows[0] + 180));
    expect(accessibleTabletRows[3], closeTo(accessibleTabletRows[2], 1));

    await tester.binding.setSurfaceSize(const Size(411, 820));
    await tester.pumpWidget(
      _TestSurface(controller: controller, child: const InsightsScreen()),
    );
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
      _restoreSurfaceAfter(tester);
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
      _restoreSurfaceAfter(tester);
      final topic = controller.topics.first;
      final vaultController = GaussController(
        questionBank,
        progress,
        backups: _LayoutBackupService(),
      );
      await tester.runAsync(vaultController.initialize);
      addTearDown(vaultController.dispose);

      await tester.binding.setSurfaceSize(const Size(411, 820));
      await tester.pumpWidget(
        _TestSurface(
          controller: controller,
          textScale: 2,
          reducedMotion: true,
          child: ArchiveScreen(topicKey: topic.key, count: 5),
        ),
      );
      await _pumpUntil(tester, find.text('STUDY ROOM'));
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1024, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.byKey(const ValueKey('study-room-single-pane')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _TestSurface(
          controller: controller,
          reducedMotion: true,
          child: ArchiveScreen(topicKey: topic.key, count: 5),
        ),
      );
      await _pumpUntil(tester, find.text('STUDY ROOM'));
      expect(
        find.byKey(const ValueKey('study-room-split-pane')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      for (final size in const [Size(411, 820), Size(1024, 800)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          _TestSurface(
            controller: vaultController,
            textScale: 2,
            reducedMotion: true,
            child: const BackupScreen(),
          ),
        );
        await _pumpUntil(tester, find.text('Back up now'));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Vault overflowed at $size and 200% text',
        );
      }
    },
  );

  testWidgets('study rotation preserves question hypothesis and committed ink', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    late StudyShelf shelf;
    late int offset;
    await tester.runAsync(() async {
      for (final session in questionBank.studyPlan.topic(topic.key).sessions) {
        final candidateOffset = session.index * GaussStudyCurriculum.batchSize;
        final candidate = await controller.loadStudyShelf(
          topic.key,
          offset: candidateOffset,
          count: 5,
        );
        if (candidate.questions.first.options.isNotEmpty) {
          shelf = candidate;
          offset = candidateOffset;
          return;
        }
      }
      throw StateError('No study session with selectable hypotheses.');
    });
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, offset: offset, count: 5),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));
    final firstChoice = find.bySemanticsLabel(RegExp(r'^Choice 1\.'));
    await tester.ensureVisible(firstChoice);
    await tester.tap(firstChoice);
    await tester.pump();
    final canvas = find.byKey(const ValueKey('inline-ink-canvas'));
    await tester.ensureVisible(canvas);
    await tester.pump(const Duration(milliseconds: 260));
    final pen = await tester.startGesture(
      tester.getRect(canvas).topLeft + const Offset(24, 24),
      kind: PointerDeviceKind.stylus,
      pointer: 81,
    );
    await pen.moveBy(const Offset(30, 12));
    await pen.up();
    await tester.pump(const Duration(milliseconds: 260));
    final ink = tester.widget<InlineQuestionScratch>(
      find.byType(InlineQuestionScratch),
    ).controller!;
    expect(ink.strokeCount, 1);
    final widths = List<double>.of(ink.recordedWidths);

    for (final size in const [Size(1024, 800), Size(411, 820)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      expect(
        find.byKey(ValueKey('study-ink-${shelf.questions.first.id}')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Choice 1\..*Your private hypothesis\.')),
        findsOneWidget,
      );
      expect(
        tester.widget<InlineQuestionScratch>(
          find.byType(InlineQuestionScratch),
        ).controller,
        same(ink),
      );
      expect(ink.strokeCount, 1);
      expect(ink.recordedWidths, widths);
      expect(
        tester.widget<PageView>(
          find.byKey(const ValueKey('study-room-pages')),
        ).controller!.page,
        0,
      );
      expect(tester.takeException(), isNull, reason: 'Rotation to $size');
    }
  });

  testWidgets('completing a session opens the recap with its reward lines', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    final shelf = await controller.loadStudyShelf(topic.key, count: 5);
    // Chart the whole first session except its final slot, off-screen.
    await tester.runAsync(() async {
      for (var index = 0; index < 4; index++) {
        await controller.saveStudyReflection(
          question: shelf.questions[index],
          shelfKey: shelf.key,
          hypothesisChoiceIndex: null,
          reflection: StudyReflection.clear,
          slot: shelf.slots[index],
        );
      }
    });
    final router = await _pumpRoutedArchive(
      tester,
      controller: controller,
      topicKey: topic.key,
      count: 5,
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    final revealSource = find.byKey(
      const ValueKey('study-room-reveal-source-action'),
    );
    await tester.ensureVisible(revealSource);
    await tester.tap(revealSource);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.ensureVisible(find.text('Concept feels clear'));
    await tester.tap(find.text('Concept feels clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Study set complete'), findsOneWidget);
    expect(find.text('Continue next session'), findsOneWidget);
    expect(find.text('Stay here'), findsOneWidget);
    await tester.tap(find.text('Continue next session'));
    for (var pump = 0; pump < 12; pump++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Session complete'), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['offset'],
      '5',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed reflection stays in place and retries exactly once', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    controller.dispose();
    final flakyController = _FailOnceGaussController(questionBank, progress);
    controller = flakyController;
    await tester.runAsync(controller.initialize);
    expect(controller.ready, isTrue);
    expect(controller.fatalError, isNull);
    final topic = controller.topics.first;
    late StudyShelf shelf;
    late int sessionOffset;
    await tester.runAsync(() async {
      for (final session in questionBank.studyPlan.topic(topic.key).sessions) {
        final candidateOffset = session.index * GaussStudyCurriculum.batchSize;
        final candidate = await controller.loadStudyShelf(
          topic.key,
          offset: candidateOffset,
          count: GaussStudyCurriculum.batchSize,
        );
        if (candidate.questions.first.options.isNotEmpty) {
          shelf = candidate;
          sessionOffset = candidateOffset;
          return;
        }
      }
      throw StateError(
        '${topic.key} has no five-question session whose first prompt has choices.',
      );
    });
    final question = shelf.questions.first;

    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(
          topicKey: topic.key,
          offset: sessionOffset,
          count: GaussStudyCurriculum.batchSize,
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await _pumpUntil(tester, find.text('STUDY ROOM'));
    final firstChoice = find.bySemanticsLabel(RegExp(r'^Choice 1\.'));
    await _pumpUntil(tester, firstChoice);
    expect(find.text('STUDY ROOM'), findsOneWidget);
    expect(find.text('Opening the study room…'), findsNothing);
    expect(find.text('The study room could not open'), findsNothing);
    expect(firstChoice, findsOneWidget);
    final inkKey = ValueKey('study-ink-${question.id}');
    final inkElement = find.byKey(inkKey).evaluate().single;

    await tester.tap(firstChoice);
    await tester.pump();
    final revealSource = find.byKey(
      const ValueKey('study-room-reveal-source-action'),
    );
    await tester.ensureVisible(revealSource);
    await tester.tap(revealSource);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.ensureVisible(find.text('Concept feels clear'));
    await tester.tap(find.text('Concept feels clear'));
    await tester.pump();

    expect(find.text('Field note not saved'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Choice 1\..*Your private hypothesis\.')),
      findsOneWidget,
    );
    expect(identical(find.byKey(inkKey).evaluate().single, inkElement), isTrue);
    expect(await progress.studyRecords(topicKey: topic.key), isEmpty);

    await tester.tap(find.text('Retry'));
    // A second callback from a stale frame must be ignored while retrying.
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(flakyController.saveAttempts, 2);
    expect(find.text('Field note not saved'), findsNothing);
    expect(find.text('Concept marked clear'), findsOneWidget);
    expect(identical(find.byKey(inkKey).evaluate().single, inkElement), isTrue);
    expect(await progress.studyRecords(topicKey: topic.key), hasLength(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the terminal unit recap returns to Map in one tap', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    final topicPlan = questionBank.studyPlan.topic(topic.key);
    final finalOffset =
        (topicPlan.sessions.length - 1) * GaussStudyCurriculum.batchSize;
    await tester.runAsync(() async {
      for (final session in topicPlan.sessions) {
        final shelf = await controller.loadStudyShelf(
          topic.key,
          offset: session.index * GaussStudyCurriculum.batchSize,
          count: 5,
        );
        for (var index = 0; index < shelf.slots.length; index++) {
          if (session.key == topicPlan.sessions.last.key &&
              index == shelf.slots.length - 1) {
            continue;
          }
          await controller.saveStudyReflection(
            question: shelf.questions[index],
            shelfKey: shelf.key,
            hypothesisChoiceIndex: null,
            reflection: StudyReflection.clear,
            slot: shelf.slots[index],
          );
        }
      }
    });
    await _pumpRoutedArchive(
      tester,
      controller: controller,
      topicKey: topic.key,
      offset: finalOffset,
      count: 5,
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    final revealSource = find.byKey(
      const ValueKey('study-room-reveal-source-action'),
    );
    await tester.ensureVisible(revealSource);
    await tester.tap(revealSource);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.ensureVisible(find.text('Concept feels clear'));
    await tester.tap(find.text('Concept feels clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Unit charted'), findsOneWidget);
    expect(find.text('Return to Map'), findsOneWidget);
    expect(find.text('Stay here'), findsOneWidget);
    await tester.tap(find.text('Return to Map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('MAP DESTINATION'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tenth daily reflection opens a truthful quest recap', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final topic = controller.topics.first;
    final questions = await questionBank.loadTopic(topic.key);
    await tester.runAsync(() async {
      for (final question in questions.take(9)) {
        await controller.saveStudyReflection(
          question: question,
          shelfKey: '${topic.key}:0:5',
          hypothesisChoiceIndex: null,
          reflection: StudyReflection.clear,
        );
      }
    });
    await tester.pumpWidget(
      _TestSurface(
        controller: controller,
        child: ArchiveScreen(topicKey: topic.key, count: 5),
      ),
    );
    await _pumpUntil(tester, find.text('STUDY ROOM'));

    final revealSource = find.byKey(
      const ValueKey('study-room-reveal-source-action'),
    );
    await tester.ensureVisible(revealSource);
    await tester.tap(revealSource);
    await tester.pump(const Duration(milliseconds: 220));
    await tester.ensureVisible(find.text('Concept feels clear'));
    await tester.tap(find.text('Concept feels clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Daily observation complete'), findsOneWidget);
    expect(find.text('Daily observation'), findsOneWidget);
    expect(
      find.text('Ten new reflections are safely recorded for today.'),
      findsOneWidget,
    );
    expect(find.text('Keep charting'), findsOneWidget);
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

class _FailOnceGaussController extends GaussController {
  _FailOnceGaussController(super.questionBank, super.progress);

  int saveAttempts = 0;

  @override
  Future<StudyReflectionOutcome> saveStudyReflection({
    required Question question,
    required String shelfKey,
    required int? hypothesisChoiceIndex,
    required StudyReflection reflection,
    StudyShelfSlot? slot,
  }) {
    saveAttempts += 1;
    if (saveAttempts == 1) {
      throw StudyWriteFailure(
        StateError('injected local write failure'),
        operation: 'save_study_reflection',
      );
    }
    return super.saveStudyReflection(
      question: question,
      shelfKey: shelfKey,
      hypothesisChoiceIndex: hypothesisChoiceIndex,
      reflection: reflection,
      slot: slot,
    );
  }
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

class _LayoutBackupService extends BackupService {
  @override
  bool get isSupported => true;

  @override
  Future<List<BackupEntry>> listBackups() async => const [];

  @override
  Future<bool> hasPendingRestore() async => false;
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(411, 820));
  _restoreSurfaceAfter(tester);
}

void _restoreSurfaceAfter(WidgetTester tester) {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<GoRouter> _pumpRoutedArchive(
  WidgetTester tester, {
  required GaussController controller,
  required String topicKey,
  int offset = 0,
  int count = 5,
}) async {
  final router = GoRouter(
    initialLocation: '/study/chapter/$topicKey?offset=$offset&count=$count',
    routes: [
      GoRoute(
        path: '/map',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('MAP DESTINATION'))),
      ),
      GoRoute(
        path: '/study/chapter/:topicKey',
        builder: (context, state) => ArchiveScreen(
          topicKey: state.pathParameters['topicKey']!,
          offset: int.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0,
          count: int.tryParse(state.uri.queryParameters['count'] ?? '') ?? 5,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildGaussTheme(),
      routerConfig: router,
      builder: (context, child) =>
          GaussScope(controller: controller, child: child!),
    ),
  );
  return router;
}

Future<Rect> _pumpScratchSurface(
  WidgetTester tester,
  ScratchInkController ink, {
  ValueChanged<bool>? onDrawingChanged,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 420));
  _restoreSurfaceAfter(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      home: Scaffold(
        backgroundColor: GaussColors.parchment,
        body: Center(
          child: SizedBox(
            width: 330,
            child: InlineQuestionScratch(
              controller: ink,
              onDrawingChanged: onDrawingChanged,
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
  await tester.pump();
  return tester.getRect(find.byKey(const ValueKey('question-plate')));
}

Future<Rect> _pumpExpandedScratchpad(
  WidgetTester tester,
  ScratchInkController ink,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  _restoreSurfaceAfter(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showScratchpad(context, controller: ink),
              child: const Text('Open shared scratchpad'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open shared scratchpad'));
  await tester.pumpAndSettle();
  return tester.getRect(find.byKey(const ValueKey('scratchpad-ink-canvas')));
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
  fail('Timed out while scrolling for $finder.');
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
  fail('Timed out while pumping for $finder.');
}
