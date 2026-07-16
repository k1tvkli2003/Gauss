import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1417),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Color(0xFF243337),
    ),
  );
  runApp(GaussApp(controller: controller));
  await controller.initialize();
}
