// Taps every enabled control on each primary route, one per fresh app, and
// fails on any exception. This is the mechanical half of a click-through:
// it proves no control throws, overflows or dead-ends the router.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/state/gauss_controller.dart';

const _routes = [
  '/map',
  '/study',
  '/insights',
  '/study/chapter/sets',
  '/mission/sets',
];

Finder _controls() => find.byWidgetPredicate((widget) {
  if (widget is InkWell) return widget.onTap != null;
  if (widget is IconButton) return widget.onPressed != null;
  if (widget is ButtonStyleButton) return widget.onPressed != null;
  if (widget is GestureDetector) return widget.onTap != null;
  return false;
}, skipOffstage: true).hitTestable();

void main() {
  late GaussDatabase database;
  late GaussController controller;

  setUpAll(() async {
    database = GaussDatabase(NativeDatabase.memory());
    controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    await controller.initialize();
    await controller.markTourSeen();
  });

  tearDownAll(() async {
    controller.dispose();
    await database.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> open(WidgetTester tester, String route) async {
    await tester.pumpWidget(
      GaussApp(
        key: UniqueKey(),
        controller: controller,
        initialLocation: route,
      ),
    );
    await settle(tester);
  }

  for (final route in _routes) {
    testWidgets('every control on $route responds without error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await open(tester, route);
      final total = _controls().evaluate().length;
      expect(total, greaterThan(0), reason: '$route exposes controls');
      final failures = <String>[];
      for (var index = 0; index < total; index++) {
        await open(tester, route);
        final controls = _controls();
        if (index >= controls.evaluate().length) break;
        final target = controls.at(index);
        final label = target.evaluate().single.widget.runtimeType;
        await tester.tap(target, warnIfMissed: false);
        await settle(tester);
        final error = tester.takeException();
        if (error != null) failures.add('#$index $label: $error');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
