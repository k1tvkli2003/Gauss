import 'dart:convert';
import 'dart:io';

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

  test('the unit classification covers every question exactly once', () async {
    final index = bank.subtopicIndex;
    expect(index.unitCount, greaterThan(250));

    final seen = <String>{};
    for (final topic in bank.topics) {
      final units = index.unitsOf(topic.key);
      expect(units, isNotEmpty, reason: '${topic.key} has units');
      var count = 0;
      for (final unit in units) {
        expect(unit.topicKey, topic.key);
        expect(unit.label.trim(), isNotEmpty);
        for (final id in unit.questionIds) {
          expect(seen.add(id), isTrue, reason: '$id is in two units');
        }
        count += unit.questionCount;
      }
      expect(count, topic.questionCount, reason: '${topic.key} fully covered');

      // The unit belongs to the same topic the question is shipped under.
      for (final question in await bank.loadTopic(topic.key)) {
        expect(index.unitOfQuestion(question.id)?.topicKey, topic.key);
      }
    }
    expect(seen, hasLength(3672));
  });

  test('unclassified questions sit in an explicit Mixed problems unit', () {
    final mixed = [
      for (final topic in bank.topics)
        ...bank.subtopicIndex.unitsOf(topic.key).where((u) => u.isMixed),
    ];
    expect(mixed, isNotEmpty);
    expect(mixed.every((unit) => unit.label == 'Mixed problems'), isTrue);
    // Mixed units always come last in their chapter.
    for (final topic in bank.topics) {
      final units = bank.subtopicIndex.unitsOf(topic.key);
      for (var i = 0; i < units.length - 1; i++) {
        expect(units[i].isMixed, isFalse, reason: '${topic.key} order');
      }
    }
  });

  test(
    'every unit points at a real lesson that contains its questions',
    () async {
      for (final topic in bank.topics) {
        final plan = bank.studyPlan.topic(topic.key);
        for (final unit in bank.subtopicIndex.unitsOf(topic.key)) {
          final members = unit.questionIds.toSet();
          final lessonIndex = plan.sessions.indexWhere(
            (session) =>
                session.slots.any((slot) => members.contains(slot.questionId)),
          );
          expect(
            lessonIndex,
            isNonNegative,
            reason: '${unit.key} has a lesson',
          );
          final lesson = await bank.createStudySessionMission(
            topic.key,
            offset: lessonIndex * GaussStudyCurriculum.batchSize,
          );
          expect(lesson, hasLength(GaussStudyCurriculum.batchSize));
        }
      }
    },
  );

  test('the committed asset is current with the taxonomy sources', () async {
    final result = await Process.run('python3', [
      '-I',
      '../scripts/build_subtopic_index.py',
      '--check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(
      (jsonDecode(
            File('assets/curriculum/subtopic_index_v1.json').readAsStringSync(),
          )
          as Map)['schema_version'],
      1,
    );
  });
}
