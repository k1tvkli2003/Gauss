import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/screens/map_screen.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GaussDatabase database;
  late GaussController controller;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets(
    'compact map header keeps equal flank tracks around the true center axis',
    (tester) async {
      for (final configuration in const [
        (size: Size(320, 760), textScale: 2.0, compact: true),
        (size: Size(390, 844), textScale: 1.0, compact: true),
        (size: Size(411, 891), textScale: 2.0, compact: true),
        (size: Size(800, 1280), textScale: 1.0, compact: false),
      ]) {
        await _pumpMap(
          tester,
          controller: controller,
          size: configuration.size,
          textScale: configuration.textScale,
        );

        final frameRect = tester.getRect(
          find.byKey(
            ValueKey(
              configuration.compact
                  ? 'map-compact-header-frame'
                  : 'map-wide-header-frame',
            ),
          ),
        );
        final identityRect = tester.getRect(
          find.byKey(
            ValueKey(
              configuration.compact
                  ? 'map-compact-identity-track'
                  : 'map-wide-identity-track',
            ),
          ),
        );
        final crestRect = tester.getRect(
          find.byKey(const ValueKey('map-course-progress-crest')),
        );
        final subjectRect = tester.getRect(
          find.byKey(
            ValueKey(
              configuration.compact
                  ? 'map-compact-subject-track'
                  : 'map-wide-subject-track',
            ),
          ),
        );
        final caseLabel =
            '${configuration.size} at ${configuration.textScale}x text';
        final frameAxis = frameRect.center.dx;
        final flankAxis = (identityRect.center.dx + subjectRect.center.dx) / 2;
        final leadingGap = crestRect.left - identityRect.right;
        final trailingGap = subjectRect.left - crestRect.right;

        expect(identityRect.width, subjectRect.width, reason: caseLabel);
        expect(
          identityRect.width,
          configuration.compact ? 100 : 178,
          reason: caseLabel,
        );
        expect(crestRect.center.dx, closeTo(frameAxis, .01), reason: caseLabel);
        expect(flankAxis, closeTo(frameAxis, .01), reason: caseLabel);
        expect(leadingGap, closeTo(trailingGap, .01), reason: caseLabel);
        expect(leadingGap, greaterThanOrEqualTo(4), reason: caseLabel);
        expect(tester.takeException(), isNull, reason: caseLabel);
      }
    },
  );

  testWidgets(
    'compact winding path keeps every visible label attached to its node',
    (tester) async {
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(320, 760),
        textScale: 2,
      );

      final route = find.byKey(const ValueKey('map-study-path-scroll'));
      final checkedNodes = <String>{};
      final checkedSides = <bool>{};

      void inspectVisibleLabels() {
        final pathRect = tester.getRect(route);
        final labels = find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('map-node-label-');
        });
        for (final element in labels.evaluate()) {
          final labelFinder = find.byElementPredicate(
            (candidate) => candidate == element,
          );
          final labelRect = tester.getRect(labelFinder);
          if (!pathRect.contains(labelRect.topLeft) ||
              !pathRect.contains(labelRect.bottomRight)) {
            continue;
          }
          final labelKey = (element.widget.key! as ValueKey<String>).value;
          final nodeKey = labelKey.substring('map-node-label-'.length);
          final nodeRect = tester.getRect(
            find.byKey(ValueKey('map-node-$nodeKey')),
          );
          final labelOnLeadingSide = labelRect.center.dx < nodeRect.center.dx;
          final horizontalGap = labelOnLeadingSide
              ? nodeRect.left - labelRect.right
              : labelRect.left - nodeRect.right;
          final verticalOverlap =
              math.min(labelRect.bottom, nodeRect.bottom) -
              math.max(labelRect.top, nodeRect.top);

          expect(labelRect.overlaps(nodeRect), isFalse, reason: labelKey);
          expect(
            horizontalGap,
            inInclusiveRange(0, 10),
            reason: '$labelKey must remain visibly attached to its instrument.',
          );
          expect(
            verticalOverlap,
            greaterThan(0),
            reason:
                '$labelKey must share an optical center band with its node.',
          );
          for (final text in tester.widgetList<Text>(
            find.descendant(of: labelFinder, matching: find.byType(Text)),
          )) {
            expect(text.overflow, isNot(TextOverflow.ellipsis));
          }
          checkedNodes.add(nodeKey);
          checkedSides.add(labelOnLeadingSide);
        }
      }

      inspectVisibleLabels();
      await tester.drag(route, const Offset(0, -360));
      await tester.pump();
      inspectVisibleLabels();

      expect(
        checkedNodes.length,
        greaterThanOrEqualTo(2),
        reason: 'The compact stress pass must prove multiple path pairings.',
      );
      expect(
        checkedSides,
        hasLength(2),
        reason: 'The compact stress pass must cover labels on both path sides.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '200 percent chapter gate reserves space before its first lesson node',
    (tester) async {
      await controller.selectTopic('patterns_sequences');
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(320, 760),
        textScale: 2,
      );

      final gate = find.byKey(const ValueKey('map-section-gate-2'));
      final firstLesson = find.byKey(
        const ValueKey('map-node-patterns_sequences:0:5'),
      );
      expect(gate, findsOneWidget);
      expect(firstLesson, findsOneWidget);
      final gateRect = tester.getRect(gate);
      final lessonRect = tester.getRect(firstLesson);
      expect(
        gateRect.overlaps(lessonRect),
        isFalse,
        reason: 'gate=$gateRect lesson=$lessonRect',
      );
      expect(
        lessonRect.top - gateRect.bottom,
        greaterThanOrEqualTo(12),
        reason:
            'The route geometry must reserve the complete live chapter gate '
            'before positioning the next five-question instrument. '
            'gate=$gateRect lesson=$lessonRect',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required GaussController controller,
  required Size size,
  required double textScale,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: GaussScope(
        controller: controller,
        child: const Scaffold(body: MapScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
