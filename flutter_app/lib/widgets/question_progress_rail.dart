import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';

/// Five question positions presented as one compact constellation instrument.
///
/// Labels and values remain live English chrome. Each numbered position is
/// visible without relying on color, and the composition reflows vertically
/// instead of shrinking when 200% text needs more room.
class QuestionProgressRail extends StatelessWidget {
  const QuestionProgressRail({
    required this.index,
    required this.total,
    required this.label,
    this.accent = GaussColors.brassLight,
    this.valueKey,
    this.valueText,
    super.key,
  }) : assert(total > 0),
       assert(index >= 0),
       assert(index < total);

  final int index;
  final int total;
  final String label;
  final Color accent;
  final Key? valueKey;
  final String? valueText;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label. Question ${index + 1} of $total.',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaledInsignia = MediaQuery.textScalerOf(
            context,
          ).scale(GaussTypeScale.insignia);
          final stackHeader =
              constraints.maxWidth < 210 ||
              (scaledInsignia >= 18 && constraints.maxWidth < 420);
          final rail = _ConstellationRail(
            index: index,
            total: total,
            accent: accent,
          );
          final labelWidget = Text(
            label,
            textAlign: stackHeader ? TextAlign.center : TextAlign.start,
            softWrap: true,
            style: TextStyle(
              color: accent,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.05,
              height: 1.1,
            ),
          );
          final valueWidget = Text(
            valueText ?? '${index + 1} / $total',
            key: valueKey,
            textAlign: stackHeader ? TextAlign.center : TextAlign.end,
            softWrap: true,
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          );
          if (stackHeader) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                labelWidget,
                const SizedBox(height: GaussSpacing.space4),
                rail,
                const SizedBox(height: GaussSpacing.space4),
                valueWidget,
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: labelWidget),
                  const SizedBox(width: GaussSpacing.space8),
                  valueWidget,
                ],
              ),
              const SizedBox(height: GaussSpacing.space4),
              rail,
            ],
          );
        },
      ),
    ),
  );
}

class _ConstellationRail extends StatelessWidget {
  const _ConstellationRail({
    required this.index,
    required this.total,
    required this.accent,
  });

  final int index;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('question-progress-segments'),
    height: 34,
    child: Stack(
      alignment: Alignment.center,
      children: [
        PositionedDirectional(
          start: 14,
          end: 14,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: .12),
                  GaussColors.brass.withValues(alpha: .48),
                  GaussColors.hairline,
                  accent.withValues(alpha: .12),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (var step = 0; step < total; step++)
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    key: ValueKey('question-progress-segment-$step'),
                    duration: GaussMotion.resolve(context, GaussMotion.micro),
                    width: step == index ? 32 : 26,
                    height: step == index ? 32 : 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step < index
                          ? GaussColors.signal.withValues(alpha: .2)
                          : step == index
                          ? GaussColors.deepInk
                          : GaussColors.abyss.withValues(alpha: .9),
                      border: Border.all(
                        color: step < index
                            ? GaussColors.signalBright
                            : step == index
                            ? accent
                            : GaussColors.fog.withValues(alpha: .72),
                        width: step == index ? 2 : 1.2,
                      ),
                      boxShadow: step == index
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: .46),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: step < index
                            ? GaussColors.signalBright
                            : step == index
                            ? GaussColors.brassLight
                            : GaussColors.ivory,
                        fontSize: step == index ? 12 : 10,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
