import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/study_curriculum.dart';
import '../feedback/feedback_capture.dart';
import '../screens/archive_screen.dart';
import '../screens/backup_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/map_screen.dart';
import '../screens/mission_screen.dart';
import '../screens/practice_screen.dart';
import '../state/gauss_controller.dart';
import '../widgets/first_run_tour.dart';
import '../widgets/gauss_brand.dart';
import 'gauss_design_system.dart';
import 'gauss_theme.dart';

class GaussApp extends StatefulWidget {
  const GaussApp({required this.controller, super.key});
  final GaussController controller;

  @override
  State<GaussApp> createState() => _GaussAppState();
}

class _GaussAppState extends State<GaussApp> {
  bool _listeningForBootstrap = false;
  final ValueNotifier<String> _routeName = ValueNotifier('/');
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey();

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
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
                path: '/study',
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
            child: ArchiveScreen(
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
          child: const ArchiveScreen.revisit(),
        ),
      ),
      GoRoute(
        path: '/study/gems',
        pageBuilder: (context, state) => _gaussSpatialPage(
          context: context,
          state: state,
          child: const ArchiveScreen.gems(),
        ),
      ),
      GoRoute(
        path: '/vault',
        pageBuilder: (context, state) => _gaussSpatialPage(
          context: context,
          state: state,
          child: const BackupScreen(),
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

CustomTransitionPage<void> _gaussSpatialPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final enterDuration = GaussMotion.resolve(
    context,
    _GaussRouteMotion.detailEnter,
  );
  final exitDuration = GaussMotion.resolve(
    context,
    _GaussRouteMotion.detailExit,
  );
  final reducedMotion = enterDuration == Duration.zero;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: enterDuration,
    reverseTransitionDuration: exitDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reducedMotion) return child;

      final motion = CurvedAnimation(
        parent: animation,
        curve: _GaussRouteMotion.enterCurve,
        reverseCurve: _GaussRouteMotion.exitCurve,
      );
      return FadeTransition(
        key: const ValueKey('gauss-spatial-route-motion'),
        opacity: motion,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, _GaussRouteMotion.detailTravel),
            end: Offset.zero,
          ).animate(motion),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: _GaussRouteMotion.detailStartScale,
              end: 1,
            ).animate(motion),
            child: child,
          ),
        ),
      );
    },
  );
}

/// The route-level subset of the Gauss Motion Bible.
///
/// Peer destinations move laterally while detail/mission surfaces move into
/// depth. Both grammars use only transform and opacity, keep the shell stable,
/// and resolve to an immediate state change through [GaussMotion].
abstract final class _GaussRouteMotion {
  static const branch = Duration(milliseconds: 280);
  static const detailEnter = Duration(milliseconds: 340);
  static const detailExit = Duration(milliseconds: 240);

  static const branchTravel = .034;
  static const branchStartOpacity = .9;
  static const detailTravel = .024;
  static const detailStartScale = .99;

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  void _go(int index) => widget.shell.goBranch(
    index,
    initialLocation: index == widget.shell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final shell = widget.shell;
    final tourActive = controller.needsTour && shell.currentIndex == 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = GaussWindowClass.fromWidth(constraints.maxWidth);
        final useRail = window.usesNavigationRail;
        final extendRail = window.extendsNavigationRail;
        if (!useRail) {
          final footerSafeBottom = GaussMetrics.compactNavigationSafeBottom(
            context,
          );
          return Scaffold(
            extendBody: true,
            body: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  excluding: tourActive,
                  child: IgnorePointer(
                    ignoring: tourActive,
                    child: _BranchEntrance(
                      activeIndex: shell.currentIndex,
                      child: shell,
                    ),
                  ),
                ),
                if (tourActive)
                  FirstRunTour(onDismiss: controller.markTourSeen),
              ],
            ),
            bottomNavigationBar: tourActive
                ? null
                : Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, footerSafeBottom),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 1,
                      child: _GaussFloatingNavigation(
                        selectedIndex: shell.currentIndex,
                        onSelected: _go,
                      ),
                    ),
                  ),
          );
        }
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                excluding: tourActive,
                child: IgnorePointer(
                  ignoring: tourActive,
                  child: Row(
                    children: [
                      SafeArea(
                        minimum: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: GaussColors.deepInk.withValues(
                                  alpha: .88,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: GaussColors.brass.withValues(
                                    alpha: .24,
                                  ),
                                ),
                              ),
                              child: NavigationRail(
                                backgroundColor: Colors.transparent,
                                extended: extendRail,
                                minWidth: 82,
                                minExtendedWidth: 188,
                                groupAlignment: -.58,
                                selectedIndex: shell.currentIndex,
                                onDestinationSelected: _go,
                                leading: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    30,
                                  ),
                                  child: extendRail
                                      ? const GaussWordmark(width: 132)
                                      : const TheoremStarMark(size: 43),
                                ),
                                trailing: Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: Semantics(
                                        label:
                                            'Offline. All learning content is available.',
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
                                    label: Text('Study'),
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
                        ),
                      ),
                      Expanded(
                        child: _BranchEntrance(
                          activeIndex: shell.currentIndex,
                          child: shell,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tourActive) FirstRunTour(onDismiss: controller.markTourSeen),
            ],
          ),
        );
      },
    );
  }
}

class _GaussFloatingNavigation extends StatelessWidget {
  const _GaussFloatingNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <({String label, GaussDestinationGlyph glyph})>[
    (label: 'Map', glyph: GaussDestinationGlyph.map),
    (label: 'Study', glyph: GaussDestinationGlyph.practice),
    (label: 'Insights', glyph: GaussDestinationGlyph.insights),
  ];

  @override
  Widget build(BuildContext context) {
    // At accessibility scales the three full labels cannot coexist inside a
    // 320dp viewport without broken words or a bulky two-row footer. The
    // custom glyphs become the visible navigation language while Tooltip and
    // Semantics retain every explicit destination name.
    final symbolOnly = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final itemWidth = symbolOnly ? 58.0 : 82.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: GaussColors.abyss.withValues(alpha: .68),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: GaussColors.brass.withValues(alpha: .08),
            blurRadius: 16,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        key: const ValueKey('gauss-floating-navigation-dock'),
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GaussColors.deepInk.withValues(alpha: .66),
                  GaussColors.ink.withValues(alpha: .78),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: GaussColors.brassLight.withValues(alpha: .22),
              ),
            ),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: SizedBox(
                height: GaussMetrics.compactNavigationHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < _items.length; index++)
                      _GaussNavigationItem(
                        key: ValueKey(
                          'gauss-nav-${_items[index].label.toLowerCase()}',
                        ),
                        label: _items[index].label,
                        glyph: _items[index].glyph,
                        selected: selectedIndex == index,
                        width: itemWidth,
                        showLabel: !symbolOnly,
                        onPressed: () => onSelected(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaussNavigationItem extends StatelessWidget {
  const _GaussNavigationItem({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.width,
    required this.showLabel,
    required this.onPressed,
    super.key,
  });

  final String label;
  final GaussDestinationGlyph glyph;
  final bool selected;
  final double width;
  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: GaussMetrics.compactNavigationHeight,
    child: Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            splashColor: GaussColors.brassLight.withValues(alpha: .12),
            highlightColor: GaussColors.brassLight.withValues(alpha: .07),
            focusColor: GaussColors.brassLight.withValues(alpha: .1),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: GaussMotion.resolve(context, GaussMotion.micro),
                  curve: Curves.easeOutCubic,
                  top: showLabel
                      ? selected
                            ? 2
                            : 4
                      : selected
                      ? 11
                      : 13,
                  child: AnimatedContainer(
                    duration: GaussMotion.resolve(context, GaussMotion.micro),
                    width: selected ? 31 : 29,
                    height: selected ? 31 : 29,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? GaussColors.brass.withValues(alpha: .17)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? GaussColors.brassLight.withValues(alpha: .3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: GaussNavGlyph(glyph: glyph, selected: selected),
                    ),
                  ),
                ),
                if (showLabel)
                  Positioned(
                    left: 2,
                    right: 2,
                    bottom: 4,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? GaussColors.brassLight
                            : GaussColors.fog,
                        fontSize: 10,
                        height: 1,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        letterSpacing: selected ? .25 : .1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A deliberate, tiny orbit drift makes destination changes feel related to
/// the map without delaying navigation. It leaves all branch state mounted
/// and becomes a no-op under the platform's reduced-motion preference.
class _BranchEntrance extends StatefulWidget {
  const _BranchEntrance({required this.activeIndex, required this.child});

  final int activeIndex;
  final Widget child;

  @override
  State<_BranchEntrance> createState() => _BranchEntranceState();
}

class _BranchEntranceState extends State<_BranchEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _GaussRouteMotion.branch,
    value: 1,
  );
  var _logicalDirection = 1;
  var _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    _controller.duration = GaussMotion.resolve(
      context,
      _GaussRouteMotion.branch,
    );
    if (reducedMotion) {
      // A preference change during motion settles immediately without
      // replaying the entrance when full motion is enabled again.
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _BranchEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.activeIndex - oldWidget.activeIndex;
    if (delta == 0) return;
    _logicalDirection = delta.sign;
    if (_reducedMotion) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reducedMotion) return widget.child;
    final motion = CurvedAnimation(
      parent: _controller,
      curve: _GaussRouteMotion.enterCurve,
    );
    final readingDirection = Directionality.of(context);
    final visualDirection = readingDirection == TextDirection.ltr
        ? _logicalDirection
        : -_logicalDirection;
    final position = Tween<Offset>(
      begin: Offset(_GaussRouteMotion.branchTravel * visualDirection, 0),
      end: Offset.zero,
    ).animate(motion);
    final opacity = Tween<double>(
      begin: _GaussRouteMotion.branchStartOpacity,
      end: 1,
    ).animate(motion);
    return RepaintBoundary(
      child: FadeTransition(
        key: const ValueKey('gauss-branch-route-motion'),
        opacity: opacity,
        child: SlideTransition(position: position, child: widget.child),
      ),
    );
  }
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
