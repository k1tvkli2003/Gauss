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
    'source-bound repairs remain complete and render at 320dp with 200% text',
    (tester) async {
      final receipts =
          File('../data/certification/v1/source-repair-receipts.jsonl')
              .readAsLinesSync()
              .where((line) => line.trim().isNotEmpty)
              .map((line) => jsonDecode(line) as Map<String, dynamic>)
              .toList(growable: false);
      final sourceRows =
          (jsonDecode(
                    File(
                      'assets/question_bank/topics/math_patterns_sequences.json',
                    ).readAsStringSync(),
                  )
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();

      expect(receipts, hasLength(4));
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final receipt in receipts) {
        final id = receipt['question_id'] as String;
        final source = sourceRows.firstWhere((row) => row['id'] == id);
        expect(canonicalJsonSha256(source), receipt['runtime_record_sha256']);
        final effective = Map<String, dynamic>.of(source)
          ..addAll(receipt['content_patch'] as Map<String, dynamic>);
        expect(
          canonicalJsonSha256(effective),
          receipt['effective_record_sha256'],
        );
        final question = Question.fromJson(effective);

        if (id.endsWith('0070')) {
          final solutionText = question.solution
              .whereType<TextBlock>()
              .map((block) => block.text)
              .join('\n');
          expect(
            RegExp(
              RegExp.escape(r't_7 = t_1 + 6d = 0'),
            ).allMatches(solutionText),
            hasLength(1),
          );
        }
        if (id.endsWith('0069')) {
          final solutionText = question.solution
              .whereType<TextBlock>()
              .map((block) => block.text)
              .join('\n');
          expect(solutionText, contains(r'(a+d)(a-3d)=0'));
          expect(solutionText, contains(r'5d=20'));
          expect(solutionText, contains('روش دوم'));
          expect(question.correctChoiceIndex, 1);
        }
        if (id.endsWith('0080')) {
          final stemText = question.stem
              .whereType<TextBlock>()
              .map((block) => block.text)
              .join('\n');
          expect(stemText, contains(r'a-\dfrac{3}{2}'));
          expect(stemText, contains(r'6, a, a-'));
          expect(stemText, isNot(contains(r'$-\dfrac{3}{2}')));
          expect(question.correctChoiceIndex, 0);
        }
        if (id.endsWith('0085')) {
          expect(
            question.options
                .map((option) => (option.single as TextBlock).text)
                .toList(),
            const [
              r'$\frac{9}{16}$',
              r'$-\frac{9}{16}$',
              r'$\frac{27}{64}$',
              r'$-\frac{27}{64}$',
            ],
          );
          expect(question.correctChoiceIndex, 3);
        }

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
        expect(tester.takeException(), isNull, reason: id);
      }
    },
  );
}
