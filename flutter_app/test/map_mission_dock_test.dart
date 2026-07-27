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

  testWidgets(
    'the compact map dock distinguishes the current mission from a selected set',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final database = GaussDatabase(NativeDatabase.memory());
      final controller = GaussController(
        QuestionBankRepository(),
        ProgressRepository(database),
      );
      addTearDown(() async {
        controller.dispose();
        await database.close();
      });
      await tester.binding.setSurfaceSize(const Size(411, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: GaussScope(
            controller: controller,
            child: const Scaffold(body: MapScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('CURRENT MISSION'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^CURRENT MISSION\.')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('map-node-sets:20:20')));
      await tester.pumpAndSettle();

      expect(find.text('SELECTED SET'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^SELECTED SET\.')), findsOneWidget);
      semantics.dispose();
      expect(find.text('Study'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
