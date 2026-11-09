part of 'insights_screen.dart';

class _ActivityStarChart extends StatelessWidget {
  const _ActivityStarChart({required this.heatmap});

  final Map<String, int> heatmap;

  String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      28,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 27 - index)),
    );
    final maxValue = math.max(
      1,
      days.fold<int>(
        0,
        (value, day) => math.max(value, heatmap[_key(day)] ?? 0),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: _GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final compact =
                        constraints.maxWidth < 360 || textScale > 1.35;
                    final titleText = Text(
                      'Last 28 days',
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                    const qualifier = Text(
                      'first reflections only',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GaussColors.muted,
                        fontSize: GaussTypeScale.insignia,
                      ),
                    );
                    if (compact) {
                      return Center(
                        child: Column(
                          children: [
                            if (textScale > 1.35) ...[
                              const Icon(
                                Icons.auto_graph_rounded,
                                color: GaussColors.brassLight,
                                size: 21,
                              ),
                              const SizedBox(height: 5),
                              titleText,
                            ] else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_graph_rounded,
                                    color: GaussColors.brassLight,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 9),
                                  titleText,
                                ],
                              ),
                            const SizedBox(height: 5),
                            qualifier,
                          ],
                        ),
                      );
                    }
                    return Row(
                      children: [
                        const Icon(
                          Icons.auto_graph_rounded,
                          color: GaussColors.brassLight,
                          size: 21,
                        ),
                        const SizedBox(width: 9),
                        Expanded(child: titleText),
                        qualifier,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 13),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = constraints.maxWidth < 500 ? 3.0 : 6.0;
                    return Row(
                      children: [
                        for (var index = 0; index < days.length; index++) ...[
                          if (index > 0) SizedBox(width: gap),
                          Expanded(
                            child: _ActivityStar(
                              day: days[index],
                              value: heatmap[_key(days[index])] ?? 0,
                              maxValue: maxValue,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 11),
                const Text(
                  'Daily streak rewards a steady rhythm; one calm grace day can bridge a missed day, and earned XP never disappears.',
                  style: TextStyle(
                    color: GaussColors.muted,
                    fontSize: GaussTypeScale.caption,
                    height: 1.4,
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

class _ActivityStar extends StatelessWidget {
  const _ActivityStar({
    required this.day,
    required this.value,
    required this.maxValue,
  });

  final DateTime day;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final strength = value == 0 ? 0.0 : .22 + .78 * value / maxValue;
    return Tooltip(
      message: value == 0
          ? '${day.month}/${day.day}: quiet'
          : '${day.month}/${day.day}: $value first reflections',
      child: AspectRatio(
        aspectRatio: .72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: value == 0
                ? GaussColors.line.withValues(alpha: .72)
                : GaussColors.brass.withValues(alpha: strength),
            border: Border.all(
              color: value == 0
                  ? GaussColors.hairline
                  : GaussColors.brassLight.withValues(alpha: strength),
            ),
            boxShadow: value == 0
                ? null
                : [
                    BoxShadow(
                      color: GaussColors.brass.withValues(alpha: strength * .4),
                      blurRadius: 8,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 25, 20, 13),
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
                fontSize: GaussTypeScale.caption,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
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
