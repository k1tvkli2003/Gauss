import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/screens/mission_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/widgets/mission_start_guard.dart';
import 'package:gauss/widgets/content_blocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Question sampleQuestion;
  late Question archiveQuestion;

  setUpAll(() async {
    final questionBank = QuestionBankRepository();
    await questionBank.initialize();
    archiveQuestion = (await questionBank.loadTopic('sets')).first;
    sampleQuestion = _verifiedMissionFixture();
  });

  test(
    'controller recreation safely suppresses a source-archive mission',
    () async {
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final questionBank = QuestionBankRepository();
      final first = GaussController(questionBank, ProgressRepository(database));
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
      await restarted.initialize();
      final saved = restarted.resumableMission;

      expect(
        restarted.fatalError,
        isNull,
        reason: '${restarted.fatalError?.cause}',
      );
      expect(saved, isNull);
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
    await _pumpUntilFound(tester, find.text('Skip'));

    await tester.tap(find.text('Skip'));
    await _pumpUntilFound(tester, find.text('Try again'));
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _pumpUntilFound(tester, find.text('Next question'));
    expect(find.text('Next question'), findsOneWidget);
    expect(controller.savedAttempts, hasLength(1));
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

class _MissionTestController extends GaussController {
  _MissionTestController(this.question, GaussDatabase database)
    : super(QuestionBankRepository(), ProgressRepository(database));

  final Question question;
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
    if (!_failed) {
      _failed = true;
      throw StateError('simulated local write interruption');
    }
    savedAttempts.add(attempt);
  }
}
