part of 'gauss_app.dart';

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
