// Re-cutting lessons (plan v1 -> v2) must keep every charted question charted
// and must never leave one lesson showing another lesson's progress.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a re-cut plan keeps charted questions and shows no phantom progress',
    () async {
      final database = GaussDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = ProgressRepository(database);
      final bank = QuestionBankRepository();
      await bank.initialize();
      final newPlan = bank.studyPlan;
      final oldPlan = GaussStudyPlan.fromJson(
        jsonDecode(
              File('test/fixtures/plan_v1_sets_only.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      expect(oldPlan.version, isNot(newPlan.version));
      expect(newPlan.revision, greaterThan(oldPlan.revision));

      // Chart the first primary question of every old lesson of "sets".
      final charted = <String>[];
      for (final session in oldPlan.topic('sets').sessions) {
        final slot = session.slots.firstWhere(
          (slot) => slot.kind == StudySlotKind.primary,
        );
        charted.add(slot.questionId);
        await repository.saveStudyReflection(
          questionId: slot.questionId,
          topicKey: 'sets',
          subjectKey: 'math',
          shelfKey: slot.sessionKey,
          setSize: 5,
          topicQuestionCount: 50,
          hypothesisChoiceIndex: null,
          hypothesisMatched: null,
          reflection: StudyReflection.clear,
        );
      }
      await repository.migrateStudyPlan(oldPlan);
      expect((await repository.studySummary()).totalReflected, charted.length);

      // Now the app ships the re-cut plan.
      await repository.migrateStudyPlan(newPlan);
      final summary = await repository.studySummary();

      // 1. Every charted question is still charted, once.
      expect(summary.totalReflected, charted.length);
      expect(summary.reflectedQuestionIds, charted.toSet());

      // 2. Each lesson shows exactly the charted questions it now contains.
      for (final session in newPlan.topic('sets').sessions) {
        final expected = session.slots
            .where(
              (slot) =>
                  slot.kind == StudySlotKind.primary &&
                  charted.contains(slot.questionId),
            )
            .length;
        expect(
          summary.shelf(session.key).reflected,
          expected,
          reason: '${session.key} must not inherit old-plan progress',
        );
      }
      final total = newPlan
          .topic('sets')
          .sessions
          .fold<int>(0, (sum, s) => sum + summary.shelf(s.key).reflected);
      expect(total, charted.length);

      // 3. Records point at each question's new home lesson.
      for (final record in await repository.studyRecords()) {
        expect(
          record.shelfKey,
          newPlan.maybePrimarySlot(record.questionId)!.sessionKey,
        );
      }
    },
  );
}
