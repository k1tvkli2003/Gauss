import 'package:flutter/material.dart';

import '../app/gauss_theme.dart';
import 'gauss_brand.dart';

/// A three-card welcome shown once, over the map.
///
/// It names the three places the learner will actually live in, then gets out
/// of the way. Dismissing it counts as seeing it — there is no second prompt.
class FirstRunTour extends StatefulWidget {
  const FirstRunTour({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  State<FirstRunTour> createState() => _FirstRunTourState();
}

class _FirstRunTourState extends State<FirstRunTour> {
  static const _steps = <_TourStep>[
    _TourStep(
      icon: Icons.route_outlined,
      eyebrow: 'THE PATH',
      title: 'A continuous route, not a scoreboard',
      detail:
          'Every unit is sliced into short sets of twenty questions. Follow '
          'the path in order, or wander — the map remembers where you were.',
    ),
    _TourStep(
      icon: Icons.menu_book_outlined,
      eyebrow: 'THE STUDY ROOM',
      title: 'Commit, reveal, then decide for yourself',
      detail:
          'Make a private call before revealing the source answer. The source '
          'is preserved but unverified, so nothing here is ever marked right '
          'or wrong — you decide whether the concept felt clear.',
    ),
    _TourStep(
      icon: Icons.loop_rounded,
      eyebrow: 'THE ORBITS',
      title: 'What you shelve comes back at the right time',
      detail:
          'Mark a concept to revisit and it returns tomorrow, then later and '
          'later as it settles. Mark one as a gem to keep it for its idea.',
    ),
  ];

  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _steps.length - 1) {
      widget.onDismiss();
      return;
    }
    _controller.nextPage(
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: GaussColors.abyss.withValues(alpha: .92),
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The card takes a share of whatever height exists rather than a
          // fixed block, so large text scales shrink it instead of pushing
          // the buttons off screen. The tour scrolls if even that is tight.
          final cardHeight = (constraints.maxHeight * .38).clamp(150.0, 320.0);
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GaussWordmark(width: 150),
                      const SizedBox(height: 6),
                      const Text(
                        'Chart what you are learning.',
                        style: TextStyle(
                          color: GaussColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: cardHeight,
                        child: PageView.builder(
                          controller: _controller,
                          onPageChanged: (index) =>
                              setState(() => _index = index),
                          itemCount: _steps.length,
                          itemBuilder: (context, index) =>
                              _TourCard(step: _steps[index]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var dot = 0; dot < _steps.length; dot++)
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: dot == _index ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dot == _index
                                    ? GaussColors.brassLight
                                    : GaussColors.line,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: widget.onDismiss,
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _next,
                              child: Text(
                                _index == _steps.length - 1
                                    ? 'Start charting'
                                    : 'Next',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _TourStep {
  const _TourStep({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String detail;
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.step});

  final _TourStep step;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${step.eyebrow}. ${step.title}. ${step.detail}',
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GaussColors.panelHigh.withValues(alpha: .96),
            GaussColors.ink.withValues(alpha: .97),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GaussColors.brass.withValues(alpha: .38)),
      ),
      // The card scrolls its own content: at large text scales the title and
      // detail grow past any fixed card height, and clipping copy would be
      // worse than a short scroll.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GaussColors.brass.withValues(alpha: .12),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .45),
                ),
              ),
              child: Icon(step.icon, color: GaussColors.brassLight),
            ),
            const SizedBox(height: 14),
            Text(
              step.eyebrow,
              style: const TextStyle(
                color: GaussColors.brassLight,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(step.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 9),
            Text(
              step.detail,
              style: const TextStyle(
                color: GaussColors.muted,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
