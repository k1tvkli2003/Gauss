part of 'study_hub_screen.dart';

class _ContinueInstrument extends StatelessWidget {
  const _ContinueInstrument({
    required this.node,
    required this.snapshot,
    required this.subject,
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.previousSectionTitle,
    required this.nextSectionTitle,
    required this.onPreviousSection,
    required this.onNextSection,
    required this.onOpen,
  });

  final StudyPathNode node;
  final StudyTopicSnapshot snapshot;
  final Subject subject;
  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final String previousSectionTitle;
  final String nextSectionTitle;
  final VoidCallback onPreviousSection;
  final VoidCallback onNextSection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accessibleViewport =
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(1) >=
            _StudyGeometry.accessibleLayoutScale;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _StudyGeometry.contentMaxWidth,
          ),
          child: _StudyGlass(
            key: const ValueKey('study-today'),
            radius: 28,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentSectionAxis(
                  subject: subject,
                  section: section,
                  sectionIndex: sectionIndex,
                  sectionCount: sectionCount,
                  previousSectionTitle: previousSectionTitle,
                  nextSectionTitle: nextSectionTitle,
                  onPrevious: onPreviousSection,
                  onNext: onNextSection,
                ),
                Divider(
                  height: 1,
                  color: GaussColors.brass.withValues(alpha: .2),
                ),
                Padding(
                  padding: EdgeInsets.all(accessibleViewport ? 8 : 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final wide =
                          constraints.maxWidth >= 720 &&
                          textScale < _StudyGeometry.accessibleLayoutScale;
                      final compactHeroRow =
                          constraints.maxWidth >= 330 && textScale < 1.45;
                      final compactAccessible =
                          constraints.maxWidth < 330 &&
                          textScale >= _StudyGeometry.accessibleLayoutScale;
                      final progress = node.questionCount == 0
                          ? 0.0
                          : snapshot.reflected / node.questionCount;
                      final emblem = _OrbitEmblem(
                        dimension: wide
                            ? 126
                            : compactHeroRow
                            ? 72
                            : 84,
                        progress: progress,
                      );
                      final lessonCopy = _CurrentLessonCopy(
                        node: node,
                        centered: !wide && !compactHeroRow,
                      );
                      final lessonProgress = _LessonProgress(
                        reflected: snapshot.reflected,
                        total: node.questionCount,
                      );
                      final continueButton = _ContinueButton(
                        node: node,
                        onOpen: onOpen,
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            emblem,
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  lessonCopy,
                                  const SizedBox(height: 14),
                                  lessonProgress,
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(width: 120, child: continueButton),
                          ],
                        );
                      }

                      if (compactAccessible) {
                        return Column(
                          key: const ValueKey(
                            'study-accessible-current-mission',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            lessonCopy,
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: lessonProgress),
                                const SizedBox(width: 12),
                                continueButton,
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (compactHeroRow)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                emblem,
                                const SizedBox(width: 14),
                                Expanded(child: lessonCopy),
                                const SizedBox(width: 8),
                                continueButton,
                              ],
                            )
                          else ...[
                            Center(child: emblem),
                            const SizedBox(height: 12),
                            lessonCopy,
                          ],
                          const SizedBox(height: 10),
                          lessonProgress,
                          if (!compactHeroRow) ...[
                            const SizedBox(height: 12),
                            continueButton,
                          ],
                        ],
                      );
                    },
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

class _CurrentSectionAxis extends StatelessWidget {
  const _CurrentSectionAxis({
    required this.subject,
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.previousSectionTitle,
    required this.nextSectionTitle,
    required this.onPrevious,
    required this.onNext,
  });

  final Subject subject;
  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final String previousSectionTitle;
  final String nextSectionTitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        '${_subjectTitle(subject)} course. Current chapter ${sectionIndex + 1} of $sectionCount, ${section.title}.',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final reflowNavigation =
              textScale >= _StudyGeometry.accessibleLayoutScale;
          final previous = SizedBox.square(
            dimension: _StudyGeometry.controlTrack,
            child: IconButton.outlined(
              key: const ValueKey('study-previous-section'),
              onPressed: onPrevious,
              tooltip: 'Previous chapter: $previousSectionTitle',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          );
          final next = SizedBox.square(
            dimension: _StudyGeometry.controlTrack,
            child: IconButton.outlined(
              key: const ValueKey('study-next-section'),
              onPressed: onNext,
              tooltip: 'Next chapter: $nextSectionTitle',
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          );
          final sectionTitle = ExcludeSemantics(
            key: const ValueKey('study-current-section-title'),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 1,
              children: [
                for (final word in section.title.split(' '))
                  Text(
                    word,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: GaussColors.ivory,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          );
          final sectionLabel = Column(
            key: const ValueKey('study-current-section-label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                runSpacing: 1,
                children: [
                  Text(
                    '${_subjectTitle(subject)} course',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'chapter ${sectionIndex + 1} of $sectionCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.insignia,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              sectionTitle,
            ],
          );
          final responsiveSectionLabel = reflowNavigation
              ? Column(
                  key: const ValueKey('study-current-section-label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.2,
                      child: Text(
                        '${_subjectTitle(subject)} · Chapter ${sectionIndex + 1}/$sectionCount',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: GaussTypeScale.insignia,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.35,
                      child: sectionTitle,
                    ),
                  ],
                )
              : sectionLabel;

          if (reflowNavigation) {
            return Column(
              key: const ValueKey('study-current-section-axis'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                responsiveSectionLabel,
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    previous,
                    const SizedBox(width: 16),
                    Container(
                      width: _StudyGeometry.controlTrack,
                      height: _StudyGeometry.controlTrack,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GaussColors.raised.withValues(alpha: .5),
                        border: Border.all(color: GaussColors.hairline),
                      ),
                      child: const TheoremStarMark(size: 24),
                    ),
                    const SizedBox(width: 16),
                    next,
                  ],
                ),
              ],
            );
          }

          return Row(
            key: const ValueKey('study-current-section-axis'),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              previous,
              const SizedBox(width: 8),
              Expanded(child: responsiveSectionLabel),
              const SizedBox(width: 8),
              next,
            ],
          );
        },
      ),
    ),
  );
}

class _CurrentLessonCopy extends StatelessWidget {
  const _CurrentLessonCopy({required this.node, required this.centered});

  final StudyPathNode node;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final accessible =
        MediaQuery.textScalerOf(context).scale(1) >=
        _StudyGeometry.accessibleLayoutScale;
    final title = Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        node.topic.label,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    if (accessible) {
      return Semantics(
        key: const ValueKey('study-current-lesson-copy'),
        label:
            'Current study. ${node.topic.label}. Micro-lesson ${node.partIndex + 1} of ${node.partCount}.',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                'Current study · Lesson ${node.partIndex + 1}/${node.partCount}',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: GaussTypeScale.caption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
            ),
            const SizedBox(height: 3),
            title,
          ],
        ),
      );
    }
    return Column(
      key: const ValueKey('study-current-lesson-copy'),
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Current study',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GaussColors.brassLight,
            fontSize: GaussTypeScale.caption,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 3),
        title,
        const SizedBox(height: 3),
        Text(
          'Micro-lesson ${node.partIndex + 1} of ${node.partCount}',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(color: GaussColors.fog, fontSize: 12),
        ),
      ],
    );
  }
}

class _LessonProgress extends StatelessWidget {
  const _LessonProgress({required this.reflected, required this.total});

  final int reflected;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$reflected of $total questions charted in this micro-lesson.',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final reflow =
              constraints.maxWidth < 130 ||
              textScale >= _StudyGeometry.accessibleLayoutScale;
          Widget segments() => Row(
            children: [
              for (var index = 0; index < total; index++) ...[
                if (index > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: GaussMotion.resolve(
                      context,
                      GaussMotion.standard,
                    ),
                    height: 6,
                    decoration: BoxDecoration(
                      color: index < reflected
                          ? GaussColors.signalBright
                          : GaussColors.line,
                      borderRadius: BorderRadius.circular(GaussRadii.pill),
                    ),
                  ),
                ),
              ],
            ],
          );
          final counter = MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.35,
            child: Text(
              '$reflected / $total',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GaussColors.signalBright,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
          if (reflow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [segments(), const SizedBox(height: 5), counter],
            );
          }
          return Row(
            children: [
              Expanded(child: segments()),
              const SizedBox(width: 10),
              counter,
            ],
          );
        },
      ),
    ),
  );
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.node, required this.onOpen});

  final StudyPathNode node;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.35,
    child: Center(
      child: OrbitalActionControl(
        key: const ValueKey('study-primary-continue'),
        semanticLabel: 'Continue ${node.topic.label}, ${_sessionLabel(node)}',
        caption: 'Next 5',
        onPressed: onOpen,
        icon: Icons.play_arrow_rounded,
        dimension: 58,
      ),
    ),
  );
}

class _OrbitEmblem extends StatelessWidget {
  const _OrbitEmblem({required this.progress, this.dimension = 126});
  final double progress;
  final double dimension;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: dimension - 10,
          child: CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: GaussColors.line,
            color: GaussColors.brass,
          ),
        ),
        Container(
          width: dimension * .7,
          height: dimension * .7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF17353A), GaussColors.deepInk],
            ),
            border: Border.all(color: GaussColors.brass, width: 2),
            boxShadow: [
              BoxShadow(
                color: GaussColors.brass.withValues(alpha: .18),
                blurRadius: 24,
              ),
            ],
          ),
          child: Center(child: TheoremStarMark(size: dimension * .44)),
        ),
      ],
    ),
  );
}
