import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  testWidgets('a chapter expands into its units and a unit opens a lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final database = GaussDatabase(NativeDatabase.memory());
    final controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    await tester.runAsync(controller.initialize);
    await tester.runAsync(controller.markTourSeen);
    addTearDown(() async {
      controller.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      GaussApp(controller: controller, initialLocation: '/study'),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Counts read from the real corpus, not parts mislabeled as chapters.
    expect(find.text('18 chapters · 136 units'), findsOneWidget);

    final part = find.byKey(
      const ValueKey('study-section-toggle-math_algebraic_foundations'),
    );
    await tester.scrollUntilVisible(
      part,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(part);
    await tester.pump(const Duration(milliseconds: 400));

    final chapter = find.byKey(const ValueKey('study-chapter-toggle-sets'));
    await tester.ensureVisible(chapter);
    await tester.tap(chapter);
    await tester.pump(const Duration(milliseconds: 400));

    final unit = find.byKey(const ValueKey('study-unit-sets_venn_diagrams'));
    expect(unit, findsOneWidget);
    expect(find.text('Venn diagrams'), findsOneWidget);
    expect(tester.getSize(unit).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(unit);
    await tester.tap(unit);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    // A unit opens one of the chapter's real five-question lessons.
    expect(find.text('Question 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
