part of 'map_screen.dart';

class _OrbitSelector extends StatelessWidget {
  const _OrbitSelector({
    required this.section,
    required this.sectionIndex,
    required this.sectionCount,
    required this.reflected,
    required this.total,
    required this.activeTopic,
    required this.chapterIndex,
    required this.chapterReflected,
    required this.compact,
    required this.onPressed,
  });

  final StudySectionDefinition section;
  final int sectionIndex;
  final int sectionCount;
  final int reflected;
  final int total;
  final TopicDescriptor activeTopic;
  final int chapterIndex;
  final int chapterReflected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reflowCompact =
        compact && (media.size.width < 360 || media.textScaler.scale(1) > 1.35);
    final orbitTitleStyle = TextStyle(
      color: GaussColors.ivory,
      fontSize: compact ? 13 : 14,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );
    final orbitTitle = reflowCompact
        ? ExcludeSemantics(
            child: Wrap(
              key: const ValueKey('map-active-orbit-title'),
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 6,
              children: [
                for (final word in section.title.split(' '))
                  Text(
                    word,
                    maxLines: 1,
                    softWrap: false,
                    style: orbitTitleStyle,
                  ),
              ],
            ),
          )
        : Text(
            key: const ValueKey('map-active-orbit-title'),
            section.title,
            softWrap: true,
            style: orbitTitleStyle,
          );
    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current orbit · $sectionIndex of $sectionCount',
          style: const TextStyle(
            color: GaussColors.brassLight,
            fontSize: GaussTypeScale.caption,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 2),
        orbitTitle,
      ],
    );
    final reading = Text(
      '$reflected / $total',
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        color: GaussColors.signalBright,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
    final centeredChapter = Container(
      key: const ValueKey('map-active-chapter-summary'),
      width: double.infinity,
      alignment: Alignment.center,
      // Course, chapter, and reading used to become two nested vertical
      // stacks. A single adaptive constellation line keeps the same complete
      // identity while returning the route to the first viewport. Wrap is
      // intentional: 320dp/200% gets a calm second line, never clipped copy.
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          Text(
            'Chapter $chapterIndex',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: GaussColors.brassLight,
              fontSize: GaussTypeScale.insignia,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: GaussColors.brass,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            activeTopic.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GaussColors.ivory,
              fontSize: compact ? 10.5 : 12,
              height: 1.16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$chapterReflected / ${activeTopic.questionCount}',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: GaussColors.signalBright,
              fontSize: GaussTypeScale.insignia,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
    final centeredCompactIdentity = Column(
      key: const ValueKey('map-orbit-center-axis'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Orbit $sectionIndex  ·  $reflected / $total',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            color: GaussColors.brassLight,
            fontSize: GaussTypeScale.caption,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 2),
        orbitTitle,
        const SizedBox(height: 3),
        centeredChapter,
      ],
    );
    return Semantics(
      button: true,
      label:
          'Current orbit $sectionIndex of $sectionCount. ${section.title}. '
          'Chapter $chapterIndex, ${activeTopic.label}. '
          '$chapterReflected of ${activeTopic.questionCount} chapter questions charted. '
          '$reflected of $total orbit questions charted.',
      hint: 'Double tap to choose another orbit.',
      child: InkWell(
        key: const ValueKey('map-orbit-selector'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: GaussMetrics.minTouchTarget,
          ),
          padding: EdgeInsets.fromLTRB(
            8,
            reflowCompact ? 6 : 6,
            8,
            reflowCompact ? 6 : 6,
          ),
          decoration: BoxDecoration(
            color: GaussColors.deepInk.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .34)),
          ),
          child: compact
              ? MediaQuery.withClampedTextScaling(
                  // This is a map instrument, not reading content. Keep the
                  // complete phrases live and unbroken while capping their
                  // scale so the selected chapter cannot consume the route.
                  maxScaleFactor: reflowCompact ? 1.45 : 1.55,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Center(
                          child: _OrbitIndexRing(value: sectionIndex),
                        ),
                      ),
                      Expanded(child: centeredCompactIdentity),
                      const SizedBox(
                        width: 48,
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: GaussColors.fog,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    _OrbitIndexRing(value: sectionIndex),
                    const SizedBox(width: 10),
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        reading,
                        const SizedBox(height: 1),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: GaussColors.fog,
                          size: 15,
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

class _OrbitIndexRing extends StatelessWidget {
  const _OrbitIndexRing({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: GaussColors.abyss.withValues(alpha: .8),
      border: Border.all(
        color: GaussColors.signalBright.withValues(alpha: .72),
        width: 1.6,
      ),
    ),
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: Text(
        '$value',
        style: const TextStyle(
          color: GaussColors.ivory,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _OrbitNavigator extends StatefulWidget {
  const _OrbitNavigator({
    required this.controller,
    required this.initialSubject,
    required this.initialSection,
    required this.lastSectionBySubject,
    required this.onContinue,
  });

  final GaussController controller;
  final Subject initialSubject;
  final StudySectionDefinition initialSection;
  final Map<Subject, String> lastSectionBySubject;
  final void Function(Subject, StudySectionDefinition, {String? topicKey})
  onContinue;

  @override
  State<_OrbitNavigator> createState() => _OrbitNavigatorState();
}

class _OrbitNavigatorState extends State<_OrbitNavigator> {
  late Subject _subject;
  late String _sectionId;

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
    _sectionId = widget.initialSection.id;
  }

  List<StudySectionDefinition> get _sections =>
      GaussStudyCurriculum.forSubject(_subject);

  StudySectionDefinition get _section => _sections.firstWhere(
    (item) => item.id == _sectionId,
    orElse: () => _sections.first,
  );

  void _selectSubject(Subject subject) {
    if (_subject == subject) return;
    final sections = GaussStudyCurriculum.forSubject(subject);
    final restored = sections.firstWhere(
      (item) => item.id == widget.lastSectionBySubject[subject],
      orElse: () => sections.first,
    );
    setState(() {
      _subject = subject;
      _sectionId = restored.id;
    });
  }

  void _selectSection(StudySectionDefinition section) {
    if (_sectionId == section.id) return;
    setState(() => _sectionId = section.id);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final selectedIndex = sections.indexWhere((item) => item.id == _section.id);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.55;
    final courseName = _subject == Subject.math
        ? (largeText ? 'Math' : 'Mathematics')
        : 'Physics';
    return KeyedSubtree(
      key: const ValueKey('orbit-navigator'),
      child: _GlassFrame(
        radius: 30,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GaussColors.fog.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(GaussRadii.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: GaussSpacing.space8),
                    Row(
                      key: const ValueKey('orbit-navigator-header'),
                      children: [
                        const TheoremStarMark(size: 34),
                        const SizedBox(width: GaussSpacing.space8),
                        Expanded(
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Orbit navigator',
                                  style: TextStyle(
                                    color: GaussColors.brassLight,
                                    fontSize: GaussTypeScale.caption,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  key: const ValueKey(
                                    'orbit-navigator-course-summary',
                                  ),
                                  '$courseName  ·  ${sections.fold<int>(0, (sum, part) => sum + part.topicKeys.length)} chapters',
                                  style: const TextStyle(
                                    color: GaussColors.fog,
                                    fontSize: GaussTypeScale.caption,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .2,
                                  ),
                                ),
                                const SizedBox(height: GaussSpacing.optical2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: GaussSpacing.space4),
                        IconButton(
                          key: const ValueKey('orbit-navigator-close'),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close Orbit Navigator',
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: GaussSpacing.space8),
                    Center(
                      child: _OrbitCourseSwitch(
                        subject: _subject,
                        compact: largeText,
                        onSubject: _selectSubject,
                      ),
                    ),
                    const SizedBox(height: GaussSpacing.space12),
                    _OrbitChapterConstellation(
                      controller: widget.controller,
                      sections: sections,
                      selectedIndex: selectedIndex,
                      onSelected: _selectSection,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GaussSpacing.space8),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  key: const ValueKey('orbit-navigator-chapter-list'),
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 18),
                  child: AnimatedSwitcher(
                    duration: GaussMotion.resolve(
                      context,
                      GaussMotion.standard,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.025, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey('orbit-preview-${_section.id}'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OrbitChapterPreview(
                          controller: widget.controller,
                          section: _section,
                          index: selectedIndex,
                          sectionCount: sections.length,
                          onContinue: () =>
                              widget.onContinue(_subject, _section),
                        ),
                        const SizedBox(height: GaussSpacing.space12),
                        _OrbitChapterList(
                          controller: widget.controller,
                          section: _section,
                          onOpen: (topicKey) => widget.onContinue(
                            _subject,
                            _section,
                            topicKey: topicKey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitCourseSwitch extends StatelessWidget {
  const _OrbitCourseSwitch({
    required this.subject,
    required this.compact,
    required this.onSubject,
  });

  final Subject subject;
  final bool compact;
  final ValueChanged<Subject> onSubject;

  @override
  Widget build(BuildContext context) => _SubjectSwitch(
    controlKey: const ValueKey('orbit-navigator-course-switch'),
    subject: subject,
    compact: compact,
    onSubject: onSubject,
  );
}

class _OrbitChapterConstellation extends StatelessWidget {
  const _OrbitChapterConstellation({
    required this.controller,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  final GaussController controller;
  final List<StudySectionDefinition> sections;
  final int selectedIndex;
  final ValueChanged<StudySectionDefinition> onSelected;

  double _progressFor(StudySectionDefinition section) {
    final total = section.topicKeys.fold<int>(
      0,
      (sum, key) =>
          sum +
          controller.topics
              .firstWhere((topic) => topic.key == key)
              .questionCount,
    );
    if (total == 0) return 0;
    final reflected = section.topicKeys.fold<int>(
      0,
      (sum, key) => sum + controller.study.topic(key).reflected,
    );
    return (reflected / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = sections.map(_progressFor).toList(growable: false);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Chapter constellation',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const beaconWidth = 48.0;
              final gaps = math.max(0, sections.length - 1);
              final rawGap = gaps == 0
                  ? 0.0
                  : (constraints.maxWidth - sections.length * beaconWidth) /
                        gaps;
              final gap = rawGap.clamp(8.0, 30.0);
              final contentWidth = sections.length * beaconWidth + gaps * gap;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(constraints.maxWidth, contentWidth),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < sections.length;
                            index++
                          ) ...[
                            if (index > 0)
                              SizedBox(
                                width: gap,
                                child: _OrbitChapterLink(
                                  active: index <= selectedIndex,
                                  complete: progress[index - 1] >= .999,
                                ),
                              ),
                            _OrbitChapterBeacon(
                              key: ValueKey(
                                'orbit-chapter-${sections[index].id}',
                              ),
                              index: index,
                              title: sections[index].title,
                              progress: progress[index],
                              selected: index == selectedIndex,
                              onPressed: () => onSelected(sections[index]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: GaussSpacing.space8),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: Text(
              'Orbit ${selectedIndex + 1} of ${sections.length}',
              textAlign: TextAlign.center,
              softWrap: false,
              style: const TextStyle(
                color: GaussColors.fog,
                fontSize: GaussTypeScale.caption,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitChapterLink extends StatelessWidget {
  const _OrbitChapterLink({required this.active, required this.complete});

  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? GaussColors.signalBright
        : active
        ? GaussColors.brassLight
        : GaussColors.hairline;
    return AnimatedContainer(
      key: const ValueKey('orbit-chapter-link'),
      duration: GaussMotion.resolve(context, GaussMotion.micro),
      height: active ? 2 : 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: active ? .26 : .5),
            color.withValues(alpha: active ? .9 : .5),
          ],
        ),
      ),
    );
  }
}

class _OrbitChapterBeacon extends StatelessWidget {
  const _OrbitChapterBeacon({
    required this.index,
    required this.title,
    required this.progress,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final int index;
  final String title;
  final double progress;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? GaussColors.brassLight
        : progress >= .999
        ? GaussColors.signalBright
        : GaussColors.fog;
    return Tooltip(
      message: 'Orbit ${index + 1}: $title',
      child: Semantics(
        button: true,
        selected: selected,
        label:
            'Orbit ${index + 1}. $title. ${(progress * 100).round()} percent charted.',
        child: AnimatedScale(
          duration: GaussMotion.resolve(context, GaussMotion.micro),
          scale: selected ? 1.08 : 1,
          curve: Curves.easeOutCubic,
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: selected ? 2.4 : 1.8,
                  color: accent,
                  backgroundColor: GaussColors.hairline.withValues(alpha: .46),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkResponse(
                      onTap: onPressed,
                      containedInkWell: true,
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: GaussMotion.resolve(
                          context,
                          GaussMotion.micro,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected
                              ? RadialGradient(
                                  center: const Alignment(-.28, -.35),
                                  colors: [
                                    GaussColors.brassLight.withValues(
                                      alpha: .34,
                                    ),
                                    GaussColors.brass.withValues(alpha: .13),
                                    GaussColors.deepInk.withValues(alpha: .9),
                                  ],
                                  stops: const [0, .55, 1],
                                )
                              : null,
                          color: selected
                              ? null
                              : GaussColors.deepInk.withValues(alpha: .72),
                          border: Border.all(
                            color: accent.withValues(
                              alpha: selected ? .82 : .34,
                            ),
                          ),
                        ),
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: selected
                                  ? GaussColors.ivory
                                  : GaussColors.fog,
                              fontSize: GaussTypeScale.metadata,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _OrbitChapterPreview extends StatelessWidget {
  const _OrbitChapterPreview({
    required this.controller,
    required this.section,
    required this.index,
    required this.sectionCount,
    required this.onContinue,
  });

  final GaussController controller;
  final StudySectionDefinition section;
  final int index;
  final int sectionCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    var currentIndex = nodes.indexWhere(
      (node) => controller.study.shelf(node.key).reflected < node.questionCount,
    );
    if (currentIndex < 0) currentIndex = nodes.length - 1;
    final currentNode = nodes[currentIndex];
    final currentSnapshot = controller.study.shelf(currentNode.key);
    final total = section.topicKeys.fold<int>(
      0,
      (sum, key) =>
          sum +
          controller.topics
              .firstWhere((topic) => topic.key == key)
              .questionCount,
    );
    final reflected = section.topicKeys.fold<int>(
      0,
      (sum, key) => sum + controller.study.topic(key).reflected,
    );
    final progress = total == 0 ? 0.0 : reflected / total;
    final complete = total > 0 && reflected >= total;
    final nextLabel = complete ? 'Mastery review' : 'Next five questions';
    final actionLabel = complete
        ? 'Open orbit ${index + 1} mastery review'
        : 'Continue orbit ${index + 1} at lesson ${currentIndex + 1}';

    return Semantics(
      container: true,
      label:
          'Orbit ${index + 1} of $sectionCount. ${section.title}. $reflected of $total charted. Current lesson ${currentIndex + 1} of ${nodes.length}.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GaussColors.brass.withValues(alpha: .12),
              GaussColors.deepInk.withValues(alpha: .66),
              GaussColors.ink.withValues(alpha: .82),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
              color: GaussColors.abyss.withValues(alpha: .46),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(GaussSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrbitIndexRing(value: index + 1),
                  const SizedBox(width: GaussSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.4,
                          child: Text(
                            'Orbit ${index + 1}  ·  ${(progress * 100).round()}% charted',
                            style: const TextStyle(
                              color: GaussColors.brassLight,
                              fontSize: GaussTypeScale.caption,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                        const SizedBox(height: GaussSpacing.space4),
                        // Capped so the longest word of a part title
                        // ("foundations") never breaks mid-word at 200%.
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.45,
                          child: Text(
                            section.title,
                            style: const TextStyle(
                              color: GaussColors.ivory,
                              fontSize: GaussTypeScale.title,
                              fontWeight: FontWeight.w900,
                              height: 1.16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GaussSpacing.space8),
              Text(
                section.subtitle,
                style: const TextStyle(
                  color: GaussColors.muted,
                  fontSize: GaussTypeScale.caption,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: GaussSpacing.space12),
              ClipRRect(
                borderRadius: BorderRadius.circular(GaussRadii.pill),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  color: complete
                      ? GaussColors.signalBright
                      : GaussColors.brassLight,
                  backgroundColor: GaussColors.abyss.withValues(alpha: .8),
                ),
              ),
              const SizedBox(height: GaussSpacing.space16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GaussColors.abyss.withValues(alpha: .52),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: GaussColors.hairline.withValues(alpha: .8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.4,
                              child: Text(
                                '$nextLabel  ·  ${currentIndex + 1} / ${nodes.length}',
                                softWrap: true,
                                style: const TextStyle(
                                  color: GaussColors.signalBright,
                                  fontSize: GaussTypeScale.caption,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .2,
                                ),
                              ),
                            ),
                            const SizedBox(height: GaussSpacing.space4),
                            Directionality(
                              textDirection:
                                  _usesRtlScript(currentNode.topic.label)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: Text(
                                currentNode.topic.label,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: GaussColors.ivory,
                                  fontSize: GaussTypeScale.body,
                                  fontWeight: FontWeight.w900,
                                  height: 1.24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${currentSnapshot.reflected} / ${currentNode.questionCount} charted',
                              softWrap: false,
                              style: const TextStyle(
                                color: GaussColors.fog,
                                fontSize: GaussTypeScale.insignia,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: GaussSpacing.space8),
                      OrbitalActionControl(
                        key: const ValueKey('orbit-navigator-continue'),
                        semanticLabel: actionLabel,
                        onPressed: onContinue,
                        icon: complete
                            ? Icons.replay_rounded
                            : Icons.arrow_forward_rounded,
                        dimension: 56,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectSwitch extends StatelessWidget {
  const _SubjectSwitch({
    required this.subject,
    required this.onSubject,
    required this.compact,
    this.controlKey = const ValueKey('map-subject-dual-orbit'),
  });

  final Subject subject;
  final ValueChanged<Subject> onSubject;
  final bool compact;
  final Key controlKey;

  @override
  Widget build(BuildContext context) {
    final mathSelected = subject == Subject.math;
    return Semantics(
      container: true,
      label: 'Study path subject',
      child: SizedBox(
        key: controlKey,
        width: compact ? 100 : 178,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SubjectOrbitButton(
                    subject: Subject.math,
                    semanticLabel: 'Mathematics study path',
                    selected: mathSelected,
                    compact: compact,
                    key: const ValueKey('map-subject-math'),
                    onPressed: () => onSubject(Subject.math),
                  ),
                ),
                SizedBox(width: compact ? 4 : 8),
                Expanded(
                  child: _SubjectOrbitButton(
                    subject: Subject.physics,
                    semanticLabel: 'Physics study path',
                    selected: !mathSelected,
                    compact: compact,
                    key: const ValueKey('map-subject-physics'),
                    onPressed: () => onSubject(Subject.physics),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectOrbitButton extends StatelessWidget {
  const _SubjectOrbitButton({
    required this.subject,
    required this.semanticLabel,
    required this.selected,
    required this.compact,
    required this.onPressed,
    super.key,
  });

  final Subject subject;
  final String semanticLabel;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = subject == Subject.math
        ? GaussColors.brassLight
        : GaussColors.ice;
    final label = subject == Subject.math ? 'Math' : 'Physics';
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        container: true,
        label: semanticLabel,
        button: true,
        selected: selected,
        child: InkResponse(
          onTap: onPressed,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          radius: compact ? 28 : 36,
          child: AnimatedContainer(
            duration: GaussMotion.resolve(context, GaussMotion.micro),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minWidth: GaussMetrics.minTouchTarget,
              minHeight: GaussMetrics.minTouchTarget,
            ),
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 6),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: .15)
                  : GaussColors.deepInk.withValues(alpha: .56),
              borderRadius: BorderRadius.circular(compact ? 26 : 18),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: .92)
                    : GaussColors.hairline.withValues(alpha: .78),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SubjectGlyph(subject: subject, color: accent, size: 21),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        softWrap: false,
                        style: TextStyle(
                          color: selected ? GaussColors.ivory : GaussColors.fog,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every chapter of the selected part as a direct jump target, so any of the
/// 29 chapters is two taps from the Map: open the navigator, pick the chapter.
class _OrbitChapterList extends StatelessWidget {
  const _OrbitChapterList({
    required this.controller,
    required this.section,
    required this.onOpen,
  });

  final GaussController controller;
  final StudySectionDefinition section;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final topics = [
      for (final key in section.topicKeys)
        controller.topics.firstWhere((topic) => topic.key == key),
    ];
    return Column(
      key: const ValueKey('orbit-navigator-chapters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            'Jump to a chapter',
            style: TextStyle(
              color: GaussColors.brassLight,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
        for (var i = 0; i < topics.length; i++)
          _OrbitChapterRow(
            key: ValueKey('orbit-chapter-${topics[i].key}'),
            number: i + 1,
            topic: topics[i],
            units: controller.subtopics.unitsOf(topics[i].key).length,
            charted: controller.study.topic(topics[i].key).reflected,
            onTap: () => onOpen(topics[i].key),
          ),
      ],
    );
  }
}

class _OrbitChapterRow extends StatelessWidget {
  const _OrbitChapterRow({
    super.key,
    required this.number,
    required this.topic,
    required this.units,
    required this.charted,
    required this.onTap,
  });

  final int number;
  final TopicDescriptor topic;
  final int units;
  final int charted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = topic.questionCount;
    final detail =
        '$units ${units == 1 ? 'unit' : 'units'} · $charted/$total charted';
    return Semantics(
      button: true,
      label:
          'Chapter $number. ${topic.label}. $detail. Opens its first uncharted lesson.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GaussRadii.small),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: GaussMetrics.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '$number',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.brassLight,
                      fontSize: GaussTypeScale.caption,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.label,
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontSize: GaussTypeScale.body,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: GaussTypeScale.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GaussColors.brassLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
