part of 'gauss_app.dart';

/// Route motion, ported from SonusKt: a quiet fade-through. The incoming
/// surface fades in after the outgoing one has started to leave, with no
/// slide or scale, so navigation reads as calm rather than spatial.
abstract final class _GaussRouteMotion {
  static const fadeIn = Duration(milliseconds: 220);
  static const fadeInDelay = Duration(milliseconds: 60);
  static const fadeOut = Duration(milliseconds: 140);
  static final detailEnter = fadeInDelay + fadeIn;
  static const detailExit = fadeOut;

  static const enterCurve = Curves.easeOut;
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
                // Soft fade so the last line of content never collides
                // with the floating bar (SonusKt shell pattern).
                if (!tourActive)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height:
                        GaussMetrics.compactNavigationFootprint(context) +
                        GaussSpacing.space16,
                    child: const IgnorePointer(
                      child: DecoratedBox(
                        key: ValueKey('gauss-navigation-scrim'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x0003090B), Color(0xEB03090B)],
                          ),
                        ),
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

/// The phone footer, ported from the SonusKt `GlassNavBar` the owner chose as
/// the house pattern: one floating pill, the selected destination filled
/// with the accent and showing its label, the others icon-only. Showing one
/// label keeps the bar short at 320dp and 200% text without broken words.
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
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('gauss-floating-navigation-dock'),
    // Elevation marks the only chrome that floats above scrolling content.
    decoration: const ShapeDecoration(
      shape: StadiumBorder(),
      shadows: [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 36,
          spreadRadius: -4,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: CustomPaint(
      foregroundPainter: const _NavigationRimPainter(),
      child: Container(
        height: GaussMetrics.compactNavigationHeight,
        padding: const EdgeInsets.all(6),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: GaussColors.surface.withValues(alpha: .9),
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < _items.length; index++) ...[
                if (index > 0) const SizedBox(width: 2),
                _GaussNavigationItem(
                  key: ValueKey(
                    'gauss-nav-${_items[index].label.toLowerCase()}',
                  ),
                  label: _items[index].label,
                  glyph: _items[index].glyph,
                  selected: selectedIndex == index,
                  onPressed: () => onSelected(index),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// A light top edge fading toward the bottom gives the pill its rim without
/// spending the brass accent on a border.
class _NavigationRimPainter extends CustomPainter {
  const _NavigationRimPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x2EFFFFFF), Color(0x0AFFFFFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _NavigationRimPainter oldDelegate) => false;
}

class _GaussNavigationItem extends StatelessWidget {
  const _GaussNavigationItem({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final GaussDestinationGlyph glyph;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final duration = GaussMotion.resolve(context, GaussMotion.standard);
    final tint = selected ? GaussColors.deepInk : GaussColors.muted;
    // The single visible label may grow with the system text size, but is
    // capped so three destinations still fit one row at 320dp.
    final labelScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            splashColor: GaussColors.brassLight.withValues(alpha: .14),
            highlightColor: GaussColors.brassLight.withValues(alpha: .08),
            focusColor: GaussColors.brassLight.withValues(alpha: .16),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 52, minWidth: 52),
              padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 15),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: selected ? GaussColors.brass : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GaussNavGlyph(
                    glyph: glyph,
                    selected: selected,
                    size: 24,
                    color: tint,
                  ),
                  // AnimatedSize asserts on a zero duration, so reduced
                  // motion swaps the label in place.
                  if (duration == Duration.zero)
                    selected
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              textScaler: labelScaler,
                              style: const TextStyle(
                                color: GaussColors.deepInk,
                                fontSize: GaussTypeScale.body,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink()
                  else
                    AnimatedSize(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      alignment: AlignmentDirectional.centerStart,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 8,
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                textScaler: labelScaler,
                                style: const TextStyle(
                                  color: GaussColors.deepInk,
                                  fontSize: GaussTypeScale.body,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    duration: _GaussRouteMotion.fadeIn,
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: _GaussRouteMotion.enterCurve,
  );
  var _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    _controller.duration = GaussMotion.resolve(
      context,
      _GaussRouteMotion.fadeIn,
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
    if (widget.activeIndex == oldWidget.activeIndex) return;
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
    return RepaintBoundary(
      child: FadeTransition(
        key: const ValueKey('gauss-branch-route-motion'),
        opacity: _opacity,
        child: widget.child,
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
    ),
  );
}
