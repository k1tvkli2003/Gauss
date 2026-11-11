part of 'study_hub_screen.dart';

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.countLabel,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String countLabel;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('study-library'),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 11),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        // Fill the content width so the heading's left edge aligns
        // with the cards below instead of centering as a narrow block.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: GaussTypeScale.caption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                    countLabel,
                    style: const TextStyle(
                      color: GaussColors.signalBright,
                      fontSize: GaussTypeScale.caption,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                style: const TextStyle(
                  color: GaussColors.muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionAtlas extends StatelessWidget {
  const _SectionAtlas({
    required this.sections,
    required this.controller,
    required this.onOpen,
  });

  final List<StudySectionDefinition> sections;
  final GaussController controller;
  final ValueChanged<StudyPathNode> onOpen;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final window = GaussWindowClass.fromWidth(
            math.max(MediaQuery.sizeOf(context).width, constraints.maxWidth),
          );
          final usePairs =
              window.isExpanded &&
              constraints.maxWidth >= 880 &&
              MediaQuery.textScalerOf(context).scale(GaussTypeScale.body) < 20;
          if (!usePairs) {
            return Column(
              children: [
                for (var index = 0; index < sections.length; index++) ...[
                  if (index > 0) const SizedBox(height: 14),
                  _SectionAtlasCard(
                    key: ValueKey('study-section-${sections[index].id}'),
                    number: index + 1,
                    section: sections[index],
                    controller: controller,
                    onOpen: onOpen,
                  ),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var index = 0; index < sections.length; index += 2) ...[
                if (index > 0) const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SectionAtlasCard(
                        key: ValueKey('study-section-${sections[index].id}'),
                        number: index + 1,
                        section: sections[index],
                        controller: controller,
                        onOpen: onOpen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: index + 1 < sections.length
                          ? _SectionAtlasCard(
                              key: ValueKey(
                                'study-section-${sections[index + 1].id}',
                              ),
                              number: index + 2,
                              section: sections[index + 1],
                              controller: controller,
                              onOpen: onOpen,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _SectionAtlasCard extends StatefulWidget {
  const _SectionAtlasCard({
    super.key,
    required this.number,
    required this.section,
    required this.controller,
    required this.onOpen,
  });

  final int number;
  final StudySectionDefinition section;
  final GaussController controller;
  final ValueChanged<StudyPathNode> onOpen;

  @override
  State<_SectionAtlasCard> createState() => _SectionAtlasCardState();
}

class _SectionAtlasCardState extends State<_SectionAtlasCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final controller = widget.controller;
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    final topics = [
      for (final key in section.topicKeys)
        controller.topics.firstWhere((topic) => topic.key == key),
    ];
    final total = nodes.fold<int>(0, (sum, node) => sum + node.questionCount);
    final reflected = nodes.fold<int>(
      0,
      (sum, node) => sum + controller.study.shelf(node.key).reflected,
    );
    return _StudyGlass(
      radius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            key: ValueKey('study-section-toggle-${section.id}'),
            button: true,
            expanded: _expanded,
            label:
                '${section.title}. $reflected of $total session slots charted.',
            hint: _expanded ? 'Collapse chapter' : 'Open chapter',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final accessibleText =
                              MediaQuery.textScalerOf(
                                context,
                              ).scale(GaussTypeScale.body) >=
                              20;

                          Widget numberBadge() => Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE1AD4C), Color(0xFF8B5713)],
                              ),
                            ),
                            child: Text(
                              '${widget.number}',
                              style: const TextStyle(
                                color: GaussColors.deepInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );

                          Widget titleBlock() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: Theme.of(context).textTheme.titleLarge,
                                textScaler: gaussHeadingScaler(context),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${topics.length} chapters · '
                                '${topics.fold<int>(0, (sum, topic) => sum + controller.subtopics.unitsOf(topic.key).length)} units · '
                                '${nodes.length} lessons',
                                style: const TextStyle(
                                  color: GaussColors.fog,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );

                          Widget chevron() => AnimatedRotation(
                            turns: _expanded ? .5 : 0,
                            duration: GaussMotion.resolve(
                              context,
                              GaussMotion.micro,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: GaussColors.brassLight,
                            ),
                          );

                          final progress = Text(
                            '$reflected/$total',
                            style: const TextStyle(
                              color: GaussColors.signalBright,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          );
                          if (accessibleText || constraints.maxWidth < 360) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // The badge sits above the title so long
                                // words like "mathematics" keep the full
                                // card width instead of breaking mid-word.
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: numberBadge(),
                                ),
                                const SizedBox(height: 10),
                                titleBlock(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    progress,
                                    const Spacer(),
                                    chevron(),
                                  ],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              numberBadge(),
                              const SizedBox(width: 12),
                              Expanded(child: titleBlock()),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [progress, chevron()],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        section.subtitle,
                        style: const TextStyle(
                          color: GaussColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: total == 0 ? 0 : reflected / total,
                          backgroundColor: GaussColors.line,
                          color: GaussColors.signal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final topicNodes = nodes
                      .where((node) => node.topic.key == topic.key)
                      .toList(growable: false);
                  final units = controller.subtopics.unitsOf(topic.key);
                  final charted = units.fold<int>(
                    0,
                    (sum, unit) => sum + controller.unitReflected(unit),
                  );
                  final nextNode = topicNodes.firstWhere(
                    (node) =>
                        controller.study.shelf(node.key).reflected <
                        node.questionCount,
                    orElse: () => topicNodes.last,
                  );
                  return _ChapterRow(
                    key: ValueKey('study-chapter-${topic.key}'),
                    index: index + 1,
                    topic: topic,
                    lessonCount: topicNodes.length,
                    charted: charted,
                    total: topic.questionCount,
                    units: units,
                    controller: controller,
                    onContinue: () => widget.onOpen(nextNode),
                    onOpenUnit: (unit) {
                      final node = controller.lessonForUnit(unit);
                      if (node != null) widget.onOpen(node);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatefulWidget {
  const _ChapterRow({
    super.key,
    required this.index,
    required this.topic,
    required this.lessonCount,
    required this.charted,
    required this.total,
    required this.units,
    required this.controller,
    required this.onContinue,
    required this.onOpenUnit,
  });

  final int index;
  final TopicDescriptor topic;
  final int lessonCount;
  final int charted;
  final int total;
  final List<StudyUnit> units;
  final GaussController controller;
  final VoidCallback onContinue;
  final ValueChanged<StudyUnit> onOpenUnit;

  @override
  State<_ChapterRow> createState() => _ChapterRowState();
}

class _ChapterRowState extends State<_ChapterRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.units.length == 1 ? 'unit' : 'units';
    return Material(
      color: GaussColors.raised.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: _expanded,
                  label:
                      '${widget.topic.label}. ${widget.units.length} $unitLabel, '
                      '${widget.charted} of ${widget.total} questions charted.',
                  hint: _expanded ? 'Hide units' : 'Show units',
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('study-chapter-toggle-${widget.topic.key}'),
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(15),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: GaussMetrics.minTouchTarget,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(11, 10, 4, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 29,
                              height: 29,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: GaussColors.hairline),
                              ),
                              child: Text(
                                '${widget.index}',
                                style: const TextStyle(
                                  color: GaussColors.brassLight,
                                  fontSize: GaussTypeScale.insignia,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      widget.topic.label,
                                      style: const TextStyle(
                                        color: GaussColors.ivory,
                                        fontSize: GaussTypeScale.body,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 2,
                                    children: [
                                      for (final part in [
                                        '${widget.units.length} $unitLabel',
                                        '${widget.lessonCount} lessons',
                                        '${widget.charted}/${widget.total} charted',
                                      ])
                                        Text(
                                          part,
                                          style: const TextStyle(
                                            color: GaussColors.muted,
                                            fontSize: GaussTypeScale.caption,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _expanded ? .5 : 0,
                              duration: GaussMotion.resolve(
                                context,
                                GaussMotion.micro,
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: GaussColors.brassLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('study-chapter-continue-${widget.topic.key}'),
                onPressed: widget.onContinue,
                tooltip: 'Continue this chapter',
                icon: const Icon(Icons.play_arrow_rounded),
                color: GaussColors.brassLight,
                constraints: const BoxConstraints(
                  minWidth: GaussMetrics.minTouchTarget,
                  minHeight: GaussMetrics.minTouchTarget,
                ),
              ),
            ],
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
              child: Column(
                children: [
                  for (final unit in widget.units)
                    _UnitTile(
                      key: ValueKey('study-unit-${unit.key}'),
                      unit: unit,
                      charted: widget.controller.unitReflected(unit),
                      onOpen: () => widget.onOpenUnit(unit),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    super.key,
    required this.unit,
    required this.charted,
    required this.onOpen,
  });

  final StudyUnit unit;
  final int charted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = charted >= unit.questionCount;
    final count = Text(
      '$charted/${unit.questionCount}',
      textAlign: TextAlign.end,
      style: const TextStyle(
        color: GaussColors.fog,
        fontSize: GaussTypeScale.caption,
        fontWeight: FontWeight.w800,
      ),
    );
    final bar = LinearProgressIndicator(
      minHeight: 3,
      value: unit.questionCount == 0 ? 0 : charted / unit.questionCount,
      backgroundColor: GaussColors.line,
      color: GaussColors.signal,
    );
    final label = Text(
      unit.label,
      style: TextStyle(
        color: unit.isMixed ? GaussColors.muted : GaussColors.ivory,
        fontSize: GaussTypeScale.body,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
    return Semantics(
      button: true,
      label:
          '${unit.label}. $charted of ${unit.questionCount} questions charted.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(GaussRadii.small),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: GaussMetrics.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Narrow phones and large text: the whole label gets the full
                // row and the count moves beside the bar, never mid-word.
                final stacked =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) >=
                        GaussComposition.accessibilityTextScale;
                final icon = Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: GaussIconSizes.standard,
                  color: done ? GaussColors.signalBright : GaussColors.fog,
                );
                if (stacked) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: icon,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            label,
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: bar),
                                const SizedBox(width: 10),
                                count,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [label, const SizedBox(height: 4), bar],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Fixed slot so every unit's bar ends at one edge.
                    SizedBox(width: 52, child: count),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyGlass extends StatelessWidget {
  const _StudyGlass({
    super.key,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      GaussSurface(radius: radius, padding: padding, child: child);
}
