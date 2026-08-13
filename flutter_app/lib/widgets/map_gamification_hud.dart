import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/models.dart';

/// A compact, map-first readout for the private daily learning loop.
///
/// This widget is deliberately presentation-only. The map owns placement and
/// navigation, while [summary] remains the reward engine's source of truth.
/// It does not duplicate course progress, the active subject, or level data.
class MapGamificationHud extends StatelessWidget {
  const MapGamificationHud({super.key, required this.summary, this.onPressed});

  final GamificationSummary summary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final target = math.max(0, summary.quest.target);
    final progress = math.max(0, summary.quest.progress);
    final safeProgress = target == 0
        ? (summary.quest.completed ? 1.0 : 0.0)
        : (progress / target).clamp(0.0, 1.0);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      key: const ValueKey('map-gamification-hud'),
      container: true,
      button: onPressed != null,
      enabled: onPressed == null ? null : true,
      label: _semanticSummary(summary),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: GaussMetrics.minTouchTarget,
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GaussRadii.large),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GaussColors.panelHigh.withValues(alpha: .92),
                  GaussColors.deepInk.withValues(alpha: .95),
                  GaussColors.abyss.withValues(alpha: .94),
                ],
              ),
              borderRadius: BorderRadius.circular(GaussRadii.large),
              border: Border.all(
                color: GaussColors.brassLight.withValues(alpha: .28),
              ),
              boxShadow: [
                BoxShadow(
                  color: GaussColors.abyss.withValues(alpha: .34),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(GaussRadii.large),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GaussSpacing.space12,
                  vertical: GaussSpacing.space8,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Three instrument columns need enough room for whole
                    // English labels, not merely enough room for their boxes.
                    // The optional trailing action consumes another 48dp, so
                    // phone sheets deliberately reflow instead of breaking
                    // words such as STREAK or RHYTHM across lines.
                    final horizontalThreshold = onPressed == null
                        ? 520.0
                        : 580.0;
                    final horizontal =
                        constraints.maxWidth >= horizontalThreshold &&
                        textScale <= 1.2;
                    final items = <Widget>[
                      _HudMetric(
                        key: const ValueKey('map-daily-streak'),
                        icon: summary.streakGraceUsed
                            ? Icons.shield_moon_outlined
                            : Icons.local_fire_department_outlined,
                        accent: summary.streakGraceUsed
                            ? GaussColors.ice
                            : GaussColors.brassLight,
                        value: '${summary.streak}',
                        label: 'DAY STREAK',
                        detail: summary.streakGraceUsed
                            ? '1-DAY GRACE ACTIVE'
                            : 'DAILY RHYTHM',
                      ),
                      _HudMetric(
                        key: const ValueKey('map-today-xp'),
                        icon: Icons.auto_awesome_rounded,
                        accent: GaussColors.signalBright,
                        value: '${summary.todayXp} XP',
                        label: 'TODAY',
                        detail: 'SAVED ON DEVICE',
                      ),
                      _QuestMetric(
                        quest: summary.quest,
                        progress: safeProgress,
                      ),
                    ];

                    if (!horizontal) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            if (index > 0) const _HudDivider(horizontal: true),
                            items[index],
                          ],
                          if (onPressed != null) ...[
                            const SizedBox(height: GaussSpacing.space4),
                            const _OpenProgressCue(expanded: true),
                          ],
                        ],
                      );
                    }

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: items[0]),
                          const _HudDivider(),
                          Expanded(child: items[1]),
                          const _HudDivider(),
                          Expanded(child: items[2]),
                          if (onPressed != null) ...[
                            const SizedBox(width: GaussSpacing.space4),
                            const _OpenProgressCue(),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    super.key,
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final Color accent;
  final String value;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: GaussSpacing.space8,
      vertical: GaussSpacing.space4,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: .1),
            border: Border.all(color: accent.withValues(alpha: .4)),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: GaussSpacing.space8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: GaussColors.ivory,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: GaussSpacing.space4),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuestMetric extends StatelessWidget {
  const _QuestMetric({required this.quest, required this.progress});

  final DailyQuest quest;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('map-daily-quest'),
    padding: const EdgeInsets.symmetric(
      horizontal: GaussSpacing.space8,
      vertical: GaussSpacing.space4,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                key: const ValueKey('map-quest-progress'),
                tween: Tween(begin: 0, end: progress),
                duration: GaussMotion.resolve(context, GaussMotion.spatial),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.5,
                  color: quest.completed
                      ? GaussColors.signalBright
                      : GaussColors.brassLight,
                  backgroundColor: GaussColors.hairline,
                ),
              ),
              Icon(
                quest.completed ? Icons.check_rounded : Icons.flag_outlined,
                size: 15,
                color: quest.completed
                    ? GaussColors.signalBright
                    : GaussColors.brassLight,
              ),
            ],
          ),
        ),
        const SizedBox(width: GaussSpacing.space8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.completed
                    ? 'COMPLETE'
                    : '${math.max(0, quest.progress)}/${math.max(0, quest.target)}',
                style: const TextStyle(
                  color: GaussColors.ivory,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: GaussSpacing.space4),
              Text(
                'DAILY QUEST',
                style: TextStyle(
                  color: quest.completed
                      ? GaussColors.signalBright
                      : GaussColors.brassLight,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quest.completed ? 'REWARD RECORDED' : 'NO RUSH',
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HudDivider extends StatelessWidget {
  const _HudDivider({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) => horizontal
      ? const Divider(height: GaussSpacing.space12, color: GaussColors.hairline)
      : const VerticalDivider(
          width: GaussSpacing.space8,
          color: GaussColors.hairline,
        );
}

class _OpenProgressCue extends StatelessWidget {
  const _OpenProgressCue({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: GaussMetrics.minTouchTarget,
      minHeight: GaussMetrics.minTouchTarget,
    ),
    child: expanded
        ? const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'OPEN PROGRESS',
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: TextStyle(
                    color: GaussColors.brassLight,
                    fontSize: GaussTypeScale.insignia,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
              ),
              SizedBox(width: GaussSpacing.space8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: GaussColors.brassLight,
              ),
            ],
          )
        : const Center(
            child: Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: GaussColors.brassLight,
            ),
          ),
  );
}

String _semanticSummary(GamificationSummary summary) {
  final grace = summary.streakGraceUsed ? ' One day grace is active.' : '';
  final questState = summary.quest.completed
      ? 'Daily quest complete and reward recorded.'
      : 'Daily quest ${math.max(0, summary.quest.progress)} of '
            '${math.max(0, summary.quest.target)}.';
  return 'Private daily progress. ${summary.streak} day streak.$grace '
      '${summary.todayXp} experience today. $questState '
      'Earned progress is never erased.';
}
