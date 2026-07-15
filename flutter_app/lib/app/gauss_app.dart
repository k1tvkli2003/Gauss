import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import '../screens/insights_screen.dart';
import '../screens/map_screen.dart';
import '../screens/mission_screen.dart';
import '../screens/practice_screen.dart';
import '../state/gauss_controller.dart';
import 'gauss_theme.dart';

class GaussApp extends StatefulWidget {
  const GaussApp({required this.controller, super.key});
  final GaussController controller;

  @override
  State<GaussApp> createState() => _GaussAppState();
}

class _GaussAppState extends State<GaussApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/map',
    errorBuilder: (context, state) => const _RouteErrorScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                builder: (context, state) => const PracticeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/resume',
        builder: (context, state) =>
            const MissionScreen(topicKey: 'resume', resume: true),
      ),
      GoRoute(
        path: '/mission/:topicKey',
        builder: (context, state) {
          final difficulties =
              (state.uri.queryParametersAll['difficulty'] ?? const [])
                  .map(Difficulty.tryFromKey)
                  .whereType<Difficulty>()
                  .toSet();
          final requestedCount = int.tryParse(
            state.uri.queryParameters['count'] ?? '',
          );
          return MissionScreen(
            topicKey: state.pathParameters['topicKey']!,
            count: (requestedCount ?? 10).clamp(5, 50),
            difficulties: difficulties,
            sourceBanks: (state.uri.queryParametersAll['source'] ?? const [])
                .where(const {'nardebam', 'gauss'}.contains)
                .toSet(),
          );
        },
      ),
      GoRoute(
        path: '/revenge',
        builder: (context, state) => MissionScreen(
          topicKey: 'revenge',
          count: (int.tryParse(state.uri.queryParameters['count'] ?? '') ?? 10)
              .clamp(5, 50),
          revenge: true,
        ),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/map'),
      GoRoute(path: '/missions', redirect: (context, state) => '/practice'),
      GoRoute(path: '/arena', redirect: (context, state) => '/practice'),
      GoRoute(path: '/profile', redirect: (context, state) => '/insights'),
    ],
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, child) {
      if (widget.controller.fatalError != null) {
        return MaterialApp(
          title: 'Gauss',
          debugShowCheckedModeBanner: false,
          theme: buildGaussTheme(),
          home: _StartupFailureScreen(controller: widget.controller),
        );
      }
      return GaussScope(
        controller: widget.controller,
        child: MaterialApp.router(
          title: 'Gauss',
          debugShowCheckedModeBanner: false,
          theme: buildGaussTheme(),
          routerConfig: _router,
        ),
      );
    },
  );
}

class _StartupFailureScreen extends StatefulWidget {
  const _StartupFailureScreen({required this.controller});
  final GaussController controller;

  @override
  State<_StartupFailureScreen> createState() => _StartupFailureScreenState();
}

class _StartupFailureScreenState extends State<_StartupFailureScreen> {
  bool retrying = false;

  Future<void> _retry() async {
    setState(() => retrying = true);
    await widget.controller.retryInitialize();
    if (mounted) setState(() => retrying = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: GaussColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Gauss could not open safely',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 9),
                const Text(
                  'The offline archive or local progress store could not be verified. No data was reset. Try opening it again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GaussColors.muted),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: retrying ? null : _retry,
                  icon: retrying
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(retrying ? 'Opening…' : 'Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.public_outlined),
      selectedIcon: Icon(Icons.public),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Practice',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Insights',
    ),
  ];

  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final expanded = constraints.maxWidth >= 800;
      if (!expanded) {
        return Scaffold(
          body: shell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.currentIndex,
            destinations: destinations,
            onDestinationSelected: _go,
          ),
        );
      }
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: constraints.maxWidth >= 1320,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Icon(
                  Icons.explore,
                  color: GaussColors.brassLight,
                  size: 34,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.public_outlined),
                  selectedIcon: Icon(Icons.public),
                  label: Text('Map'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Practice'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: Text('Insights'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    },
  );
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
