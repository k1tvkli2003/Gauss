// This compatibility test intentionally targets the parser used internally by
// flutter_math_fork. Keeping the import test-only lets production code stay on
// the package's public API while the complete bundled corpus is parse-gated.
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_fork/src/parser/tex/parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/widgets/content_blocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'mixed Persian and TeX parsing preserves prose and repairs one line',
    () {
      const source =
          'اگر \$x^۲+۱=۰\$ باشد، مقدار را بیابید.\n'
          r'سطر ناقص: $\fracrac{۱}{۲}+\timesimes ۳';

      final segments = parseMathContent(source);

      expect(
        segments
            .where((segment) => !segment.isMath)
            .map((segment) => segment.value)
            .join(),
        contains('اگر '),
      );
      expect(
        segments
            .where((segment) => !segment.isMath)
            .map((segment) => segment.value)
            .join(),
        contains('سطر ناقص: '),
      );
      expect(
        segments
            .where((segment) => segment.isMath)
            .map((segment) => segment.value),
        containsAll(<String>[r'x^2+1=0', r'\frac{1}{2}+\times 3']),
      );
    },
  );

  test('TeX normalization is view-only and deterministic', () {
    const source = r'\fracrac{۱۲}{٣} \timesimes ۲ − ۱٪';
    expect(normalizeMathTex(source), r'\frac{12}{3} \times 2 - 1\%');
    expect(source, r'\fracrac{۱۲}{٣} \timesimes ۲ − ۱٪');
  });

  test(
    'every bundled question TeX segment parses without source mutation',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();

      var questionCount = 0;
      var textBlockCount = 0;
      var formulaCount = 0;
      final failures = <String>[];

      for (final topic in bank.topics) {
        for (final question in await bank.loadTopic(topic.key)) {
          questionCount++;
          final blocks = <ContentBlock>[
            ...question.stem,
            for (final option in question.options) ...option,
            ...question.solution,
            ...?question.shortcut,
          ];
          for (final block in blocks.whereType<TextBlock>()) {
            textBlockCount++;
            final original = block.text;
            for (final segment in parseMathContent(original)) {
              if (!segment.isMath) continue;
              formulaCount++;
              try {
                TexParser(
                  segment.value,
                  TexParserSettings(displayMode: segment.display),
                ).parse();
              } catch (error) {
                if (failures.length < 80) {
                  failures.add(
                    '${question.id}: `${segment.value}` (${segment.source}) => $error',
                  );
                }
              }
            }
            expect(
              block.text,
              original,
              reason: '${question.id} source text must remain immutable',
            );
          }
        }
      }

      expect(questionCount, 3672);
      expect(textBlockCount, 22032);
      expect(formulaCount, greaterThan(37000));
      expect(
        failures,
        isEmpty,
        reason:
            'flutter_math_fork rejected ${failures.length} captured formulas:\n'
            '${failures.join('\n')}',
      );
    },
  );

  testWidgets(
    'Persian prose and inline/display math render at phone width and 200% text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(2),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ContentBlocksView(
                  blocks: [
                    TextBlock(
                      'عبارت \$x^۲+۲x+۱\$ را ساده کنید.\n'
                      r'$$\frac{۱}{۲}+\sqrt{۹}=۳٫۵$$',
                    ),
                    TextBlock('پاسخ: گزینهٔ دوم، زیرا مربع کامل است.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Math), findsNWidgets(2));
      expect(find.textContaining('عبارت '), findsOneWidget);
      expect(find.textContaining('پاسخ:'), findsOneWidget);
      final inline = tester.getRect(
        find.byKey(const ValueKey('inline-math-1')),
      );
      final display = tester.getRect(
        find.byKey(const ValueKey('display-math-3')),
      );
      expect(
        display.top,
        greaterThan(inline.bottom),
        reason: r'$$...$$ must occupy a separate full-width row',
      );
      expect(display.width, greaterThan(280));
      expect(tester.takeException(), isNull);
    },
  );
}
