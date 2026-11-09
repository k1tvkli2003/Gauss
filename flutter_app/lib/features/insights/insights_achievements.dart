part of 'insights_screen.dart';

class _AchievementPlateGrid extends StatelessWidget {
  const _AchievementPlateGrid({required this.achievements});

  final List<AchievementSnapshot> achievements;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final columns = textScale > 1.15
          ? 1
          : constraints.crossAxisExtent >= 1000
          ? 3
          : constraints.crossAxisExtent >= 700
          ? 2
          : 1;
      if (columns == 1) {
        return SliverList.builder(
          itemCount: achievements.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == achievements.length - 1 ? 0 : 11,
            ),
            child: _AchievementPlate(snapshot: achievements[index]),
          ),
        );
      }
      return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          mainAxisExtent: 230,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) =>
            _AchievementPlate(snapshot: achievements[index]),
      );
    },
  );
}

class _AchievementPlate extends StatelessWidget {
  const _AchievementPlate({required this.snapshot});

  final AchievementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final definition = snapshot.definition;
    final earned = snapshot.earnedLevel;
    final next = snapshot.nextLevel;
    final rarity = earned?.rarity ?? next?.rarity ?? AchievementRarity.common;
    final color = _rarityColor(rarity);
    final progressLabel = next == null
        ? 'Constellation complete'
        : '${snapshot.current} / ${next.threshold} toward ${next.title}';

    return Semantics(
      key: ValueKey('achievement-plate-${definition.id}'),
      container: true,
      excludeSemantics: true,
      label:
          '${definition.accessibilityLabel}. ${earned?.title ?? 'Uncharted'}. '
          '$progressLabel. ${rarity.label} tier.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stacked = constraints.maxWidth < 340 || textScale > 1.35;
          final seal = SizedBox.square(
            dimension: 68,
            child: CustomPaint(
              painter: _AchievementSealPainter(
                family: definition.family,
                color: color,
                earned: earned != null,
                tier: rarity.index + 1,
              ),
            ),
          );
          final copy = _AchievementPlateCopy(
            snapshot: snapshot,
            rarity: rarity,
            color: color,
            progressLabel: progressLabel,
            centered: stacked,
          );
          return _GlassPanel(
            radius: 21,
            padding: const EdgeInsets.all(15),
            child: stacked
                ? Column(
                    key: ValueKey(
                      'achievement-layout-stacked-${definition.id}',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    children: [seal, const SizedBox(height: 12), copy],
                  )
                : Row(
                    key: ValueKey('achievement-layout-inline-${definition.id}'),
                    children: [
                      seal,
                      const SizedBox(width: 13),
                      Expanded(child: copy),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _AchievementPlateCopy extends StatelessWidget {
  const _AchievementPlateCopy({
    required this.snapshot,
    required this.rarity,
    required this.color,
    required this.progressLabel,
    required this.centered,
  });

  final AchievementSnapshot snapshot;
  final AchievementRarity rarity;
  final Color color;
  final String progressLabel;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final definition = snapshot.definition;
    final earned = snapshot.earnedLevel;
    final alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              definition.title,
              textAlign: textAlign,
              style: TextStyle(
                color: earned == null ? GaussColors.fog : GaussColors.ivory,
                fontWeight: FontWeight.w900,
              ),
            ),
            _RarityNotches(count: rarity.index + 1, color: color),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          earned?.title ?? 'Uncharted',
          textAlign: textAlign,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          definition.description,
          textAlign: textAlign,
          style: const TextStyle(
            color: GaussColors.muted,
            fontSize: 10,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: snapshot.progress,
            minHeight: 4,
            backgroundColor: GaussColors.line,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        if (centered) ...[
          Text(
            progressLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GaussColors.fog,
              fontSize: GaussTypeScale.insignia,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            rarity.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  progressLabel,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: GaussTypeScale.insignia,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rarity.label,
                style: TextStyle(
                  color: color,
                  fontSize: GaussTypeScale.caption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RarityNotches extends StatelessWidget {
  const _RarityNotches({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < count; index++)
        Container(
          width: 3,
          height: 7 + index * 2,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
    ],
  );
}

/// Engraved brass seals: one distinct instrument silhouette per achievement
/// family, with rarity encoded as rim ticks so the tier reads without color.
class _AchievementSealPainter extends CustomPainter {
  const _AchievementSealPainter({
    required this.family,
    required this.color,
    required this.earned,
    required this.tier,
  });

  final AchievementFamily family;
  final Color color;
  final bool earned;
  final int tier;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .43;
    final dim = earned ? 1.0 : .5;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: dim);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .2 * dim);

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = color.withValues(alpha: .07 * dim),
    );
    canvas.drawCircle(Offset.zero, radius, line);
    canvas.drawCircle(Offset.zero, radius * .76, faint);
    for (var i = 0; i < tier; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / tier;
      canvas.drawCircle(
        Offset(math.cos(angle), math.sin(angle)) * radius,
        2,
        Paint()..color = color.withValues(alpha: dim),
      );
    }

    switch (family) {
      case AchievementFamily.mastery:
        for (var i = 0; i < 4; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 2);
          canvas.drawPath(
            Path()
              ..moveTo(-2.6, -2.6)
              ..quadraticBezierTo(0, -11, 0, -17)
              ..quadraticBezierTo(0, -11, 2.6, -2.6)
              ..lineTo(0, 1.8)
              ..close(),
            Paint()..color = color.withValues(alpha: dim),
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, 4, line);
      case AchievementFamily.correction:
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 14.5),
          -.2,
          math.pi * 1.45,
          false,
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-14.5, -7)
            ..lineTo(-16.5, 1)
            ..lineTo(-8.5, -1.6),
          line,
        );
        canvas.drawLine(const Offset(-7, 4), const Offset(-1.6, 9.4), line);
        canvas.drawLine(const Offset(-1.6, 9.4), const Offset(10, -7), line);
      case AchievementFamily.exploration:
        canvas.drawCircle(Offset.zero, 15, line);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 13, height: 30),
          line,
        );
        canvas.drawLine(const Offset(-15, 0), const Offset(15, 0), line);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 29, height: 13),
          line,
        );
      case AchievementFamily.challenge:
        canvas.drawPath(
          Path()
            ..moveTo(0, -17)
            ..lineTo(15, 0)
            ..lineTo(0, 17)
            ..lineTo(-15, 0)
            ..close(),
          line,
        );
        canvas.drawCircle(Offset.zero, 5.5, line);
        canvas.drawLine(const Offset(0, -11), const Offset(0, -5), line);
        canvas.drawLine(const Offset(0, 5), const Offset(0, 11), line);
      case AchievementFamily.consistency:
        final wave = Path()..moveTo(-18, 0);
        for (var x = -18.0; x <= 18; x += 1) {
          wave.lineTo(x, math.sin(x / 3.7) * 7.5);
        }
        canvas.drawPath(wave, line);
        canvas.drawLine(const Offset(-18, 12), const Offset(18, 12), faint);
        canvas.drawLine(const Offset(-18, -12), const Offset(18, -12), faint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AchievementSealPainter oldDelegate) =>
      oldDelegate.family != family ||
      oldDelegate.color != color ||
      oldDelegate.earned != earned ||
      oldDelegate.tier != tier;
}

Color _rarityColor(AchievementRarity rarity) => switch (rarity) {
  AchievementRarity.common => GaussColors.muted,
  AchievementRarity.uncommon => GaussColors.signalBright,
  AchievementRarity.rare => GaussColors.ice,
  AchievementRarity.epic => GaussColors.violet,
  AchievementRarity.legendary => GaussColors.brassLight,
};
