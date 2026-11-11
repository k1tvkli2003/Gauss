// Every shipped source question must be reachable through a Map lesson.
// Guards against any chapter, topic or question silently dropping out of
// the study route.
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every source question is reachable through the Map route', () async {
    final bank = QuestionBankRepository();
    await bank.initialize();

    final reachable = <String>{};
    final perSection = <String, ({int lessons, Set<String> ids})>{};
    for (final section in GaussStudyCurriculum.sections) {
      final nodes = GaussStudyCurriculum.nodesFor(section, bank.topics);
      final ids = <String>{};
      for (final node in nodes) {
        final lesson = await bank.createStudySessionMission(
          node.topic.key,
          offset: node.offset,
        );
        ids.addAll(lesson.map((question) => question.id));
      }
      perSection[section.id] = (lessons: nodes.length, ids: ids);
      reachable.addAll(ids);
    }

    final topicsOnRoute = {
      for (final section in GaussStudyCurriculum.sections)
        ...GaussStudyCurriculum.nodesFor(
          section,
          bank.topics,
        ).map((node) => node.topic.key),
    };
    final everyKey = bank.topics.map((topic) => topic.key).toSet();
    final bySubject = <Subject, int>{};
    for (final topic in bank.topics) {
      bySubject[topic.subject] =
          (bySubject[topic.subject] ?? 0) + topic.questionCount;
    }

    // ignore: avoid_print
    print(
      'REACH lessons=${perSection.values.fold<int>(0, (a, s) => a + s.lessons)} '
      'questions=${reachable.length} topics=${topicsOnRoute.length}/${everyKey.length} '
      'bySubject=$bySubject',
    );
    for (final entry in perSection.entries) {
      // ignore: avoid_print
      print(
        'REACH ${entry.key}: ${entry.value.lessons} lessons, '
        '${entry.value.ids.length} questions',
      );
    }

    expect(topicsOnRoute, everyKey, reason: 'every topic is on the route');
    expect(
      reachable.length,
      3672,
      reason: 'every source question is reachable',
    );
  });
}
