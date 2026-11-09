part of 'map_screen.dart';

class _StudyDock extends StatelessWidget {
  const _StudyDock({
    required this.node,
    required this.studyLabel,
    required this.snapshot,
    required this.missionReady,
    required this.isCurrent,
    required this.onOpen,
  });

  final StudyPathNode node;
  final String studyLabel;
  final StudyTopicSnapshot snapshot;
  final bool missionReady;
  final bool isCurrent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isComplete = snapshot.reflected >= node.questionCount;
    final accessible = MediaQuery.textScalerOf(context).scale(1) >= 1.55;
    final status = isComplete
        ? 'Lesson complete'
        : isCurrent
        ? 'Current mission'
        : 'Selected lesson';
    final visualStatus = accessible
        ? '${isComplete
              ? 'Complete'
              : isCurrent
              ? 'Current'
              : 'Selected'} · ${snapshot.reflected} / ${node.questionCount}'
        : status;
    final accent = isComplete
        ? GaussColors.signalBright
        : isCurrent
        ? GaussColors.brassLight
        : GaussColors.brass;
    return KeyedSubtree(
      key: const ValueKey('map-study-dock'),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: Semantics(
          container: true,
          label:
              '$status. $studyLabel. ${node.topic.label}. '
              '${snapshot.reflected} of ${node.questionCount} questions '
              'charted. Lesson ${node.partIndex + 1} of ${node.partCount}.',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                key: const ValueKey('map-study-dock-main-row'),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: ExcludeSemantics(
                        child: _StudyDockEmblem(
                          topicKey: node.topic.key,
                          isCurrent: isCurrent,
                          isComplete: isComplete,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DecoratedBox(
                      key: const ValueKey('map-study-dock-copy'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GaussColors.deepInk.withValues(alpha: .9),
                            GaussColors.ink.withValues(alpha: .94),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accent.withValues(alpha: .24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GaussColors.abyss.withValues(alpha: .44),
                            blurRadius: 16,
                            spreadRadius: -7,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: KeyedSubtree(
                        key: const ValueKey('map-study-dock-plaque'),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            accessible ? 9 : 7,
                            12,
                            accessible ? 9 : 7,
                          ),
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        visualStatus,
                                        textAlign: TextAlign.center,
                                        softWrap: false,
                                        style: const TextStyle(
                                          color: GaussColors.brassLight,
                                          fontSize: GaussTypeScale.insignia,
                                          height: 1.1,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  studyLabel,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: const TextStyle(
                                    color: GaussColors.ivory,
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                                if (!accessible) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    key: const ValueKey(
                                      'map-study-dock-readings',
                                    ),
                                    children: [
                                      Expanded(
                                        child: _FiveQuestionTrack(
                                          reflected: snapshot.reflected,
                                          complete: isComplete,
                                        ),
                                      ),
                                      if (snapshot.revisit > 0)
                                        const Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            start: 5,
                                          ),
                                          child: Icon(
                                            Icons.bookmark_outline_rounded,
                                            size: 13,
                                            color: GaussColors.signalBright,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: _StudyDockAction(onPressed: onOpen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyDockAction extends StatelessWidget {
  const _StudyDockAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OrbitalActionControl(
    key: const ValueKey('map-study-dock-action'),
    semanticLabel: 'Start five-question mission',
    onPressed: onPressed,
    icon: Icons.rocket_launch_rounded,
    dimension: 48,
  );
}

class _FiveQuestionTrack extends StatelessWidget {
  const _FiveQuestionTrack({required this.reflected, required this.complete});

  final int reflected;
  final bool complete;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < GaussStudyCurriculum.batchSize; index++) ...[
        Expanded(
          child: AnimatedContainer(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            height: 4,
            decoration: BoxDecoration(
              color: index < reflected
                  ? GaussColors.signalBright
                  : complete
                  ? GaussColors.brassLight
                  : GaussColors.hairline,
              borderRadius: BorderRadius.circular(GaussRadii.pill),
            ),
          ),
        ),
        if (index < GaussStudyCurriculum.batchSize - 1)
          const SizedBox(width: 3),
      ],
      const SizedBox(width: 8),
      Text(
        '$reflected / ${GaussStudyCurriculum.batchSize}',
        softWrap: false,
        style: TextStyle(
          color: complete ? GaussColors.signalBright : GaussColors.ivory,
          fontSize: GaussTypeScale.insignia,
          height: 1.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _StudyDockEmblem extends StatelessWidget {
  const _StudyDockEmblem({
    required this.topicKey,
    required this.isCurrent,
    required this.isComplete,
  });

  final String topicKey;
  final bool isCurrent;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final accent = isComplete
        ? GaussColors.signalBright
        : isCurrent
        ? GaussColors.brassLight
        : GaussColors.brass;
    return Container(
      key: const ValueKey('map-study-dock-emblem'),
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: .2),
            GaussColors.deepInk.withValues(alpha: .98),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: .78), width: 1.4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCurrent || isComplete)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .42)),
              ),
            ),
          TopicGlyph(topicKey: topicKey, color: accent, size: 21),
        ],
      ),
    );
  }
}
