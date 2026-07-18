import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import '../screens/insights_screen.dart';
import '../screens/map_screen.dart';
import '../screens/mission_screen.dart';
import '../screens/practice_screen.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';
import 'gauss_theme.dart';

class GaussApp extends StatefulWidget {
  const GaussApp({required this.controller, super.key});
  final GaussController controller;

  @override
  State<GaussApp> createState() => _GaussAppState();
}

class _GaussAppState extends State<GaussApp> {
  bool _listeningForBootstrap = false;

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
      GoRoute(
        path: '/review',
        builder: (context, state) => MissionScreen(
          topicKey: 'review',
          count: (int.tryParse(state.uri.queryParameters['count'] ?? '') ?? 10)
              .clamp(5, 50),
          review: true,
        ),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/map'),
      GoRoute(path: '/missions', redirect: (context, state) => '/practice'),
      GoRoute(path: '/arena', redirect: (context, state) => '/practice'),
      GoRoute(path: '/profile', redirect: (context, state) => '/insights'),
    ],
  );

  @override
  void initState() {
    super.initState();
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
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.fatalError != null) {
      return MaterialApp(
        title: 'Gauss',
        debugShowCheckedModeBanner: false,
        theme: buildGaussTheme(),
        home: _StartupFailureScreen(controller: widget.controller),
      );
    }
    if (!widget.controller.ready) {
      return MaterialApp(
        title: 'Gauss',
        debugShowCheckedModeBanner: false,
        theme: buildGaussTheme(),
        home: const _StartupView(),
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
  }
}

class _StartupView extends StatelessWidget {
  const _StartupView();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/visual/map/orrery_atmosphere_portrait.png',
          fit: BoxFit.cover,
          cacheWidth: 1200,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x3303090B), Color(0xF703090B)],
              stops: [.25, 1],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GaussWordmark(width: 214),
                const SizedBox(height: 7),
                const Text(
                  'Chart what you can prove.',
                  style: TextStyle(color: GaussColors.muted),
                ),
                const SizedBox(height: 30),
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Opening your offline observatory…',
                  style: TextStyle(color: GaussColors.fog, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
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

  static const destinations = <NavigationDestination>[
    NavigationDestination(
      icon: GaussNavGlyph(glyph: GaussDestinationGlyph.map, selected: false),
      selectedIcon: GaussNavGlyph(
        glyph: GaussDestinationGlyph.map,
        selected: true,
      ),
      label: 'Map',
    ),
    NavigationDestination(
      icon: GaussNavGlyph(
        glyph: GaussDestinationGlyph.practice,
        selected: false,
      ),
      selectedIcon: GaussNavGlyph(
        glyph: GaussDestinationGlyph.practice,
        selected: true,
      ),
      label: 'Practice',
    ),
    NavigationDestination(
      icon: GaussNavGlyph(
        glyph: GaussDestinationGlyph.insights,
        selected: false,
      ),
      selectedIcon: GaussNavGlyph(
        glyph: GaussDestinationGlyph.insights,
        selected: true,
      ),
      label: 'Insights',
    ),
  ];

  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final useRail = constraints.maxWidth >= 760;
      final extendRail = constraints.maxWidth >= 1260;
      if (!useRail) {
        return Scaffold(
          body: shell,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: GaussColors.hairline)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xB803090B),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              destinations: destinations,
              onDestinationSelected: _go,
            ),
          ),
        );
      }
      return Scaffold(
        body: Row(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: GaussColors.ink,
                border: Border(right: BorderSide(color: GaussColors.hairline)),
              ),
              child: SafeArea(
                right: false,
                child: NavigationRail(
                  extended: extendRail,
                  minWidth: 82,
                  minExtendedWidth: 188,
                  groupAlignment: -.58,
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _go,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
                    child: extendRail
                        ? const GaussWordmark(width: 132)
                        : const TheoremStarMark(size: 43),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Semantics(
                          label: 'Offline. All learning content is available.',
                          child: extendRail
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _OfflineDot(),
                                    SizedBox(width: 8),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        color: GaussColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : const _OfflineDot(),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: GaussNavGlyph(
                        glyph: GaussDestinationGlyph.map,
                        selected: false,
                      ),
                      selectedIcon: GaussNavGlyph(
                        glyph: GaussDestinationGlyph.map,
                        selected: true,
                      ),
                      label: Text('Map'),
                    ),
                    NavigationRailDestination(
                      icon: GaussNavGlyph(
                        glyph: GaussDestinationGlyph.practice,
                        selected: false,
                      ),
                      selectedIcon: GaussNavGlyph(
                        glyph: GaussDestinationGlyph.practice,
                        selected: true,
                      ),
                      label: Text('Practice'),
                    ),
                    NavigationRailDestination(
                      icon: GaussNavGlyph(
                        glyph: GaussDestinationGlyph.insights,
                        selected: false,
                      ),
                      selectedIcon: GaussNavGlyph(
                        glyph: GaussDestinationGlyph.insights,
                        selected: true,
                      ),
                      label: Text('Insights'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: shell),
          ],
        ),
      );
    },
  );
}

class _OfflineDot extends StatelessWidget {
  const _OfflineDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GaussColors.signalBright,
      boxShadow: [
        BoxShadow(
          color: GaussColors.signal.withValues(alpha: .48),
          blurRadius: 9,
          spreadRadius: 1,
        ),
      ],
    ),
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
