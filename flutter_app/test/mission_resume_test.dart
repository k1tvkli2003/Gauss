import 'dart:convert';
import 'dart:ui' show SemanticsAction;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/feedback/feedback_capture.dart';
import 'package:gauss/feedback/feedback_models.dart';
import 'package:gauss/screens/mission_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/widgets/mission_start_guard.dart';
import 'package:gauss/widgets/content_blocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Question sampleQuestion;
  late Question archiveQuestion;
  late Question representativePersianQuestion;

  setUpAll(() async {
    final regular = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/vazirmatn_regular.ttf'));
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/manrope_variable.ttf'));
    await Future.wait([regular.load(), manrope.load()]);
    final questionBank = QuestionBankRepository();
    await questionBank.initialize();
    archiveQuestion = (await questionBank.loadTopic('sets')).first;
    representativePersianQuestion = (await questionBank.loadTopic(
      'patterns_sequences',
    )).firstWhere((question) => question.id == 'nardebam_math_1405_0065');
    sampleQuestion = _verifiedMissionFixture();
  });

  test(
    'controller recreation resumes provisionally usable source questions',
    () async {
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final questionBank = QuestionBankRepository();
      final first = GaussController(questionBank, ProgressRepository(database));
      addTearDown(first.dispose);
      await first.initialize();
      final questions = [archiveQuestion];
      final startedAt = DateTime(2026, 7, 12, 16);
      await first.startMission(
        sessionId: 'restart-safe',
        topicKey: 'sets',
        createdAt: startedAt,
        questions: questions,
      );
      await first.recordAttempt(
        AttemptRecord(
          sessionId: 'restart-safe',
          missionIndex: 0,
          questionId: questions.first.id,
          subject: questions.first.subject,
          topicKey: questions.first.topicKey,
          selectedChoiceIndex: questions.first.correctChoiceIndex,
          correct: true,
          elapsedSeconds: 12,
          at: startedAt.add(const Duration(seconds: 12)),
        ),
      );

      final restarted = GaussController(
        QuestionBankRepository(),
        ProgressRepository(database),
      );
      addTearDown(restarted.dispose);
      await restarted.initialize();
      final saved = await restarted.loadResumableMission();

      expect(
        restarted.fatalError,
        isNull,
        reason: '${restarted.fatalError?.cause}',
      );
      expect(saved, isNotNull);
      expect(saved!.questions.single.id, archiveQuestion.id);
      expect(saved.questions.single.runtimeUsable, isTrue);
    },
  );

  test(
    'a draft referencing deleted corpus ids retires instead of bricking startup',
    () async {
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final progress = ProgressRepository(database);
      // A pre-migration draft: its question id no longer exists anywhere in
      // the nardebam-only bank.
      await progress.startMission(
        sessionId: 'stale-corpus-draft',
        subject: Subject.math,
        topicKey: 'sets',
        createdAt: DateTime(2026, 7, 12, 16).millisecondsSinceEpoch,
        questionIds: const ['gauss_functions_0001_removed'],
      );

      final controller = GaussController(QuestionBankRepository(), progress);
      addTearDown(controller.dispose);
      await controller.initialize();

      expect(
        controller.fatalError,
        isNull,
        reason: '${controller.fatalError?.cause}',
      );
      expect(controller.resumableMission, isNull);
    },
  );

  testWidgets('failed skip exposes a working retry action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dummyDatabase = GaussDatabase(NativeDatabase.memory());
    addTearDown(dummyDatabase.close);
    final controller = _MissionTestController(sampleQuestion, dummyDatabase);

    await tester.pumpWidget(
      MaterialApp(
        home: GaussScope(
          controller: controller,
          child: const MissionScreen(topicKey: 'sets', count: 5),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('mission-skip-action')),
    );

    await tester.tap(find.byKey(const ValueKey('mission-skip-action')));
    await _pumpUntilFound(tester, find.bySemanticsLabel('Try again'));
    expect(find.bySemanticsLabel('Try again'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mission-primary-action')));
    await _pumpUntilFound(tester, find.bySemanticsLabel('Next question'));
    expect(find.bySemanticsLabel('Next question'), findsOneWidget);
    expect(controller.savedAttempts, hasLength(1));
  });

  testWidgets('question issue action saves exact local repair context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = GaussDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = _MissionTestController(
      archiveQuestion,
      database,
      failFirstSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: GaussScope(
          controller: controller,
          child: const MissionScreen(topicKey: 'sets', count: 5),
        ),
      ),
    );
    final reportAction = find.byKey(
      const ValueKey('mission-report-question-action'),
    );
    await _pumpUntilFound(tester, reportAction);
    await tester.ensureVisible(reportAction);
    await tester.tap(reportAction);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('question-issue-sheet')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('question-issue-kind-answer_key')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('question-issue-note')),
      'The keyed option looks inconsistent.',
    );
    await tester.tap(find.byKey(const ValueKey('question-issue-save')));
    await tester.pumpAndSettle();

    final reports = await ProgressRepository(database).questionIssueReports();
    expect(reports, hasLength(1));
    expect(reports.single.questionId, archiveQuestion.id);
    expect(reports.single.kind, QuestionIssueKind.answerKey);
    expect(reports.single.note, 'The keyed option looks inconsistent.');
    expect(reports.single.missionIndex, 0);
    expect(
      find.text('Question report saved to the private outbox.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'question report previews and stores an attached surface in the app shell',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(
        archiveQuestion,
        database,
        failFirstSave: false,
      );
      await controller.feedback.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: GaussScope(
            controller: controller,
            child: GaussFeedbackCapture(
              controller: controller.feedback,
              routeName: () => '/mission/sets',
              screenshotProvider: () async =>
                  GaussFeedbackScreenshot(bytes: _onePixelPng, pixelRatio: 1),
              child: const MissionScreen(topicKey: 'sets', count: 5),
            ),
          ),
        ),
      );
      final reportAction = find.byKey(
        const ValueKey('mission-report-question-action'),
      );
      await _pumpUntilFound(tester, reportAction);
      await tester.ensureVisible(reportAction);
      await tester.tap(reportAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('question-issue-screenshot-preview')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('question-issue-save')));
      await tester.pumpAndSettle();

      expect(controller.feedback.entries, hasLength(1));
      expect(controller.feedback.entries.single.questionId, archiveQuestion.id);
      expect(controller.feedback.entries.single.hasScreenshot, isTrue);
      expect(
        await controller.feedback.readScreenshot(
          controller.feedback.entries.single,
        ),
        isNotNull,
      );
    },
  );

  testWidgets(
    'mission chrome stays fixed while contextual tools remain on the manuscript',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(sampleQuestion, database);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GaussScope(
            controller: controller,
            child: const MissionScreen(topicKey: 'sets', count: 5),
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('mission-question-action-dock')),
      );
      expect(tester.takeException(), isNull, reason: 'initial mission layout');
      expect(find.text('QUESTION 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mission-answer-manuscript')),
        findsOneWidget,
      );

      final header = tester.getRect(
        find.byKey(const ValueKey('mission-question-header-axis')),
      );
      final wordmark = tester.getCenter(
        find.byKey(const ValueKey('mission-centered-wordmark')),
      );
      final close = tester.getRect(
        find.byKey(const ValueKey('mission-close-action')),
      );
      final scratchpad = tester.getRect(
        find.byKey(const ValueKey('mission-scratchpad-action')),
      );
      final paperBefore = tester.getRect(
        find.byKey(const ValueKey('mission-question-paper')),
      );
      final dockBefore = tester.getRect(
        find.byKey(const ValueKey('mission-question-action-dock')),
      );
      expect(wordmark.dx, closeTo(header.center.dx, .5));
      expect(
        header.center.dx - close.center.dx,
        closeTo(scratchpad.center.dx - header.center.dx, .5),
      );
      expect(close.width, greaterThanOrEqualTo(48));
      expect(scratchpad.width, greaterThanOrEqualTo(48));
      expect(dockBefore.center.dx, closeTo(160, .5));
      expect(dockBefore.width, lessThanOrEqualTo(296));

      final plate = tester.getRect(
        find.byKey(const ValueKey('inline-ink-canvas')),
      );
      final pen = await tester.startGesture(
        plate.center,
        pointer: 91,
        kind: PointerDeviceKind.stylus,
      );
      await pen.moveBy(const Offset(24, 18));
      await pen.up();
      await tester.pump(const Duration(milliseconds: 260));
      expect(tester.takeException(), isNull, reason: 'ink control layout');

      expect(find.byKey(const ValueKey('inline-pen-halo')), findsNothing);
      expect(find.byKey(const ValueKey('mission-ink-controls')), findsNothing);
      expect(
        find.byKey(const ValueKey('mission-readiness-signal')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('manuscript-undo-tool')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('manuscript-eraser-tool')),
        findsOneWidget,
      );
      final paperAfterInk = tester.getRect(
        find.byKey(const ValueKey('mission-question-paper')),
      );
      expect(paperAfterInk.left, closeTo(paperBefore.left, .5));
      expect(paperAfterInk.right, closeTo(paperBefore.right, .5));
      expect(paperAfterInk.top, closeTo(paperBefore.top, .5));
      expect(
        tester.getRect(
          find.byKey(const ValueKey('mission-question-action-dock')),
        ),
        dockBefore,
      );

      await tester.tap(find.byKey(const ValueKey('manuscript-clear-tool')));
      await tester.pump(const Duration(milliseconds: 260));
      expect(tester.takeException(), isNull, reason: 'ink restore layout');
      expect(
        find.byKey(const ValueKey('manuscript-restore-tool')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('manuscript-restore-tool')));
      await tester.pump(const Duration(milliseconds: 260));
      expect(tester.takeException(), isNull, reason: 'restored ink layout');
      expect(
        find.byKey(const ValueKey('manuscript-clear-tool')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('mission-close-action')));
      await tester.pump();
      expect(find.text('Leave and clear question ink?'), findsOneWidget);
      expect(find.textContaining('Question ink is temporary'), findsOneWidget);
      await tester.tap(find.text('Keep writing'));
      await tester.pump();
      expect(find.text('Leave and clear question ink?'), findsNothing);
      expect(
        find.byKey(const ValueKey('manuscript-clear-tool')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'representative Persian mission keeps all four choices above the Android dock',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 914));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(
        representativePersianQuestion,
        database,
        failFirstSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GaussScope(
            controller: controller,
            child: const MissionScreen(
              topicKey: 'patterns_sequences',
              count: 5,
            ),
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('mission-question-action-dock')),
      );

      final scroll = tester.getRect(
        find.byKey(const ValueKey('mission-question-scroll')),
      );
      final fourthChoice = tester.getRect(
        find.bySemanticsLabel(RegExp(r'^Choice 4\. 9\.')),
      );
      final dock = tester.getRect(
        find.byKey(const ValueKey('mission-question-action-dock')),
      );
      expect(fourthChoice.top, greaterThanOrEqualTo(scroll.top));
      expect(fourthChoice.bottom, lessThanOrEqualTo(scroll.bottom + .5));
      expect(scroll.bottom, lessThanOrEqualTo(dock.top + .5));
      expect(dock.bottom, lessThanOrEqualTo(914 - 24));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mission preserves work while adapting between tablet portrait and landscape',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1280));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(
        sampleQuestion,
        database,
        failFirstSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GaussScope(
            controller: controller,
            child: const MissionScreen(topicKey: 'sets', count: 5),
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('mission-question-action-dock')),
      );

      expect(find.byKey(const ValueKey('mission-solution-pane')), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Choice 2\. B\.')));
      await tester.pump();

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mission-adaptive-review-workspace')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('mission-solution-pane')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mission-primary-action')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mission-solution-pane')),
        findsOneWidget,
      );
      expect(find.text('Fixture solution'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mission rejects squeezed tablet panes at 200 percent or compact height',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(
        sampleQuestion,
        database,
        failFirstSave: false,
      );

      Future<void> pumpAt(Size size, double textScale) async {
        await tester.binding.setSurfaceSize(size);
        // Flush the view-metrics notification before replacing the route.
        // This mirrors Android's resize ordering and prevents a stale
        // pre-rotation View size from influencing the next composition.
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildGaussTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: GaussScope(
              controller: controller,
              child: MissionScreen(
                key: ValueKey('mission-${size.width}-$textScale'),
                topicKey: 'sets',
                count: 5,
              ),
            ),
          ),
        );
        await _pumpUntilFound(
          tester,
          find.byKey(const ValueKey('mission-question-action-dock')),
        );
        expect(
          find.byKey(const ValueKey('mission-adaptive-review-workspace')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('mission-solution-pane')),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: '$size @ $textScale');
      }

      await pumpAt(const Size(1280, 800), 2);
      await pumpAt(const Size(1440, 479), 1);
    },
  );

  testWidgets(
    'checked mission reflows its feedback and complete solution at 320dp 200%',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(
        sampleQuestion,
        database,
        failFirstSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GaussScope(
            controller: controller,
            child: const MissionScreen(topicKey: 'sets', count: 5),
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('mission-question-action-dock')),
      );

      final correctChoice = find.bySemanticsLabel(RegExp(r'^Choice 2\. B\.'));
      await tester.ensureVisible(correctChoice);
      expect(
        tester
            .getSemantics(correctChoice)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'TalkBack must be able to activate an unchecked answer.',
      );
      await tester.tap(correctChoice);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('mission-primary-action')));
      await _pumpUntilFound(tester, find.text('Classic solution'));

      expect(find.bySemanticsLabel('Next question'), findsOneWidget);
      expect(controller.savedAttempts, hasLength(1));
      expect(find.text('Fixture solution'), findsOneWidget);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: 'Question UI must reflow rather than truncate ${text.data}.',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('answer-first reveal is a symbolic 48dp action at 320dp 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = GaussDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = _MissionTestController(
      sampleQuestion,
      database,
      failFirstSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: GaussScope(
          controller: controller,
          child: const MissionScreen(
            topicKey: 'sets',
            count: 5,
            coverChoices: true,
          ),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('mission-covered-choices')),
    );

    final panel = find.byKey(const ValueKey('mission-covered-choices'));
    final reveal = find.byKey(const ValueKey('mission-reveal-choices-action'));
    await tester.ensureVisible(reveal);
    await tester.pump();
    expect(tester.getRect(reveal).height, greaterThanOrEqualTo(48));
    expect(
      find.descendant(of: panel, matching: find.byType(FilledButton)),
      findsNothing,
      reason: 'Reveal is an orbital lens, not a generic text box.',
    );
    expect(find.bySemanticsLabel('Uncover answer choices'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Choice 1\. A\.')), findsNothing);

    await tester.tap(find.bySemanticsLabel('Uncover answer choices'));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'^Choice 1\. A\.')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'five-question completion is celebratory and scroll-safe at 320dp 200%',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = _MissionTestController(
        sampleQuestion,
        database,
        failFirstSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GaussScope(
            controller: controller,
            child: const MissionScreen(topicKey: 'sets', count: 5),
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('mission-question-action-dock')),
      );

      for (var index = 0; index < 5; index++) {
        final correctChoice = find.bySemanticsLabel(RegExp(r'^Choice 1\. A\.'));
        await tester.ensureVisible(correctChoice);
        await tester.tap(correctChoice);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('mission-primary-action')));
        await tester.pump(const Duration(milliseconds: 260));
        expect(controller.savedAttempts, hasLength(index + 1));
        expect(
          tester.takeException(),
          isNull,
          reason: 'checked question $index',
        );

        expect(
          find.bySemanticsLabel(
            index == 4 ? 'Finish mission' : 'Next question',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('mission-primary-action')));
        await tester.pump(const Duration(milliseconds: 320));
      }

      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('mission-completion-screen')),
      );
      await tester.pump();

      expect(find.text('5-QUESTION MISSION'), findsOneWidget);
      expect(
        find.text('Perfect orbit'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .join(' | '),
      );
      expect(find.text('+45 XP'), findsWidgets);
      expect(find.bySemanticsLabel('Start another mission'), findsOneWidget);
      expect(find.bySemanticsLabel('Return to map'), findsOneWidget);

      final dock = tester.getRect(
        find.byKey(const ValueKey('mission-completion-actions')),
      );
      final retry = tester.getRect(
        find.byKey(const ValueKey('mission-retry-action')),
      );
      final map = tester.getRect(
        find.byKey(const ValueKey('mission-map-action')),
      );
      expect(dock.center.dx, closeTo(160, .5));
      expect(dock.width, lessThanOrEqualTo(296));
      expect(retry.height, greaterThanOrEqualTo(48));
      expect(map.height, greaterThanOrEqualTo(48));

      await tester.ensureVisible(
        find.byKey(const ValueKey('mission-reward-receipt')),
      );
      await tester.pump();
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: 'Completion must reflow rather than truncate ${text.data}.',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving never implies an unchecked answer was saved', (
    tester,
  ) async {
    final database = GaussDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final controller = _MissionTestController(sampleQuestion, database);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: GaussScope(
          controller: controller,
          child: const MissionScreen(topicKey: 'sets', count: 5),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('mission-question-action-dock')),
    );

    final firstChoice = find.bySemanticsLabel(RegExp(r'^Choice 1\. A\.'));
    await tester.ensureVisible(firstChoice);
    await tester.pump();
    await tester.tap(firstChoice);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mission-close-action')));
    await tester.pump();

    expect(find.text('Leave this mission?'), findsOneWidget);
    expect(
      find.textContaining(
        'selected but unchecked answer has not been recorded',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pump();
    expect(find.text('Leave this mission?'), findsNothing);
    expect(controller.savedAttempts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved mission replacement requires an explicit choice', (
    tester,
  ) async {
    var allowed = false;
    final saved = ResumableMission(
      sessionId: 'saved',
      subject: sampleQuestion.subject,
      topicKey: sampleQuestion.topicKey,
      createdAt: DateTime(2026, 7, 12),
      questions: [sampleQuestion],
      attempts: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () async {
                allowed = await confirmMissionReplacement(context, saved);
              },
              child: const Text('Launch replacement'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Launch replacement'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Start a new mission?'), findsOneWidget);
    await tester.tap(find.text('Keep saved mission'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(allowed, isFalse);

    await tester.tap(find.text('Launch replacement'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Start new'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(allowed, isTrue);
  });

  testWidgets('compact answer content is exposed as button text, not a field', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentBlocksView(blocks: [TextBlock('15')], compact: true),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsNothing);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('question content stays selectable without textbox semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentBlocksView(blocks: [TextBlock('Question stem')]),
        ),
      ),
    );

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
    expect(find.text('Question stem'), findsOneWidget);
  });
}

Question _verifiedMissionFixture() => Question.fromJson({
  'id': 'verified_mission_fixture',
  'subject': 'math',
  'topic_key': 'sets',
  'difficulty': 'hard',
  'stem': [
    {'type': 'text', 'text': 'Fixture question'},
  ],
  'options': [
    [
      {'type': 'text', 'text': 'A'},
    ],
    [
      {'type': 'text', 'text': 'B'},
    ],
    [
      {'type': 'text', 'text': 'C'},
    ],
    [
      {'type': 'text', 'text': 'D'},
    ],
  ],
  'correct_option_index': 1,
  'solution': [
    {'type': 'text', 'text': 'Fixture solution'},
  ],
  'smart_shortcut': null,
  'source_bank': 'verified_fixture',
});

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  final visibleText = find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
  expect(finder, findsOneWidget, reason: 'Visible text: $visibleText');
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

class _MissionTestController extends GaussController {
  _MissionTestController(
    this.question,
    GaussDatabase database, {
    this.failFirstSave = true,
  }) : super(QuestionBankRepository(), ProgressRepository(database));

  final Question question;
  final bool failFirstSave;
  final List<AttemptRecord> savedAttempts = [];

  bool _failed = false;

  @override
  Future<List<Question>> createMission(
    String topicKey, {
    int count = 10,
    Set<Difficulty> difficulties = const {},
    Set<String> sourceBanks = const {},
  }) async => List.filled(count, question, growable: false);

  @override
  Future<void> startMission({
    required String sessionId,
    required String topicKey,
    required DateTime createdAt,
    required List<Question> questions,
    Subject? subject,
  }) async {}

  @override
  Future<void> recordAttempt(AttemptRecord attempt) async {
    if (failFirstSave && !_failed) {
      _failed = true;
      throw StateError('simulated local write interruption');
    }
    savedAttempts.add(attempt);
  }

  @override
  Future<MissionCompletion> completeMission({
    required String sessionId,
    required int durationSeconds,
  }) async => const MissionCompletion(
    examId: 77,
    xpEarned: 45,
    totalXp: 245,
    levelBefore: 1,
    levelAfter: 2,
    lines: [
      RewardLine(
        eventId: 'question_answered:test',
        ruleVersion: 1,
        reason: 'Correct answer',
        amount: 25,
        category: 'practice',
      ),
      RewardLine(
        eventId: 'exam_completed:test',
        ruleVersion: 1,
        reason: 'Mission complete',
        amount: 20,
        category: 'practice',
      ),
    ],
  );
}
