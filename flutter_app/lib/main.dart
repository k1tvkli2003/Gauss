import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'auth/gauss_auth_app.dart';
import 'auth/gauss_auth_controller.dart';
import 'backend/gauss_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final supabase = await GaussSupabase.initialize();
  final auth = GaussAuthController(supabase);
  final package = await PackageInfo.fromPlatform();
  final appBuild = int.tryParse(package.buildNumber) ?? 1;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1417),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Color(0xFF243337),
    ),
  );
  runApp(GaussAuthApp(auth: auth, appBuild: appBuild));
}
