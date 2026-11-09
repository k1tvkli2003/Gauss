import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/features/feedback/feedback_capture.dart';
import 'package:gauss/features/study/study_room_screen.dart';
import 'package:gauss/features/vault/vault_screen.dart';
import 'package:gauss/features/insights/insights_screen.dart';
import 'package:gauss/features/map/map_screen.dart';
import 'package:gauss/features/mission/mission_screen.dart';
import 'package:gauss/features/study/study_hub_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/features/onboarding/first_run_tour.dart';
import 'package:gauss/ui/components/gauss_brand.dart';
import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

part 'gauss_startup.dart';
part 'gauss_shell.dart';

class GaussApp extends StatefulWidget {
  const GaussApp({
    required this.controller,
    this.accountEmail,
    this.onSignOut,
    this.initialLocation,
    super.key,
  });
  final GaussController controller;
  final String? accountEmail;
  final Future<void> Function()? onSignOut;
  final String? initialLocation;

  @override
  State<GaussApp> createState() => _GaussAppState();
}

class _GaussAppState extends State<GaussApp> {
  bool _listeningForBootstrap = false;
  final ValueNotifier<String> _routeName = ValueNotifier('/');
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey();

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: widget.initialLocation,
    errorBuilder: (context, state) => const _RouteErrorScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(
          shell: shell,
          accountEmail: widget.accountEmail,
          onSignOut: widget.onSignOut,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) =>
                    const GaussVisibilityGate(child: MapScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (context, state) =>
                    const GaussVisibilityGate(child: StudyHubScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) =>
                    const GaussVisibilityGate(child: InsightsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/resume',
        pageBuilder: (context, state) => _gaussSpatialPage(
          context: context,
          state: state,
          child: const MissionScreen(topicKey: 'resume', resume: true),
        ),
      ),
      GoRoute(
        path: '/mission/:topicKey',
        pageBuilder: (context, state) {
          final offset = int.tryParse(
            state.uri.queryParameters['offset'] ?? '',
          );
          return _gaussSpatialPage(
            context: context,
            state: state,
            child: MissionScreen(
              topicKey: state.pathParameters['topicKey']!,
              studyOffset: offset?.clamp(0, 100000),
            ),
          );
        },
      ),
      GoRoute(path: '/revenge', redirect: (context, state) => '/study/revisit'),
      GoRoute(
        path: '/study/chapter/:topicKey',
        pageBuilder: (context, state) {
          final offset = int.tryParse(
            state.uri.queryParameters['offset'] ?? '',
          );
          final count = int.tryParse(state.uri.queryParameters['count'] ?? '');
          return _gaussSpatialPage(
            context: context,
            state: state,
            child: StudyRoomScreen(
              topicKey: state.pathParameters['topicKey']!,
              offset: (offset ?? 0).clamp(0, 100000),
              count: (count ?? GaussStudyCurriculum.batchSize).clamp(1, 50),
              shuffleSeed: int.tryParse(
                state.uri.queryParameters['shuffle'] ?? '',
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/study/revisit',
        pageBuilder: (context, state) => _gaussSpatialPage(
          context: context,
          state: state,
          child: const StudyRoomScreen.revisit(),
        ),
      ),
      GoRoute(
        path: '/study/gems',
        pageBuilder: (context, state) => _gaussSpatialPage(
          context: context,
          state: state,
          child: const StudyRoomScreen.gems(),
        ),
      ),
      GoRoute(
        path: '/vault',
        pageBuilder: (context, state) => _gaussSpatialPage(
          context: context,
          state: state,
          child: const VaultScreen(),
        ),
      ),
      GoRoute(path: '/review', redirect: (context, state) => '/study/revisit'),
      GoRoute(path: '/', redirect: (context, state) => '/map'),
      GoRoute(path: '/practice', redirect: (context, state) => '/study'),
      GoRoute(path: '/missions', redirect: (context, state) => '/study'),
      GoRoute(path: '/arena', redirect: (context, state) => '/study'),
      GoRoute(
        path: '/archive/:topicKey',
        redirect: (context, state) =>
            '/study/chapter/${state.pathParameters['topicKey']}',
      ),
      GoRoute(path: '/profile', redirect: (context, state) => '/insights'),
    ],
  );

  void _trackRoute() {
    _routeName.value = _router.routeInformationProvider.value.uri.toString();
  }

  @override
  void initState() {
    super.initState();
    _trackRoute();
    _router.routeInformationProvider.addListener(_trackRoute);
    _listenForBootstrapIfNeeded();
  }

  @override
  void didUpdateWidget(covariant GaussApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (_listeningForBootstrap) {
      oldWidget.controller.removeListener(_handleBootstrapChange);
      _listeningForBootstrap = false;
    }
    _listenForBootstrapIfNeeded();
  }

  void _listenForBootstrapIfNeeded() {
    if (widget.controller.ready || _listeningForBootstrap) return;
    widget.controller.addListener(_handleBootstrapChange);
    _listeningForBootstrap = true;
  }

  void _handleBootstrapChange() {
    if (!mounted) return;
    if (widget.controller.ready && _listeningForBootstrap) {
      widget.controller.removeListener(_handleBootstrapChange);
      _listeningForBootstrap = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    if (_listeningForBootstrap) {
      widget.controller.removeListener(_handleBootstrapChange);
    }
    _router.routeInformationProvider.removeListener(_trackRoute);
    _routeName.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GaussScope(
      controller: widget.controller,
      accountEmail: widget.accountEmail,
      onSignOut: widget.onSignOut,
      child: MaterialApp.router(
        title: 'Gauss',
        debugShowCheckedModeBanner: false,
        // Product chrome is intentionally English/LTR regardless of the
        // Android system locale. Preserved Persian learning blocks establish
        // their own local RTL islands in ContentBlocksView.
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        theme: buildGaussTheme(),
        routerConfig: _router,
        builder: (context, child) {
          // Keep the router mounted while the offline stores open. Replacing a
          // router app with a temporary MaterialApp resets the browser route to
          // `/`, which makes refreshed and bookmarked web deep links land on
          // the map after bootstrap.
          if (widget.controller.fatalError != null) {
            return _StartupFailureScreen(controller: widget.controller);
          }
          if (!widget.controller.ready) return const _StartupView();
          return GaussFeedbackCapture(
            controller: widget.controller.feedback,
            routeName: () => _routeName.value,
            navigatorKey: _rootNavigatorKey,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.travel_explore, size: 44),
                const SizedBox(height: 16),
                Text(
                  'That orbit does not exist.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This link is not part of the current learning map.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GaussColors.muted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/map'),
                  child: const Text('Return to map'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
