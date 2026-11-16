import 'package:flutter/material.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

/// Session progress as one segmented meter (SonusKt `Meter` grammar).
///
/// Each segment is one question. Answered segments carry their outcome:
/// teal for a correct answer, coral for a miss or skip, so the five
/// results read at a glance without numbered circles crowding the header.
/// The position is always stated in text as well, never by color alone.
/// Labels and values remain live English chrome and the header reflows
/// vertically instead of shrinking when 200% text needs more room.
class QuestionProgressRail extends StatelessWidget {
  const QuestionProgressRail({
    required this.index,
    required this.total,
    required this.label,
    this.accent = GaussColors.brassLight,
    this.valueKey,
    this.valueText,
    this.outcomes = const {},
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

  /// Recorded results by question index: true correct, false missed.
  final Map<int, bool> outcomes;

  @override
  Widget build(BuildContext context) {
    final correct = outcomes.values.where((value) => value).length;
    return Semantics(
      container: true,
      label:
          '$label. Question ${index + 1} of $total.'
          '${outcomes.isEmpty ? '' : ' $correct of ${outcomes.length} answered correctly.'}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaledInsignia = MediaQuery.textScalerOf(
              context,
            ).scale(GaussTypeScale.insignia);
            final stackHeader =
                constraints.maxWidth < 210 ||
                (scaledInsignia >= 18 && constraints.maxWidth < 420);
            final rail = _SegmentedMeter(
              index: index,
              total: total,
              accent: accent,
              outcomes: outcomes,
            );
            final labelWidget = Text(
              label,
              textAlign: stackHeader ? TextAlign.center : TextAlign.start,
              softWrap: true,
              style: const TextStyle(
                color: GaussColors.ivory,
                fontSize: GaussTypeScale.caption,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            );
            final valueWidget = Text(
              valueText ?? '${index + 1} / $total',
              key: valueKey,
              textAlign: stackHeader ? TextAlign.center : TextAlign.end,
              softWrap: true,
              style: TextStyle(
                color: accent,
                fontSize: GaussTypeScale.caption,
                fontWeight: FontWeight.w900,
                height: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
            if (stackHeader) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelWidget,
                  const SizedBox(height: GaussSpacing.space8),
                  rail,
                  const SizedBox(height: GaussSpacing.space8),
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
                const SizedBox(height: GaussSpacing.space8),
                rail,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentedMeter extends StatelessWidget {
  const _SegmentedMeter({
    required this.index,
    required this.total,
    required this.accent,
    required this.outcomes,
  });

  final int index;
  final int total;
  final Color accent;
  final Map<int, bool> outcomes;

  Color _fill(int step) {
    final outcome = outcomes[step];
    if (outcome != null) {
      return outcome ? GaussColors.signalBright : GaussColors.error;
    }
    if (step == index) return accent;
    if (step < index) return GaussColors.signal.withValues(alpha: .7);
    return GaussColors.ivory.withValues(alpha: .14);
  }

  @override
  Widget build(BuildContext context) {
    // Meter values ease over 450ms, as in SonusKt; reduced motion snaps.
    final duration = GaussMotion.resolve(
      context,
      const Duration(milliseconds: 450),
    );
    return SizedBox(
      key: const ValueKey('question-progress-segments'),
      height: 8,
      child: Row(
        children: [
          for (var step = 0; step < total; step++) ...[
            if (step > 0) const SizedBox(width: 4),
            Expanded(
              // The current question's segment is wider, so position also
              // reads by shape.
              flex: step == index ? 3 : 2,
              child: AnimatedContainer(
                key: ValueKey('question-progress-segment-$step'),
                duration: duration,
                curve: Curves.easeOutCubic,
                height: step == index ? 8 : 6,
                decoration: ShapeDecoration(
                  color: _fill(step),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
