import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';

void main() {
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
    'all 3,672 bundled source questions satisfy the typed contract',
    () async {
      final repository = QuestionBankRepository();
      await repository.initialize();
      await repository.validateAllShards();
      final questions = <Question>[
        for (final topic in repository.topics)
          ...await repository.loadTopic(topic.key),
      ];
      final quarantined = questions
          .where((question) => question.trust == QuestionTrust.preservedArchive)
          .toList(growable: false);
      expect(repository.declaredTotal, 3672);
      expect(repository.topics, hasLength(29));
      expect(
        repository.topics.fold<int>(
          0,
          (total, topic) => total + topic.missionReadyCount,
        ),
        0,
      );
      expect(questions, hasLength(3672));
      expect(quarantined, hasLength(3672));
      expect(
        questions.every((question) => question.sourceBank == 'nardebam'),
        isTrue,
      );
      expect(questions.where((question) => question.missionReady), isEmpty);
      expect(
        quarantined.every((question) => question.solution.isNotEmpty),
        isTrue,
      );
      expect(questions.where((question) => question.solutionVerified), isEmpty);
      final defaultMission = await repository.createMission('sets', count: 50);
      expect(defaultMission, isEmpty);
    },
  );

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
