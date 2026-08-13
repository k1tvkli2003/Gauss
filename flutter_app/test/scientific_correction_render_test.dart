import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/question_certification.dart';
import 'package:gauss/widgets/content_blocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'scientific correction 0093 binds the answer and renders at 320dp 200%',
    (tester) async {
      final receipt =
          File('../data/certification/v1/scientific-correction-receipts.jsonl')
              .readAsLinesSync()
              .where((line) => line.trim().isNotEmpty)
              .map((line) => jsonDecode(line) as Map<String, dynamic>)
              .single;
      final sourceRows =
          (jsonDecode(
                    File(
                      'assets/question_bank/topics/math_patterns_sequences.json',
                    ).readAsStringSync(),
                  )
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final source = sourceRows.singleWhere(
        (row) => row['id'] == 'nardebam_math_1405_0093',
      );
      final classification = receipt['classification'] as Map<String, dynamic>;
      final mapping = receipt['answer_mapping'] as Map<String, dynamic>;
      final certification = QuestionCertification.fromJson({
        'question_id': receipt['question_id'],
        'subject': source['subject'],
        'topic_key': source['topic_key'],
        'section_id': classification['section_id'],
        'subtopic_key': classification['subtopic_key'],
        'concept_tags': classification['concept_tags'],
        'prerequisites': classification['prerequisites'],
        'reviewed_difficulty': source['difficulty'],
        'source_sha256': receipt['source_sha256'],
        'runtime_record_sha256': receipt['runtime_record_sha256'],
        'effective_record_sha256': receipt['effective_record_sha256'],
        'source_option_index': mapping['immutable_source_option'],
        'effective_option_index': mapping['effective_option'],
        'solution_verified': true,
        'render_receipt_id': 'flutter-render-v1-20260810',
        'source_fidelity_receipt_id': receipt['receipt_id'],
        'content_patch': receipt['content_patch'],
      });
      final effective = certification.bindAndApply(source);
      final question = Question.fromJson(
        effective,
        certification: certification,
      );

      expect(question.sourceCorrectOptionIndex, 2);
      expect(question.effectiveCorrectOptionIndex, 4);
      expect(question.correctChoiceIndex, 3);
      expect(question.solutionVerified, isTrue);
      final solutionText = question.solution
          .whereType<TextBlock>()
          .map((block) => block.text)
          .join('\n');
      expect(solutionText, contains(r'a\ne 3'));
      expect(solutionText, contains(r'6-a-b\ne 0'));
      expect(solutionText, contains(r'\frac{1}{6}'));
      expect(
        RegExp(
          r'[\u06f0-\u06f9\u0660-\u0669]',
        ).hasMatch(normalizeLearningDigits(solutionText)),
        isFalse,
      );

      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ContentBlocksView(blocks: question.stem),
                    for (final option in question.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ContentBlocksView(blocks: option),
                      ),
                    ContentBlocksView(blocks: question.solution),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
