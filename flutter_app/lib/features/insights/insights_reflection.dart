part of 'insights_screen.dart';

class _ReflectionInstrument extends StatelessWidget {
  const _ReflectionInstrument({
    required this.study,
    required this.onRevisit,
    required this.onStudy,
  });

  final StudySummary study;
  final VoidCallback onRevisit;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, study.totalReflected);
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: _GlassPanel(
            radius: 25,
            padding: EdgeInsets.all(compact ? 15 : 19),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gauge = SizedBox.square(
                  dimension: compact ? 108 : 132,
                  child: CustomPaint(
                    painter: _ReflectionGaugePainter(
                      clearRatio: study.clearCount / total,
                      hasData: study.totalReflected > 0,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${study.totalReflected}',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const Text(
                            'charted',
                            style: TextStyle(
                              color: GaussColors.fog,
                              fontSize: GaussTypeScale.insignia,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                final copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REFLECTION BALANCE',
                      style: TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      study.totalReflected == 0
                          ? 'Your first coordinate is waiting'
                          : study.revisitCount == 0
                          ? 'No concept is waiting for another pass'
                          : '${study.revisitCount} concepts are close in orbit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Clear and revisit are private metacognitive notes—not correctness labels. Change either after any future reading.',
                      style: TextStyle(
                        color: GaussColors.muted,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 9,
                      children: [
                        FilledButton.icon(
                          onPressed: study.revisitCount == 0
                              ? onStudy
                              : onRevisit,
                          icon: Icon(
                            study.revisitCount == 0
                                ? Icons.auto_stories_outlined
                                : Icons.loop_rounded,
                          ),
                          label: Text(
                            study.revisitCount == 0
                                ? 'Open study atlas'
                                : 'Enter revisit orbit',
                          ),
                        ),
                        if (study.revisitCount > 0)
                          OutlinedButton(
                            onPressed: onStudy,
                            child: const Text('Browse all units'),
                          ),
                      ],
                    ),
                  ],
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    children: [gauge, const SizedBox(height: 11), copy],
                  );
                }
                return Row(
                  children: [
                    gauge,
                    const SizedBox(width: 25),
                    Expanded(child: copy),
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

class _ReflectionGaugePainter extends CustomPainter {
  const _ReflectionGaugePainter({
    required this.clearRatio,
    required this.hasData,
  });

  final double clearRatio;
  final bool hasData;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.line;
    canvas.drawCircle(center, radius, base);
    if (!hasData) return;
    final clear = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.signalBright;
    final revisit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = GaussColors.warning;
    const start = -math.pi / 2;
    final clearSweep = math.pi * 2 * clearRatio.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      clearSweep,
      false,
      clear,
    );
    if (clearSweep < math.pi * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + clearSweep + .035,
        math.pi * 2 - clearSweep - .07,
        false,
        revisit,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReflectionGaugePainter oldDelegate) =>
      oldDelegate.clearRatio != clearRatio || oldDelegate.hasData != hasData;
}

/// Where attention has actually gone. A balance reading, not a target: the
/// two subjects hold different amounts of material, so the bar shows both
/// the share of work and the share available.
class _SubjectBalanceDial extends StatelessWidget {
  const _SubjectBalanceDial({required this.controller});

  final GaussController controller;

  @override
  Widget build(BuildContext context) {
    var mathCharted = 0;
    var physicsCharted = 0;
    var mathAvailable = 0;
    var physicsAvailable = 0;
    for (final topic in controller.topics) {
      final charted = controller.study.topic(topic.key).reflected;
      if (topic.subject == Subject.math) {
        mathCharted += charted;
        mathAvailable += topic.questionCount;
      } else {
        physicsCharted += charted;
        physicsAvailable += topic.questionCount;
      }
    }
    final charted = mathCharted + physicsCharted;
    if (charted == 0) return const SizedBox.shrink();
    final mathShare = mathCharted / charted;
    final available = mathAvailable + physicsAvailable;
    final mathAvailableShare = available == 0 ? .5 : mathAvailable / available;
    const mathColor = GaussColors.brassLight;
    const physicsColor = Color(0xFF68C8C0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Subject balance. Mathematics $mathCharted charted, physics '
                '$physicsCharted charted. Mathematics holds '
                '${(mathAvailableShare * 100).round()} percent of the library.',
            child: _GlassPanel(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.balance_outlined,
                        color: GaussColors.brassLight,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Subject balance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${(mathShare * 100).round()}% / '
                        '${(100 - (mathShare * 100).round())}%',
                        style: const TextStyle(
                          color: GaussColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: math.max(1, (mathShare * 1000).round()),
                            child: const ColoredBox(color: mathColor),
                          ),
                          Expanded(
                            flex: math.max(1, ((1 - mathShare) * 1000).round()),
                            child: const ColoredBox(color: physicsColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceLegend(
                          color: mathColor,
                          subject: 'Mathematics',
                          charted: mathCharted,
                          available: mathAvailable,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BalanceLegend(
                          color: physicsColor,
                          subject: 'Physics',
                          charted: physicsCharted,
                          available: physicsAvailable,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'The library itself is '
                    '${(mathAvailableShare * 100).round()}% mathematics, so an '
                    'even split of attention is not the goal — this is simply '
                    'where your work has gone.',
                    style: const TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.caption,
                      height: 1.4,
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
}

class _BalanceLegend extends StatelessWidget {
  const _BalanceLegend({
    required this.color,
    required this.subject,
    required this.charted,
    required this.available,
  });

  final Color color;
  final String subject;
  final int charted;
  final int available;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              softWrap: true,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              '$charted of ${_formatCount(available)}',
              softWrap: true,
              style: const TextStyle(
                color: GaussColors.fog,
                fontSize: GaussTypeScale.insignia,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// How often the learner's pre-reveal call agreed with the source-claimed
/// key. Framed as agreement, never accuracy — the source is unverified.
class _HypothesisLedger extends StatelessWidget {
  const _HypothesisLedger({required this.study});

  final StudySummary study;

  @override
  Widget build(BuildContext context) {
    final total = study.hypothesisCount;
    final matched = study.hypothesisMatchedCount;
    final ratio = total == 0 ? 0.0 : matched / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Hypothesis ledger. Your call agreed with the unverified '
                'source key $matched of $total times.',
            child: _GlassPanel(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.balance_rounded,
                        color: GaussColors.brassLight,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Hypothesis ledger',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                          color: GaussColors.brassLight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: GaussColors.line,
                      color: GaussColors.brassLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your pre-reveal call agreed with the source key '
                    '$matched of $total times.',
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The source key is unverified, so this is a record of agreement — not of being right.',
                    style: TextStyle(
                      color: GaussColors.fog,
                      fontSize: GaussTypeScale.caption,
                      height: 1.4,
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
}
