import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/question_certification.dart';

void main() {
  test('topic hints resolve questions without scanning the library', () async {
    final repository = QuestionBankRepository();
    await repository.initialize();
    final lastTopic = repository.topics.last;
    final firstTopic = repository.topics.first;
    final lastQuestion = (await repository.loadTopic(lastTopic.key)).last;
    final firstQuestion = (await repository.loadTopic(firstTopic.key)).first;

    final hinted = QuestionBankRepository();
    await hinted.initialize();
    final resolved = await hinted.questionsByIds(
      [lastQuestion.id, firstQuestion.id],
      topicByQuestionId: {
        lastQuestion.id: lastTopic.key,
        firstQuestion.id: firstTopic.key,
      },
    );

    // Order follows the requested ids, and only the two hinted shards were
    // opened — the other topics stay untouched.
    expect(resolved.map((question) => question.id), [
      lastQuestion.id,
      firstQuestion.id,
    ]);
    for (final topic in hinted.topics) {
      if (topic.key == lastTopic.key || topic.key == firstTopic.key) continue;
      expect(
        hinted.isTopicLoaded(topic.key),
        isFalse,
        reason: '${topic.key} should not have been decoded',
      );
    }
  });

  test('a stale topic hint still resolves through the full scan', () async {
    final repository = QuestionBankRepository();
    await repository.initialize();
    final topic = repository.topics.last;
    final question = (await repository.loadTopic(topic.key)).first;

    final stale = QuestionBankRepository();
    await stale.initialize();
    final resolved = await stale.questionsByIds(
      [question.id],
      topicByQuestionId: {question.id: 'a_topic_that_no_longer_exists'},
    );

    expect(resolved.single.id, question.id);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('answer index boundary', () {
    for (var sourceAnswer = 1; sourceAnswer <= 4; sourceAnswer++) {
      test(
        'maps source answer $sourceAnswer to choice ${sourceAnswer - 1}',
        () {
          final question = Question.fromJson({
            'id': 'contract_$sourceAnswer',
            'subject': 'math',
            'topic_key': 'sets',
            'difficulty': 'hard',
            'stem': [
              {'type': 'text', 'text': 'Question'},
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
            'correct_option_index': sourceAnswer,
            'solution': <Map<String, String>>[],
            'smart_shortcut': null,
            'source_bank': 'verified_fixture',
          });

          expect(question.sourceCorrectOptionIndex, sourceAnswer);
          expect(question.correctChoiceIndex, sourceAnswer - 1);
          expect(question.trust, QuestionTrust.missionReady);
          expect(question.solutionVerified, isTrue);
        },
      );
    }

    test('quarantines unverified source items without deleting them', () {
      final question = Question.fromJson({
        'id': 'source_mapping_unverified',
        'subject': 'math',
        'topic_key': 'sets',
        'difficulty': 'hard',
        'stem': [
          {'type': 'text', 'text': 'Question'},
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
        'correct_option_index': 4,
        'solution': [
          {'type': 'text', 'text': 'Preserved source explanation'},
        ],
        'smart_shortcut': null,
        'source_bank': 'nardebam',
        'provenance': {'kind': 'source', 'solution_origin': 'source'},
      });

      expect(question.trust, QuestionTrust.preservedArchive);
      expect(question.trust.canScore, isFalse);
      expect(question.solutionVerified, isFalse);
      expect(question.solution, hasLength(1));
      expect(
        (question.solution.single as TextBlock).text,
        contains('Preserved'),
      );
    });

    test('withholds a mission-ready explanation that names another answer', () {
      final question = Question.fromJson({
        'id': 'conflicting_explanation',
        'subject': 'math',
        'topic_key': 'sets',
        'difficulty': 'hard',
        'stem': [
          {'type': 'text', 'text': 'Question'},
        ],
        'options': [
          for (final value in ['A', 'B', 'C', 'D'])
            [
              {'type': 'text', 'text': value},
            ],
        ],
        'correct_option_index': 1,
        'solution': [
          {'type': 'text', 'text': 'گزینه ۲ صحیح است.'},
        ],
        'smart_shortcut': null,
        'source_bank': 'verified_fixture',
      });

      expect(question.missionReady, isTrue);
      expect(question.solutionVerified, isFalse);
      expect(question.solution, isNotEmpty);
    });

    test('rejects an invalid source answer before it enters the UI', () {
      expect(
        () => Question.fromJson({
          'id': 'invalid',
          'subject': 'math',
          'topic_key': 'sets',
          'difficulty': 'hard',
          'stem': <Map<String, String>>[],
          'options': [
            <Map<String, String>>[],
            <Map<String, String>>[],
            <Map<String, String>>[],
            <Map<String, String>>[],
          ],
          'correct_option_index': 0,
          'solution': <Map<String, String>>[],
          'source_bank': 'nardebam',
        }),
        throwsFormatException,
      );
    });
  });

  test(
    'all 3,672 source rows stay preserved and are privately usable',
    () async {
      final repository = QuestionBankRepository();
      await repository.initialize();
      await repository.validateAllShards();
      final questions = <Question>[
        for (final topic in repository.topics)
          ...await repository.loadTopic(topic.key),
      ];
      final pendingScientificReview = questions
          .where((question) => question.trust == QuestionTrust.preservedArchive)
          .toList(growable: false);
      expect(repository.declaredTotal, 3672);
      expect(repository.topics, hasLength(29));
      expect(
        repository.topics.fold<int>(
          0,
          (total, topic) => total + topic.missionReadyCount,
        ),
        51,
      );
      expect(questions, hasLength(3672));
      expect(pendingScientificReview, hasLength(3621));
      expect(
        questions.every((question) => question.sourceBank == 'nardebam'),
        isTrue,
      );
      final missionReady = questions
          .where((question) => question.missionReady)
          .toList(growable: false);
      expect(missionReady, hasLength(51));
      expect(
        missionReady.map((question) => question.id).toSet(),
        repository.certificationRuntime.questionsById.keys.toSet(),
      );
      expect(
        missionReady.every(
          (question) =>
              question.certification != null &&
              question.effectiveCorrectOptionIndex ==
                  question.certification!.effectiveOptionIndex,
        ),
        isTrue,
      );
      final repaired70 = missionReady.firstWhere(
        (question) => question.id == 'nardebam_math_1405_0070',
      );
      expect(
        RegExp(
          RegExp.escape(r't_7 = t_1 + 6d = 0'),
        ).allMatches(repaired70.solution.whereType<TextBlock>().single.text),
        hasLength(1),
      );
      final repaired85 = missionReady.firstWhere(
        (question) => question.id == 'nardebam_math_1405_0085',
      );
      expect(
        repaired85.options
            .map((option) => (option.single as TextBlock).text)
            .toList(),
        const [
          r'$\frac{9}{16}$',
          r'$-\frac{9}{16}$',
          r'$\frac{27}{64}$',
          r'$-\frac{27}{64}$',
        ],
      );
      expect(repaired85.sourceCorrectOptionIndex, 4);
      expect(repaired85.effectiveCorrectOptionIndex, 4);
      expect(repaired85.correctChoiceIndex, 3);
      final repaired69 = missionReady.firstWhere(
        (question) => question.id == 'nardebam_math_1405_0069',
      );
      expect(repaired69.sourceCorrectOptionIndex, 2);
      expect(repaired69.effectiveCorrectOptionIndex, 2);
      expect(
        repaired69.solution.whereType<TextBlock>().single.text,
        contains(r'5d=20'),
      );
      final repaired80 = missionReady.firstWhere(
        (question) => question.id == 'nardebam_math_1405_0080',
      );
      expect(repaired80.sourceCorrectOptionIndex, 1);
      expect(repaired80.effectiveCorrectOptionIndex, 1);
      expect(
        repaired80.stem.whereType<TextBlock>().single.text,
        contains(r'6, a, a-\dfrac{3}{2}'),
      );
      final rechecked88 = missionReady.firstWhere(
        (question) => question.id == 'nardebam_math_1405_0088',
      );
      expect(rechecked88.sourceCorrectOptionIndex, 1);
      expect(rechecked88.effectiveCorrectOptionIndex, 1);
      expect(
        rechecked88.certification!.sourceFidelityReceiptId,
        'source-fidelity-math-0003:nardebam_math_1405_0088',
      );
      expect(
        rechecked88.certification!.subtopicKey,
        'patterns_sequences_geometric',
      );
      expect(
        pendingScientificReview.every(
          (question) => question.solution.isNotEmpty,
        ),
        isTrue,
      );
      expect(questions.every((question) => question.runtimeUsable), isTrue);
      expect(
        questions.where((question) => question.solutionVerified),
        hasLength(51),
      );
      final defaultMission = await repository.createMission('sets', count: 50);
      expect(defaultMission, hasLength(50));
      expect(
        defaultMission.every((question) => question.runtimeUsable),
        isTrue,
      );

      // A mixed five-question micro-lesson must retain both certified and
      // archive items; certification may change trust, never source coverage.
      final firstStudySession = await repository.loadStudySession(
        'sets',
        offset: 0,
      );
      expect(firstStudySession, hasLength(5));
      expect(
        firstStudySession.map((question) => question.id),
        repository.studySession('sets', 0).slots.map((slot) => slot.questionId),
      );

      expect(
        repository.isStudySessionMissionReady('patterns_sequences', offset: 0),
        isFalse,
      );
      for (final offset in [0, 20, 30]) {
        expect(
          repository.isStudySessionPlayable(
            'patterns_sequences',
            offset: offset,
          ),
          isTrue,
        );
        if (offset != 0) {
          expect(
            repository.isStudySessionMissionReady(
              'patterns_sequences',
              offset: offset,
            ),
            isTrue,
          );
        }
        final planned = repository.studySession('patterns_sequences', offset);
        final scored = await repository.createStudySessionMission(
          'patterns_sequences',
          offset: offset,
        );
        expect(scored, hasLength(5));
        expect(
          scored.map((question) => question.id),
          planned.slots.map((slot) => slot.questionId),
        );
        expect(scored.every((question) => question.runtimeUsable), isTrue);
      }
    },
  );

  test('a stale source row cannot reuse a valid certification', () {
    final runtime = CertifiedQuestionRuntime.fromJson(
      jsonDecode(
            File(
              'assets/curriculum/certified_question_runtime_v1.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final certification = runtime.questionsById['nardebam_math_1405_0004']!;
    final rows =
        jsonDecode(
              File(
                'assets/question_bank/topics/math_sets.json',
              ).readAsStringSync(),
            )
            as List<dynamic>;
    final source = Map<String, dynamic>.of(
      rows.cast<Map<String, dynamic>>().firstWhere(
        (row) => row['id'] == certification.questionId,
      ),
    );
    final stem = List<dynamic>.of(source['stem'] as List<dynamic>);
    stem[0] = <String, dynamic>{'type': 'text', 'text': 'tampered'};
    source['stem'] = stem;

    expect(() => certification.bindAndApply(source), throwsFormatException);
  });

  test('all 3,410 source media files remain byte-for-byte present', () {
    final media = Directory('assets/question_media')
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList(growable: false);
    expect(media, hasLength(3410));
    expect(
      media.fold<int>(0, (total, file) => total + file.lengthSync()),
      66450076,
    );
  });
}
