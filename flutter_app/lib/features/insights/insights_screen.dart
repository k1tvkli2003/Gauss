import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/domain/gamification_catalog.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/features/feedback/feedback_capture.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/features/insights/gamification_orbit_ribbon.dart';
import 'package:gauss/ui/components/gauss_brand.dart';

part 'insights_level_and_metrics.dart';
part 'insights_reflection.dart';
part 'insights_activity.dart';
part 'insights_subject_progress.dart';
part 'insights_achievements.dart';

String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final study = controller.study;
    final gamification = controller.gamification;
    final window = GaussWindowClass.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ObservatoryBackdrop(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: window.isCompact ? GaussMetrics.compactChromeReserve : 0,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ObservatoryHeader(
                    level: gamification.level,
                    levelProgress: gamification.levelProgress,
                    vaultAvailable: controller.backups.isSupported,
                    feedbackCount: controller.feedback.entryCount,
                    onTools: () => GaussFeedbackToolsSheet.show(
                      context,
                      controller: controller.feedback,
                      onOpenVault: controller.backups.isSupported
                          ? () => context.push('/vault')
                          : null,
                      accountEmail: GaussScope.accountEmailOf(context),
                      onSignOut: GaussScope.onSignOutOf(context),
                    ),
                  ),
                ),
                // Four zeros say nothing to a new learner; the reflection
                // instrument below carries the honest first-run state.
                if (study.totalReflected > 0)
                  SliverToBoxAdapter(
                    child: _MetricConstellation(
                      study: study,
                      totalQuestions: controller.totalQuestions,
                      totalUnits: controller.topics.length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _ReflectionInstrument(
                    study: study,
                    onRevisit: () => context.push('/study/revisit'),
                    onStudy: () => context.go('/study'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: GamificationOrbitRibbon(
                          summary: gamification,
                          onQuestPressed: gamification.quest.completed
                              ? null
                              : () => context.go('/study'),
                        ),
                      ),
                    ),
                  ),
                ),
                if (study.totalReflected > 0)
                  SliverToBoxAdapter(
                    child: _SubjectBalanceDial(controller: controller),
                  ),
                if (study.hypothesisCount > 0)
                  SliverToBoxAdapter(child: _HypothesisLedger(study: study)),
                SliverToBoxAdapter(
                  child: _ActivityStarChart(heatmap: study.heatmap),
                ),
                const SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: 'Atlas coverage',
                    title: 'Your explored sky',
                    detail:
                        'Progress means you reflected on a question. It never certifies the provided answer.',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SubjectProgressAtlas(controller: controller),
                ),
                const SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: 'Private constellation',
                    title: 'Theorem seals',
                    detail:
                        'Milestones for charting, correction, and breadth. Private, with no leaderboard.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 128),
                  sliver: _AchievementPlateGrid(
                    achievements: gamification.achievements,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ObservatoryBackdrop extends StatelessWidget {
  const _ObservatoryBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/visual/map/orrery_atmosphere_portrait.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: 1400,
        filterQuality: FilterQuality.medium,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xA307171C), Color(0xFA03090B)],
            stops: [.05, .7],
          ),
        ),
      ),
    ],
  );
}

class _ObservatoryHeader extends StatelessWidget {
  const _ObservatoryHeader({
    required this.level,
    required this.levelProgress,
    required this.vaultAvailable,
    required this.feedbackCount,
    required this.onTools,
  });

  final int level;
  final double levelProgress;
  final bool vaultAvailable;
  final int feedbackCount;
  final VoidCallback onTools;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('insights-header'),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final compact = constraints.maxWidth < 430 || textScale > 1.25;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  key: const ValueKey('insights-balanced-header-axis'),
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox.square(
                          key: const ValueKey('insights-level-track'),
                          dimension: 48,
                          child: Center(
                            child: _LevelMedallion(
                              level: level,
                              progress: levelProgress,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: GaussWordmark(
                          key: const ValueKey('insights-centered-wordmark'),
                          width: compact ? 112 : 128,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox.square(
                          key: const ValueKey('insights-status-track'),
                          dimension: 48,
                          child: IconButton(
                            key: const ValueKey('insights-tools-action'),
                            onPressed: onTools,
                            tooltip: feedbackCount == 0
                                ? 'Private tools'
                                : 'Private tools. $feedbackCount feedback reports.',
                            icon: Badge(
                              isLabelVisible: feedbackCount > 0,
                              label: Text('$feedbackCount'),
                              child: Icon(
                                vaultAvailable
                                    ? Icons.tune_rounded
                                    : Icons.edit_note_rounded,
                                color: GaussColors.brassLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Personal constellation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GaussColors.brassLight,
                    fontSize: GaussTypeScale.caption,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your progress, kept on this device',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 72,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            GaussColors.brass,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
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
              GaussColors.panelHigh.withValues(alpha: .87),
              GaussColors.deepInk.withValues(alpha: .82),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .2)),
        ),
        child: child,
      ),
    ),
  );
}
