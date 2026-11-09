part of 'gauss_app.dart';

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
  const _AppShell({required this.shell, this.accountEmail, this.onSignOut});
  final StatefulNavigationShell shell;
  final String? accountEmail;
  final Future<void> Function()? onSignOut;

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
        final viewport = GaussViewport.fromSize(constraints.biggest);
        final useRail = viewport.usesNavigationRail;
        final extendRail = viewport.extendsNavigationRail;
        final constrainedLandscape = viewport.isConstrainedLandscape;
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
                                key: const ValueKey('gauss-navigation-rail'),
                                backgroundColor: Colors.transparent,
                                extended: extendRail,
                                minWidth: constrainedLandscape ? 72 : 82,
                                minExtendedWidth: 188,
                                groupAlignment: constrainedLandscape ? 0 : -.58,
                                selectedIndex: shell.currentIndex,
                                onDestinationSelected: _go,
                                leading: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    12,
                                    constrainedLandscape ? 6 : 12,
                                    12,
                                    constrainedLandscape ? 6 : 30,
                                  ),
                                  child: extendRail
                                      ? const GaussWordmark(width: 132)
                                      : TheoremStarMark(
                                          size: constrainedLandscape ? 32 : 43,
                                        ),
                                ),
                                trailing: constrainedLandscape
                                    ? const SizedBox.shrink()
                                    : Expanded(
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
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        _OfflineDot(),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Offline',
                                                          style: TextStyle(
                                                            color: GaussColors
                                                                .muted,
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
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
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
