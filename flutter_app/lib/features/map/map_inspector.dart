part of 'map_screen.dart';

class _StudyInspector extends StatelessWidget {
  const _StudyInspector({
    required this.section,
    required this.node,
    required this.upcoming,
    required this.snapshot,
    required this.topicSnapshot,
    required this.missionReady,
    required this.onOpen,
  });

  final StudySectionDefinition section;
  final StudyPathNode node;

  /// The next lessons on this route, from real path data.
  final List<({String title, int charted, int total})> upcoming;
  final StudyTopicSnapshot snapshot;
  final StudyTopicSnapshot topicSnapshot;
  final bool missionReady;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.reflected / node.questionCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: _GlassFrame(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
        child: SafeArea(
          left: false,
          // Scrolls on short landscape windows and at large text instead of
          // overflowing the panel.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Study inspector',
                  style: TextStyle(
                    color: GaussColors.brassLight,
                    fontSize: GaussTypeScale.caption,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.title,
                  style: const TextStyle(color: GaussColors.fog, fontSize: 11),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GaussColors.deepInk,
                        shape: BoxShape.circle,
                        border: Border.all(color: GaussColors.brass),
                      ),
                      child: TopicGlyph(
                        topicKey: node.topic.key,
                        color: GaussColors.brassLight,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit · ${node.setLabel}',
                            style: const TextStyle(
                              color: GaussColors.fog,
                              fontSize: GaussTypeScale.caption,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            node.topic.label,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProgressReading(
                  label: 'This study set',
                  value: snapshot.reflected,
                  total: node.questionCount,
                  progress: progress,
                ),
                const SizedBox(height: 12),
                _ProgressReading(
                  label: 'Whole unit',
                  value: topicSnapshot.reflected,
                  total: node.topic.questionCount,
                  progress: topicSnapshot.reflected / node.topic.questionCount,
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  GaussSurface(
                    tone: GaussSurfaceTone.inset,
                    radius: 18,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Next in this route',
                          style: TextStyle(
                            color: GaussColors.brassLight,
                            fontSize: GaussTypeScale.caption,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final lesson in upcoming)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      color: GaussColors.ivory,
                                      fontSize: GaussTypeScale.body,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${lesson.charted} / ${lesson.total}',
                                  style: const TextStyle(
                                    color: GaussColors.fog,
                                    fontSize: GaussTypeScale.caption,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                // The action follows the lesson it starts; pinning it to the
                // panel's foot left a dead band on tall tablets.
                const SizedBox(height: GaussSpacing.space24),
                if (snapshot.revisit > 0) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.bookmark_outline_rounded,
                        color: GaussColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${snapshot.revisit} ${snapshot.revisit == 1 ? 'question is' : 'questions are'} waiting for another pass.',
                          style: const TextStyle(
                            color: GaussColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Center(
                  child: OrbitalActionControl(
                    key: const ValueKey('map-study-inspector-action'),
                    semanticLabel: 'Start five-question mission',
                    caption: 'Start 5',
                    onPressed: onOpen,
                    icon: Icons.rocket_launch_rounded,
                    dimension: 62,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  missionReady
                      ? 'Five questions are ready. Reviewed evidence remains attached where available.'
                      : 'Five source questions are available for private practice. Report anything that needs repair.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: GaussTypeScale.caption,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressReading extends StatelessWidget {
  const _ProgressReading({
    required this.label,
    required this.value,
    required this.total,
    required this.progress,
  });

  final String label;
  final int value;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: GaussColors.muted, fontSize: 11),
            ),
          ),
          Text(
            '$value / $total',
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 8,
        ),
      ),
    ],
  );
}

class _JumpToCurrentButton extends StatelessWidget {
  const _JumpToCurrentButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Return to current set',
    child: Semantics(
      button: true,
      label: 'Return to the next uncharted study set',
      child: _GlassFrame(
        radius: GaussRadii.pill,
        padding: EdgeInsets.zero,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.my_location_rounded),
          color: GaussColors.brassLight,
        ),
      ),
    ),
  );
}

class _GlassFrame extends StatelessWidget {
  const _GlassFrame({
    required this.child,
    required this.padding,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF20A171C), Color(0xF50D2025)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: GaussColors.brass.withValues(alpha: .28)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x8A000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}
