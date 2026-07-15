import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app/gauss_app.dart';
import 'data/progress_repository.dart';
import 'data/local/gauss_database.dart';
import 'data/question_bank_repository.dart';
import 'state/gauss_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final database = GaussDatabase.defaults();
  final controller = GaussController(
    QuestionBankRepository(),
    ProgressRepository(database),
  );
  await controller.initialize();
  runApp(GaussApp(controller: controller));
}
