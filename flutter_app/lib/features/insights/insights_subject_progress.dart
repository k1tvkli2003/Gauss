part of 'insights_screen.dart';

class _SubjectProgressAtlas extends StatelessWidget {
  const _SubjectProgressAtlas({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              for (final subject in Subject.values)
                _SubjectProgressCard(subject: subject, controller: controller),
            ];
            if (constraints.maxWidth < 760) {
              return Column(
                children: [cards[0], const SizedBox(height: 11), cards[1]],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _SubjectProgressCard extends StatelessWidget {
  const _SubjectProgressCard({required this.subject, required this.controller});

  final Subject subject;
  final GaussController controller;

  @override
  Widget build(BuildContext context) {
    final sections = GaussStudyCurriculum.forSubject(subject);
    final nodes = [
      for (final section in sections)
        ...GaussStudyCurriculum.nodesFor(section, controller.topics),
    ];
    final total = nodes.fold<int>(0, (sum, node) => sum + node.questionCount);
    final reflected = nodes.fold<int>(
      0,
      (sum, node) => sum + controller.study.shelf(node.key).reflected,
    );
    final accent = subject == Subject.math
        ? GaussColors.brassLight
        : const Color(0xFF68C8C0);
    return _GlassPanel(
      radius: 23,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .11),
                  border: Border.all(color: accent.withValues(alpha: .42)),
                ),
                child: Center(
                  child: SubjectGlyph(subject: subject, color: accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject == Subject.math ? 'Mathematics' : 'Physics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$reflected of ${_formatCount(total)} charted',
                      style: const TextStyle(
                        color: GaussColors.fog,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                total == 0 ? '0%' : '${(reflected * 100 / total).round()}%',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 15),
          for (var index = 0; index < sections.length; index++) ...[
            _SectionProgressRow(
              number: index + 1,
              section: sections[index],
              controller: controller,
              accent: accent,
            ),
            if (index < sections.length - 1) const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _SectionProgressRow extends StatelessWidget {
  const _SectionProgressRow({
    required this.number,
    required this.section,
    required this.controller,
    required this.accent,
  });

  final int number;
  final StudySectionDefinition section;
  final GaussController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final nodes = GaussStudyCurriculum.nodesFor(section, controller.topics);
    final total = nodes.fold<int>(0, (sum, node) => sum + node.questionCount);
    final reflected = nodes.fold<int>(
      0,
      (sum, node) => sum + controller.study.shelf(node.key).reflected,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$number',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            Text(
              '$reflected/$total',
              style: const TextStyle(
                color: GaussColors.muted,
                fontSize: GaussTypeScale.insignia,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: total == 0 ? 0 : reflected / total,
            backgroundColor: GaussColors.line,
            color: accent,
          ),
        ),
      ],
    );
  }
}
