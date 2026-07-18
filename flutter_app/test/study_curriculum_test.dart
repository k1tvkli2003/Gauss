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
    'mini-nodes cover all 3672 questions once without oversized sets',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();
      final keys = <String>{};
      var covered = 0;

      for (final section in GaussStudyCurriculum.sections) {
        final nodes = GaussStudyCurriculum.nodesFor(section, bank.topics);
        expect(nodes, isNotEmpty);
        for (final node in nodes) {
          expect(keys.add(node.key), isTrue, reason: node.key);
          expect(node.questionCount, inInclusiveRange(1, 20));
          covered += node.questionCount;
        }
      }

      expect(covered, bank.declaredTotal);
      expect(keys.length, greaterThan(180));
    },
  );
}
