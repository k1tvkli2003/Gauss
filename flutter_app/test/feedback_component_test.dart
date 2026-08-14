import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/feedback/feedback_capture.dart';
import 'package:gauss/feedback/feedback_controller.dart';
import 'package:gauss/feedback/feedback_models.dart';
import 'package:gauss/feedback/feedback_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GaussDatabase database;
  late GaussFeedbackRepository repository;
  late GaussFeedbackController controller;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    repository = GaussFeedbackRepository(database);
    controller = GaussFeedbackController(
      repository,
      clock: () => DateTime.utc(2026, 8, 14, 10, 30),
      random: Random(7),
    );
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  test('redactor removes credentials before persisted feedback', () async {
    await controller.addEntry(
      route: '/map?token=not-a-real-token-123',
      note: 'Authorization: Bearer not-a-real-token-123',
      kind: GaussFeedbackKind.error,
    );

    final entry = controller.entries.single;
    expect(entry.route, contains('[REDACTED]'));
    expect(entry.note, contains('[REDACTED]'));
    expect(entry.route, isNot(contains('not-a-real-token-123')));
    expect(entry.note, isNot(contains('not-a-real-token-123')));
    expect(entry.syncState, GaussFeedbackSyncState.pending);
  });

  test('outbox rejects incomplete or corrupt screenshot bytes', () async {
    expect(
      () => controller.addEntry(
        route: '/map',
        note: 'broken image',
        kind: GaussFeedbackKind.error,
        screenshot: GaussFeedbackScreenshot(
          bytes: Uint8List.fromList([137, 80, 78, 71]),
          pixelRatio: 1,
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  testWidgets('question source namespaces never leak into feedback chrome', (
    tester,
  ) async {
    await controller.repository.addQuestionIssue(
      QuestionIssueReport(
        questionId: 'private_source_math_1405_0057',
        topicKey: 'sets',
        kind: QuestionIssueKind.questionText,
        note: 'Check the wording.',
        sessionId: 'test-session',
        missionIndex: 0,
        selectedChoiceIndex: null,
        reportedAt: DateTime.utc(2026, 8, 14),
      ),
    );
    await controller.refresh();
    await tester.pumpWidget(_FeedbackHarness(controller: controller));
    GaussFeedbackEntriesSheet.show(
      tester.element(find.text('MAP SURFACE')),
      controller,
    );
    await tester.pumpAndSettle();

    expect(find.text('Question 1405-0057'), findsOneWidget);
    expect(find.textContaining('private_source'), findsNothing);
  });

  test(
    'schema seven migrates additively and preserves existing progress',
    () async {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'gauss_feedback_migration_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      final old = _SchemaSevenDatabase(NativeDatabase(file));
      await old.customStatement(
        'CREATE TABLE app_flags ('
        '"key" TEXT NOT NULL PRIMARY KEY, '
        '"value" TEXT NOT NULL, '
        '"updated_at" INTEGER NOT NULL)',
      );
      await old.customStatement(
        "INSERT INTO app_flags (key, value, updated_at) "
        "VALUES ('tour_seen', 'true', 7)",
      );
      await old.customStatement('PRAGMA user_version = 7');
      await old.close();
      drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );

      final migrated = GaussDatabase(NativeDatabase(file));
      final flag = await (migrated.select(
        migrated.appFlags,
      )..where((row) => row.key.equals('tour_seen'))).getSingle();
      expect(flag.value, 'true');
      expect(
        await migrated.select(migrated.feedbackOutboxEntries).get(),
        isEmpty,
      );
      await migrated.close();
    },
  );

  testWidgets(
    'capture stays hidden until enabled and preview precedes private save',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var cleanCaptureFrameObserved = false;
      await tester.pumpWidget(
        _FeedbackHarness(
          controller: controller,
          screenshotProvider: () async {
            expect(
              find.byKey(const ValueKey('feedback-capture-menu')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey('feedback-capture-action')),
              findsNothing,
            );
            cleanCaptureFrameObserved = true;
            return GaussFeedbackScreenshot(bytes: _onePixelPng, pixelRatio: 1);
          },
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('feedback-capture-action')),
        findsNothing,
      );

      await controller.setEnabled(true);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('feedback-capture-action')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('feedback-capture-action')))
            .shortestSide,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.byKey(const ValueKey('feedback-capture-action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('feedback-capture-menu')),
        findsOneWidget,
      );
      expect(find.textContaining('Nothing is shared'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('feedback-screenshot-action')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('feedback-screenshot-preview')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Screenshot pixels are stored exactly as shown'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('feedback-save-action')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('feedback-note-field')),
        'The route header overlaps the first node.',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('feedback-save-action')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('feedback-save-action')));
      await tester.pumpAndSettle();

      expect(controller.entries, hasLength(1));
      expect(controller.entries.single.hasScreenshot, isTrue);
      expect(cleanCaptureFrameObserved, isTrue);
      expect(
        find.text('Private feedback saved to the outbox.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('feedback sheets reflow at 320dp and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.setEnabled(true);
    await tester.pumpWidget(
      _FeedbackHarness(controller: controller, textScale: 2),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('feedback-capture-action')));
    await tester.pumpAndSettle();
    expect(find.text('Mark what needs attention'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feedback-capture-menu')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.overflow == TextOverflow.ellipsis,
        ),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('private export stays bounded on a landscape tablet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.addEntry(
      route: '/insights',
      note: 'Tablet export layout proof.',
      kind: GaussFeedbackKind.note,
    );
    await tester.pumpWidget(_FeedbackHarness(controller: controller));
    GaussFeedbackEntriesSheet.show(
      tester.element(find.text('MAP SURFACE')),
      controller,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('feedback-export-action')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('feedback-export-dialog'));
    expect(dialog, findsOneWidget);
    expect(tester.getRect(dialog).width, lessThanOrEqualTo(640));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('feedback-confirm-export')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('Android opens Save — never Share.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('private export warning remains reachable at 320dp and 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.addEntry(
      route: '/insights',
      note: 'Accessible export proof.',
      kind: GaussFeedbackKind.note,
    );
    await tester.pumpWidget(
      _FeedbackHarness(controller: controller, textScale: 2),
    );
    GaussFeedbackEntriesSheet.show(
      tester.element(find.text('MAP SURFACE')),
      controller,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('feedback-export-action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feedback-export-action')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('feedback-export-dialog'));
    expect(dialog, findsOneWidget);
    expect(tester.getRect(dialog).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(dialog).right, lessThanOrEqualTo(320));
    await tester.ensureVisible(find.text('Android opens Save — never Share.'));
    await tester.pumpAndSettle();
    expect(find.text('Android opens Save — never Share.'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('feedback-confirm-export')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  for (final tabletSize in const <Size>[Size(800, 1280), Size(1280, 800)]) {
    testWidgets('feedback owns a bounded readable composition at '
        '${tabletSize.width.toInt()}x${tabletSize.height.toInt()}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(tabletSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await controller.setEnabled(true);
      await tester.pumpWidget(_FeedbackHarness(controller: controller));
      await tester.pump();

      final lens = find.byKey(const ValueKey('feedback-capture-action'));
      expect(tester.getSize(lens), const Size.square(52));
      expect(
        tester.getRect(lens).right,
        lessThanOrEqualTo(tabletSize.width - 8),
      );
      await tester.tap(lens);
      await tester.pumpAndSettle();

      final sheet = find.byKey(const ValueKey('feedback-capture-menu'));
      expect(sheet, findsOneWidget);
      final rect = tester.getRect(
        find.byKey(const ValueKey('feedback-sheet-surface')),
      );
      expect(rect.width, lessThanOrEqualTo(640));
      expect(rect.height, lessThanOrEqualTo(tabletSize.height * .88));
      expect(rect.bottom, lessThanOrEqualTo(tabletSize.height));
      for (final key in const [
        'feedback-screenshot-action',
        'feedback-note-action',
        'feedback-review-action',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
        expect(
          tester.getSize(find.byKey(ValueKey(key))).height,
          greaterThanOrEqualTo(70),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _SchemaSevenDatabase extends drift.GeneratedDatabase {
  _SchemaSevenDatabase(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables => const [];
}

class _FeedbackHarness extends StatelessWidget {
  _FeedbackHarness({
    required this.controller,
    this.textScale = 1,
    this.screenshotProvider,
  });

  final GaussFeedbackController controller;
  final double textScale;
  final GaussFeedbackScreenshotProvider? screenshotProvider;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    theme: buildGaussTheme(),
    builder: (context, child) => GaussFeedbackCapture(
      controller: controller,
      routeName: () => '/map',
      navigatorKey: navigatorKey,
      screenshotProvider:
          screenshotProvider ??
          () async =>
              GaussFeedbackScreenshot(bytes: _onePixelPng, pixelRatio: 1),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
    ),
    home: const Scaffold(body: Center(child: Text('MAP SURFACE'))),
  );
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
