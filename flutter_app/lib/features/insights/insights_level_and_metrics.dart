part of 'insights_screen.dart';

class _LevelMedallion extends StatelessWidget {
  const _LevelMedallion({required this.level, required this.progress});

  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Observer level $level. ${(progress * 100).round()} percent toward the next level.',
    child: SizedBox.square(
      dimension: 46,
      child: CustomPaint(
        painter: _MedallionRingPainter(progress: progress),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$level',
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: .95,
                  ),
                ),
                const Text(
                  'LVL',
                  style: TextStyle(
                    color: GaussColors.fog,
                    fontSize: GaussTypeScale.caption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MedallionRingPainter extends CustomPainter {
  const _MedallionRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 3.5) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = GaussColors.hairline,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = GaussColors.brassLight,
    );
  }

  @override
  bool shouldRepaint(covariant _MedallionRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MetricConstellation extends StatelessWidget {
  const _MetricConstellation({
    required this.study,
    required this.totalQuestions,
    required this.totalUnits,
  });

  final StudySummary study;
  final int totalQuestions;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.auto_stories_outlined,
        value: _formatCount(study.totalReflected),
        label: 'Questions charted',
        accent: GaussColors.brassLight, // the focal metric carries the accent
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        value: _formatCount(study.clearCount),
        label: 'Concepts clear',
        accent: GaussColors.muted,
      ),
      (
        icon: Icons.loop_rounded,
        value: _formatCount(study.revisitCount),
        label: 'Saved to revisit',
        accent: GaussColors.muted,
      ),
      (
        icon: Icons.hub_outlined,
        value: '${study.touchedTopics}/$totalUnits',
        label: 'Units touched',
        accent: GaussColors.muted,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(
                context,
              ).scale(1).clamp(1.0, 2.0);
              final accessible = textScale >= 1.6;
              final columns = accessible
                  ? constraints.maxWidth >= 700
                        ? 2
                        : 1
                  : constraints.maxWidth >=
                        GaussBreakpoints.insightsFourMetricsContent
                  ? 4
                  : 2;
              final metricHeight = accessible
                  ? 204.0
                  : 138 + (textScale - 1) * 34;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: metricHeight,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _MetricPlate(
                    key: ValueKey('insight-metric-$index'),
                    icon: item.icon,
                    value: item.value,
                    label: item.label,
                    accent: item.accent,
                    totalHint: index == 0
                        ? 'of ${_formatCount(totalQuestions)} available'
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetricPlate extends StatelessWidget {
  const _MetricPlate({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.totalHint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final String? totalHint;

  @override
  Widget build(BuildContext context) => _GlassPanel(
    radius: 21,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [Icon(icon, color: accent, size: 20)]),
        const SizedBox(height: 7),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: GaussColors.ivory,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Text(
          label,
          softWrap: true,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: GaussTypeScale.caption,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (totalHint != null)
          Text(
            totalHint!,
            softWrap: true,
            style: const TextStyle(
              color: GaussColors.muted,
              fontSize: GaussTypeScale.insignia,
              height: 1.15,
            ),
          ),
      ],
    ),
  );
}
