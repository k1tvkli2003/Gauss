import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'question-bank bootstrap is atomic, concurrent-safe, and idempotent',
    () async {
      final bank = QuestionBankRepository();

      await Future.wait([bank.initialize(), bank.initialize()]);
      final firstPlan = bank.studyPlan;
      final firstTopics = bank.topics;

      await bank.initialize();

      expect(identical(bank.studyPlan, firstPlan), isTrue);
      expect(identical(bank.topics, firstTopics), isTrue);
      expect(bank.declaredTotal, 3672);
      expect(bank.topics, hasLength(29));
    },
  );

  test(
    'every authored node opens as one usable five-question mission',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();

      var sessionCount = 0;
      final primaryIds = <String>{};
      for (final topic in bank.studyPlan.topics) {
        for (final session in topic.sessions) {
          final offset = session.index * GaussStudyCurriculum.batchSize;
          expect(
            bank.isStudySessionPlayable(topic.topicKey, offset: offset),
            isTrue,
            reason: session.key,
          );
          final questions = await bank.createStudySessionMission(
            topic.topicKey,
            offset: offset,
          );
          expect(questions, hasLength(GaussStudyCurriculum.batchSize));
          expect(
            questions.every((question) => question.runtimeUsable),
            isTrue,
            reason: session.key,
          );
          for (var index = 0; index < session.slots.length; index++) {
            expect(questions[index].id, session.slots[index].questionId);
            if (session.slots[index].kind == StudySlotKind.primary) {
              expect(primaryIds.add(questions[index].id), isTrue);
            }
          }
          sessionCount++;
        }
      }

      expect(primaryIds, hasLength(3672));
      expect(sessionCount, 744);
    },
  );

  test(
    'legacy count links still open one five-slot session with explicit reviews',
    () async {
      final database = GaussDatabase(NativeDatabase.memory());
      final progress = ProgressRepository(database);
      final bank = QuestionBankRepository();
      final controller = GaussController(bank, progress);
      addTearDown(() async {
        controller.dispose();
        await database.close();
      });
      await controller.initialize();

      const topicKey = 'rational_inequalities_sign';
      final topicPlan = bank.studyPlan.topic(topicKey);
      final finalOffset =
          (topicPlan.sessions.length - 1) * GaussStudyCurriculum.batchSize;
      final shelf = await controller.loadStudyShelf(
        topicKey,
        offset: finalOffset,
        count: 20,
      );

      expect(shelf.key, '$topicKey:$finalOffset:5');
      expect(shelf.questions, hasLength(5));
      expect(shelf.slots, hasLength(5));
      expect(shelf.slots.where((slot) => slot.kind == 'primary'), hasLength(1));
      expect(
        shelf.slots.where((slot) => slot.kind == 'mastery_review'),
        hasLength(4),
      );

      final reviewIndex = shelf.slots.indexWhere(
        (slot) => slot.kind == StudySlotKind.masteryReview.key,
      );
      final reviewSlot = shelf.slots[reviewIndex];
      final question = shelf.questions[reviewIndex];
      expect(reviewSlot.primaryShelfKey, isNot(shelf.key));
      expect(shelf.isEncounteredAt(reviewIndex), isFalse);

      final first = await controller.saveStudyReflection(
        question: question,
        shelfKey: shelf.key,
        hypothesisChoiceIndex: null,
        reflection: StudyReflection.clear,
        slot: reviewSlot,
      );
      expect(first.setCompleted, isFalse);
      expect(controller.study.shelf(shelf.key).reflected, 1);
      expect(
        (await progress.studyRecords(topicKey: topicKey)).single.shelfKey,
        reviewSlot.primaryShelfKey,
      );

      final replay = await controller.saveStudyReflection(
        question: question,
        shelfKey: shelf.key,
        hypothesisChoiceIndex: null,
        reflection: StudyReflection.clear,
        slot: reviewSlot,
      );
      expect(replay.setCompleted, isFalse);
      expect(replay.xpEarned, 0);
      expect(controller.study.shelf(shelf.key).reflected, 1);
    },
  );
}
