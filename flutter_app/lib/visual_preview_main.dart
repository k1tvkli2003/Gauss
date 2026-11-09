import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/features/auth/gauss_account_session.dart';

/// Android-only visual QA entrypoint.
///
/// This file is never referenced by the production entrypoint or release
/// workflow. It requires an explicit compile-time opt-in and owns a stable,
/// isolated local account so preview work cannot touch a signed user's data or
/// weaken the real Supabase authentication boundary.
Future<void> main() async {
  const enabled = bool.fromEnvironment('GAUSS_VISUAL_PREVIEW');
  if (!enabled) {
    throw StateError(
      'Visual preview is fail-closed. Build with '
      '--dart-define=GAUSS_VISUAL_PREVIEW=true.',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: GaussColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: GaussColors.hairline,
    ),
  );

  final session = await GaussAccountSession.open('visual-preview-local-v1');
  await session.controller.markTourSeen();
  runApp(
    _VisualPreviewOwner(
      session: session,
      initialLocation: const String.fromEnvironment(
        'GAUSS_PREVIEW_ROUTE',
        defaultValue: '/map',
      ),
    ),
  );
}

class _VisualPreviewOwner extends StatefulWidget {
  const _VisualPreviewOwner({
    required this.session,
    required this.initialLocation,
  });

  final GaussAccountSession session;
  final String initialLocation;

  @override
  State<_VisualPreviewOwner> createState() => _VisualPreviewOwnerState();
}

class _VisualPreviewOwnerState extends State<_VisualPreviewOwner> {
  @override
  void dispose() {
    unawaited(widget.session.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GaussApp(
    controller: widget.session.controller,
    initialLocation: widget.initialLocation,
  );
}
