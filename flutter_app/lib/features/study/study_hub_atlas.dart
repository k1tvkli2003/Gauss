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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: GaussColors.brassLight,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
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
                              boxShadow: [
                                BoxShadow(
                                  color: GaussColors.brass.withValues(
                                    alpha: .25,
                                  ),
                                  blurRadius: 16,
                                ),
                              ],
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
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${topics.length} micro-lessons · ${nodes.length} sessions',
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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    numberBadge(),
                                    const SizedBox(width: 12),
                                    Expanded(child: titleBlock()),
                                  ],
                                ),
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
                  final topicReflected = topicNodes.fold<int>(
                    0,
                    (sum, node) =>
                        sum + controller.study.shelf(node.key).reflected,
                  );
                  final topicSlots = topicNodes.fold<int>(
                    0,
                    (sum, node) => sum + node.questionCount,
                  );
                  final nextNode = topicNodes.firstWhere(
                    (node) =>
                        controller.study.shelf(node.key).reflected <
                        node.questionCount,
                    orElse: () => topicNodes.last,
                  );
                  return _UnitRow(
                    index: index + 1,
                    topic: topic,
                    sessionCount: topicNodes.length,
                    reflected: topicReflected,
                    totalSlots: topicSlots,
                    onOpen: () => widget.onOpen(nextNode),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.index,
    required this.topic,
    required this.sessionCount,
    required this.reflected,
    required this.totalSlots,
    required this.onOpen,
  });

  final int index;
  final TopicDescriptor topic;
  final int sessionCount;
  final int reflected;
  final int totalSlots;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: GaussColors.raised.withValues(alpha: .62),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: GaussMetrics.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
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
                  '$index',
                  style: const TextStyle(
                    color: GaussColors.brassLight,
                    fontSize: 10,
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
                        topic.label,
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sessionCount sessions · $reflected/$totalSlots slots charted',
                      style: const TextStyle(
                        color: GaussColors.muted,
                        fontSize: GaussTypeScale.insignia,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: GaussColors.brassLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GaussColors.panelHigh.withValues(alpha: .88),
              GaussColors.deepInk.withValues(alpha: .82),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .22)),
        ),
        child: child,
      ),
    ),
  );
}
