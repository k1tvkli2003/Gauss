import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  testWidgets('any chapter can be reached from the Map navigator', (
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

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    await tester.pumpWidget(
      GaussApp(controller: controller, initialLocation: '/map'),
    );
    await settle();
    expect(controller.selectedTopic.key, 'sets');

    // Chapter 3 of the first part, reached through the navigator.
    await tester.tap(find.byKey(const ValueKey('map-orbit-selector')));
    await settle();
    final row = find.byKey(
      const ValueKey('orbit-chapter-radicals_algebraic_expressions'),
    );
    await tester.ensureVisible(row);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    await tester.tap(row);
    await settle();
    expect(controller.selectedTopic.key, 'radicals_algebraic_expressions');
    expect(tester.takeException(), isNull);

    // The list holds exactly the selected part's chapters.
    await tester.tap(find.byKey(const ValueKey('map-orbit-selector')));
    await settle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('orbit-navigator-chapters')),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(5),
    );
    expect(tester.takeException(), isNull);
  });
}
