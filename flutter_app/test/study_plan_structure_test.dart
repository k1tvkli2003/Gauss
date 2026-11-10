// The chapter and lesson structure must stay logical: lessons follow the
// registry units in order, units are never scattered, every source question is
// a primary exactly once, and no lesson is short.
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/study_curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuestionBankRepository bank;
  setUpAll(() async {
    bank = QuestionBankRepository();
    await bank.initialize();
  });

  test('every lesson has five slots and every question is a primary once', () {
    final primaries = <String>{};
    var lessons = 0;
    for (final topic in bank.topics) {
      for (final session in bank.studyPlan.topic(topic.key).sessions) {
        lessons++;
        expect(session.slots, hasLength(GaussStudyCurriculum.batchSize));
        for (final slot in session.slots) {
          if (slot.kind == StudySlotKind.primary) {
            expect(primaries.add(slot.questionId), isTrue);
          }
        }
        // Reviews only ever fill a chapter's final remainder lesson.
        if (session.slots.any((s) => s.kind == StudySlotKind.masteryReview)) {
          expect(
            session.index,
            bank.studyPlan.topic(topic.key).sessions.length - 1,
            reason: '${session.key} is not the final lesson',
          );
        }
      }
    }
    expect(primaries, hasLength(3672));
    expect(lessons, 744);
  });

  test('lessons follow units in order and units are never scattered', () {
    var singleUnit = 0;
    var lessons = 0;
    for (final topic in bank.topics) {
      final runs = <String>[];
      for (final session in bank.studyPlan.topic(topic.key).sessions) {
        lessons++;
        final units = <String>{};
        for (final slot in session.slots.where(
          (s) => s.kind == StudySlotKind.primary,
        )) {
          final unit = bank.subtopicIndex.unitOfQuestion(slot.questionId)!;
          units.add(unit.key);
          if (runs.isEmpty || runs.last != unit.key) runs.add(unit.key);
        }
        if (units.length == 1) singleUnit++;
        expect(session.title, isNotNull, reason: '${session.key} has a title');
        expect(session.unitKey, isNotNull);
      }
      expect(
        runs.toSet(),
        hasLength(runs.length),
        reason: '${topic.key}: a unit is split into separate runs',
      );
      // Registry order inside the chapter, "Mixed problems" always last.
      final order = bank.subtopicIndex
          .unitsOf(topic.key)
          .map((unit) => unit.key)
          .toList();
      final positions = runs.map(order.indexOf).toList();
      expect(positions, orderedEquals([...positions]..sort()));
    }
    expect(
      singleUnit / lessons,
      greaterThan(.7),
      reason: 'most lessons stay inside one unit',
    );
  });

  test('titles name the unit and parts count up inside it', () {
    for (final topic in bank.topics) {
      final byUnit = <String, List<StudySessionPlan>>{};
      for (final session in bank.studyPlan.topic(topic.key).sessions) {
        byUnit.putIfAbsent(session.unitKey!, () => []).add(session);
      }
      for (final lessons in byUnit.values) {
        for (var i = 0; i < lessons.length; i++) {
          expect(lessons[i].unitPart, i + 1);
          expect(lessons[i].unitParts, lessons.length);
          expect(
            lessons[i].partLabel,
            lessons.length > 1 ? '${i + 1}/${lessons.length}' : isNull,
          );
        }
      }
    }
  });
}
