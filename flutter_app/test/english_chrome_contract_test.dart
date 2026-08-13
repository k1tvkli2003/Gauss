import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/learning_content_policy.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production source reserves Persian literals for parsing policy only',
    () {
      final persian = RegExp(r'[\u0600-\u06ff]');
      final allowed = <String, List<RegExp>>{
        'lib/domain/learning_content_policy.dart': <RegExp>[
          RegExp(r"^\s*'[۰-۹٠-٩٫٬٪]': '[0-9.,%]',\s*$"),
        ],
        'lib/domain/models.dart': <RegExp>[
          RegExp(r"^\s*r'\(\?:گزینه\|option\)\\s\*\(\[1-4\]\)',\s*$"),
        ],
        'lib/widgets/content_blocks.dart': <RegExp>[
          RegExp(r"RegExp\(r'\[\\u0600-\\u06ff\]'\)"),
        ],
      };
      final violations = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll('\\', '/');
        final exceptions = allowed[path] ?? const <RegExp>[];
        final lines = entity.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          if (!persian.hasMatch(line)) continue;
          if (exceptions.any((pattern) => pattern.hasMatch(line))) continue;
          violations.add('$path:${index + 1}: ${line.trim()}');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'App chrome must stay English. Persian source literals are allowed '
            'only in the narrow learning-content parser policy:\n'
            '${violations.join('\n')}',
      );
    },
  );

  test('all model-owned chrome labels are English', () {
    final persian = RegExp(r'[\u0600-\u06ff]');
    expect(
      Subject.values.map((value) => value.label).join(),
      isNot(contains(persian)),
    );
    expect(
      Difficulty.values.map((value) => value.label).join(),
      isNot(contains(persian)),
    );
  });

  test('learning numeral policy emits only ASCII separators and digits', () {
    const source = 'سؤال ۰۱۲۳۴۵۶۷۸۹؛ ٠١٢٣٤٥٦٧٨٩؛ ۴۵٫۶؛ ۱٬۰۰۰؛ ۹٪';
    final normalized = normalizeLearningDigits(source);
    expect(normalized, 'سؤال 0123456789؛ 0123456789؛ 45.6؛ 1,000؛ 9%');
    expect(normalized, isNot(contains(RegExp(r'[۰-۹٠-٩٫٬٪]'))));
    expect(source, 'سؤال ۰۱۲۳۴۵۶۷۸۹؛ ٠١٢٣٤٥٦٧٨٩؛ ۴۵٫۶؛ ۱٬۰۰۰؛ ۹٪');
  });

  test('every live learning text and media description normalizes cleanly', () {
    final index =
        jsonDecode(File('assets/question_bank/index.json').readAsStringSync())
            as Map<String, dynamic>;
    final forbidden = RegExp(r'[۰-۹٠-٩٫٬٪]');
    var questions = 0;
    var strings = 0;

    for (final rawTopic in index['topics'] as List<dynamic>) {
      final topic = rawTopic as Map<String, dynamic>;
      final rows =
          jsonDecode(File('assets/${topic['file']}').readAsStringSync())
              as List<dynamic>;
      for (final rawRow in rows) {
        questions++;
        final row = rawRow as Map<String, dynamic>;
        final blocks = <dynamic>[
          ...row['stem'] as List<dynamic>,
          for (final option in row['options'] as List<dynamic>)
            ...option as List<dynamic>,
          ...row['solution'] as List<dynamic>,
          ...?(row['smart_shortcut'] as List<dynamic>?),
        ];
        for (final rawBlock in blocks) {
          final block = rawBlock as Map<String, dynamic>;
          final value = switch (block['type']) {
            'image' => (block['alt'] as String?) ?? '',
            _ => (block['text'] as String?) ?? '',
          };
          strings++;
          expect(
            normalizeLearningDigits(value),
            isNot(contains(forbidden)),
            reason: '${row['id']} leaves a non-ASCII numeral at render time',
          );
        }
      }
    }

    expect(questions, 3672);
    expect(strings, greaterThan(22000));
  });

  testWidgets('app chrome remains English LTR under a Persian device locale', (
    tester,
  ) async {
    final database = GaussDatabase(NativeDatabase.memory());
    final controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    addTearDown(() async {
      controller.dispose();
      await database.close();
    });
    await tester.binding.setSurfaceSize(const Size(411, 891));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.localeTestValue = const Locale('fa');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.runAsync(controller.initialize);
    if (controller.needsTour) await controller.markTourSeen();
    await tester.pumpWidget(GaussApp(controller: controller));
    await tester.pump();

    final appContext = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(appContext), const Locale('en'));
    expect(Directionality.of(appContext), TextDirection.ltr);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
