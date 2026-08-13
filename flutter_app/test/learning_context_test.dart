import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/screens/practice_screen.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GaussDatabase database;
  late ProgressRepository progress;
  late GaussController controller;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    progress = ProgressRepository(database);
    controller = GaussController(QuestionBankRepository(), progress);
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets(
    'a physics topic selected on Map is Physics on the first Study frame',
    (tester) async {
      await controller.selectTopic('work_energy_power');

      await tester.pumpWidget(_StudySurface(controller: controller));

      expect(find.text('PHYSICS ATLAS'), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('study-subject-physics')),
            )
            .properties
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('study-subject-math')))
            .properties
            .selected,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'controller recreation restores the exact valid selected topic',
    () async {
      const exactTopic = 'current_electricity';
      await controller.selectTopic(exactTopic);

      final restored = GaussController(
        QuestionBankRepository(),
        ProgressRepository(database),
      );
      addTearDown(restored.dispose);
      await restored.initialize();

      expect(restored.ready, isTrue);
      expect(restored.fatalError, isNull);
      expect(restored.selectedTopicKey, exactTopic);
      expect(restored.selectedTopic.subject, Subject.physics);
    },
  );

  test('a stale saved topic heals to the first valid topic', () async {
    await progress.writeLearningContextTopic('removed_topic_from_old_corpus');

    final restored = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    addTearDown(restored.dispose);
    await restored.initialize();

    expect(restored.ready, isTrue);
    expect(restored.fatalError, isNull);
    expect(restored.selectedTopicKey, restored.topics.first.key);
    expect(
      await progress.readLearningContextTopic(),
      restored.topics.first.key,
      reason: 'the invalid optional flag should be repaired for next launch',
    );
  });

  testWidgets('Study subject switch updates controller and durable context', (
    tester,
  ) async {
    await tester.pumpWidget(_StudySurface(controller: controller));
    expect(controller.selectedTopic.subject, Subject.math);

    await tester.tap(find.byKey(const ValueKey('study-subject-physics')));
    await tester.pump();

    expect(controller.selectedTopic.subject, Subject.physics);
    expect(find.text('PHYSICS ATLAS'), findsOneWidget);
    expect(
      await progress.readLearningContextTopic(),
      controller.selectedTopicKey,
    );
    expect(tester.takeException(), isNull);
  });

  test('learning-context storage failure stays non-fatal', () async {
    final resilient = GaussController(
      QuestionBankRepository(),
      _FailingContextProgressRepository(database),
    );
    addTearDown(resilient.dispose);

    await resilient.initialize();
    expect(resilient.ready, isTrue);
    expect(resilient.fatalError, isNull);

    await resilient.selectTopic('physics_measurement');
    expect(resilient.selectedTopicKey, 'physics_measurement');
    expect(resilient.fatalError, isNull);
  });
}

class _StudySurface extends StatelessWidget {
  const _StudySurface({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildGaussTheme(),
    home: GaussScope(
      controller: controller,
      child: const Scaffold(body: PracticeScreen()),
    ),
  );
}

class _FailingContextProgressRepository extends ProgressRepository {
  _FailingContextProgressRepository(super.database);

  @override
  Future<String?> readLearningContextTopic() =>
      Future<String?>.error(StateError('context read unavailable'));

  @override
  Future<void> writeLearningContextTopic(String topicKey) =>
      Future<void>.error(StateError('context write unavailable'));
}
