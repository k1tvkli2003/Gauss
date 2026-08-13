import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every preserved chapter belongs to exactly one subject section',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();

      for (final subject in Subject.values) {
        final expected = bank.topics
            .where((topic) => topic.subject == subject)
            .map((topic) => topic.key)
            .toSet();
        final assigned = GaussStudyCurriculum.forSubject(
          subject,
        ).expand((section) => section.topicKeys).toList(growable: false);
        expect(assigned.toSet(), expected);
        expect(assigned.toSet().length, assigned.length);
      }
    },
  );

  test(
    'every node is one five-slot session and every source question is primary once',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();
      final keys = <String>{};
      final primaryIds = <String>{};
      var reviewSlots = 0;

      for (final section in GaussStudyCurriculum.sections) {
        final nodes = GaussStudyCurriculum.nodesFor(section, bank.topics);
        expect(nodes, isNotEmpty);
        for (final node in nodes) {
          expect(keys.add(node.key), isTrue, reason: node.key);
          expect(node.questionCount, GaussStudyCurriculum.batchSize);
          final session = bank.studyPlan.session(node.topic.key, node.offset);
          expect(session.key, node.key);
          expect(session.slots, hasLength(GaussStudyCurriculum.batchSize));
          for (final slot in session.slots) {
            expect(slot.profile.subtopicKey, isNotEmpty);
            if (slot.kind == StudySlotKind.primary) {
              expect(primaryIds.add(slot.questionId), isTrue);
            } else {
              expect(slot.kind, StudySlotKind.masteryReview);
              reviewSlots += 1;
            }
          }
        }
      }

      expect(primaryIds, hasLength(bank.declaredTotal));
      expect(reviewSlots, 48);
      expect(keys.length, greaterThan(700));
    },
  );

  test('topic remainders are explicit semantic mastery-review mixes', () async {
    final bank = QuestionBankRepository();
    await bank.initialize();

    for (final topic in bank.topics) {
      final plan = bank.studyPlan.topic(topic.key);
      final finalSession = plan.sessions.last;
      final remainder = topic.questionCount % GaussStudyCurriculum.batchSize;
      final expectedPrimary = remainder == 0
          ? GaussStudyCurriculum.batchSize
          : remainder;
      expect(finalSession.primaryCount, expectedPrimary, reason: topic.key);
      expect(
        finalSession.slots
            .where((slot) => slot.kind == StudySlotKind.masteryReview)
            .length,
        GaussStudyCurriculum.batchSize - expectedPrimary,
        reason: topic.key,
      );
      for (final review in finalSession.slots.where(
        (slot) => slot.kind == StudySlotKind.masteryReview,
      )) {
        final primary = bank.studyPlan.primarySlot(review.questionId);
        expect(primary.sessionKey, review.primarySessionKey);
        expect(primary.sessionKey, isNot(finalSession.key));
        expect(primary.profile.subtopicKey, review.profile.subtopicKey);
        expect(primary.profile.concepts, review.profile.concepts);
        expect(primary.profile.prerequisites, review.profile.prerequisites);
        expect(primary.profile.difficulty, review.profile.difficulty);
      }
    }
  });

  test(
    'screened subtopics replace raw source order as the grouping signal',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();
      var reorderedTopics = 0;
      var rawSameSubtopicAdjacency = 0;
      var plannedSameSubtopicAdjacency = 0;

      for (final topic in bank.topics) {
        final primarySlots = bank.studyPlan
            .topic(topic.key)
            .sessions
            .expand((session) => session.slots)
            .where((slot) => slot.kind == StudySlotKind.primary)
            .toList(growable: false);
        final profileById = {
          for (final slot in primarySlots) slot.questionId: slot.profile,
        };
        final rawIds = (await bank.loadTopic(
          topic.key,
        )).map((question) => question.id).toList(growable: false);
        final plannedIds = primarySlots
            .map((slot) => slot.questionId)
            .toList(growable: false);
        if (List<int>.generate(
          rawIds.length,
          (index) => index,
        ).any((index) => rawIds[index] != plannedIds[index])) {
          reorderedTopics += 1;
        }
        for (var index = 1; index < rawIds.length; index++) {
          if (profileById[rawIds[index - 1]]!.subtopicKey ==
              profileById[rawIds[index]]!.subtopicKey) {
            rawSameSubtopicAdjacency += 1;
          }
          if (primarySlots[index - 1].profile.subtopicKey ==
              primarySlots[index].profile.subtopicKey) {
            plannedSameSubtopicAdjacency += 1;
          }
        }
      }

      expect(reorderedTopics, bank.topics.length);
      expect(
        plannedSameSubtopicAdjacency,
        greaterThan(rawSameSubtopicAdjacency),
      );
    },
  );
}
