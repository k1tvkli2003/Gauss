import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/gamification_catalog.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';
import '../feedback/feedback_capture.dart';
import '../state/gauss_controller.dart';
import '../widgets/gamification_orbit_ribbon.dart';
import '../widgets/gauss_brand.dart';

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
                    totalQuestions: controller.totalQuestions,
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
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MetricConstellation(
                    study: study,
                    totalQuestions: controller.totalQuestions,
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
                    eyebrow: 'ATLAS COVERAGE',
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
                    eyebrow: 'PRIVATE CONSTELLATION',
                    title: 'Theorem seals',
                    detail:
                        'Engraved milestones for charting, correction, and breadth — private, calm, and free of leaderboard pressure.',
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
    required this.totalQuestions,
    required this.level,
    required this.levelProgress,
    required this.vaultAvailable,
    required this.feedbackCount,
    required this.onTools,
  });

  final int totalQuestions;
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
                  'PERSONAL CONSTELLATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GaussColors.brassLight,
                    fontSize: GaussTypeScale.insignia,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatCount(totalQuestions)} questions · fully offline',
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
                    fontSize: GaussTypeScale.insignia,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
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
  });

  final StudySummary study;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.auto_stories_outlined,
        value: _formatCount(study.totalReflected),
        label: 'Questions charted',
        accent: GaussColors.brassLight,
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        value: _formatCount(study.clearCount),
        label: 'Concepts clear',
        accent: GaussColors.signalBright,
      ),
      (
        icon: Icons.loop_rounded,
        value: _formatCount(study.revisitCount),
        label: 'Saved to revisit',
        accent: GaussColors.warning,
      ),
      (
        icon: Icons.hub_outlined,
        value: '${study.touchedTopics}/29',
        label: 'Units touched',
        accent: const Color(0xFF73A9D3),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >=
                      GaussBreakpoints.insightsFourMetricsContent
                  ? 4
                  : 2;
              final textScale = MediaQuery.textScalerOf(
                context,
              ).scale(1).clamp(1.0, 2.0);
              final metricHeight = 138 + (textScale - 1) * 34;
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
        Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const Spacer(),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [BoxShadow(color: accent, blurRadius: 9)],
              ),
            ),
          ],
        ),
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              '$charted of ${_formatCount(available)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
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
                child: Icon(
                  subject == Subject.math
                      ? Icons.functions_rounded
                      : Icons.bolt_rounded,
                  color: accent,
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
            rarity.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
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
                rarity.label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
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
