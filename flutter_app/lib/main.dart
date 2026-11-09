import 'package:flutter/material.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:gauss/features/auth/gauss_auth_app.dart';
import 'package:gauss/features/auth/gauss_auth_controller.dart';
import 'package:gauss/backend/gauss_supabase.dart';

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
      systemNavigationBarColor: GaussColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: GaussColors.hairline,
    ),
  );
  runApp(GaussAuthApp(auth: auth, appBuild: appBuild));
}
