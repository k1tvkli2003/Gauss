import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a web deep link survives the offline bootstrap screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 820));
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/study';

    final database = GaussDatabase(NativeDatabase.memory());
    final controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );

    try {
      await tester.pumpWidget(GaussApp(controller: controller));
      expect(find.text('Opening your offline observatory…'), findsOneWidget);

      await controller.initialize();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('STUDY OBSERVATORY'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Study'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
      await database.close();
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
      await tester.binding.setSurfaceSize(null);
    }
  });
}
