import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/gamification_catalog.dart';
import '../domain/models.dart';
import '../domain/study_curriculum.dart';
import '../state/gauss_controller.dart';
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
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ObservatoryBackdrop(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).width < 760 ? 88 : 0,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ObservatoryHeader(
                    totalQuestions: controller.totalQuestions,
                    level: gamification.level,
                    levelProgress: gamification.levelProgress,
                    vaultAvailable: controller.backups.isSupported,
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
                  child: _DailyQuestInstrument(
                    quest: gamification.quest,
                    todayXp: gamification.todayXp,
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
                        'Engraved milestones for charting, correction, and breadth — no streak loss, leaderboard, or score.',
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
  });

  final int totalQuestions;
  final int level;
  final double levelProgress;
  final bool vaultAvailable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 18, 13),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On a narrow phone the wordmark, subtitle, medallion, vault, and
            // offline pip cannot share one row; the subtitle is the piece
            // that can stand down.
            final compact = constraints.maxWidth < 430;
            return Row(
              children: [
                GaussWordmark(width: compact ? 104 : 122),
                if (!compact) ...[
                  const SizedBox(width: 14),
                  Container(width: 1, height: 30, color: GaussColors.hairline),
                  const SizedBox(width: 14),
                ] else
                  const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERSONAL CONSTELLATION',
                        style: TextStyle(
                          color: GaussColors.brassLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.35,
                        ),
                      ),
                      Text(
                        '${_formatCount(totalQuestions)} questions · fully offline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _LevelMedallion(level: level, progress: levelProgress),
                if (vaultAvailable) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => context.push('/vault'),
                    tooltip: 'Progress vault',
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                      color: GaussColors.brassLight,
                    ),
                  ),
                ],
                if (!compact) const _OfflineSignal(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ],
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

class _DailyQuestInstrument extends StatelessWidget {
  const _DailyQuestInstrument({required this.quest, required this.todayXp});

  final DailyQuest quest;
  final int todayXp;

  @override
  Widget build(BuildContext context) {
    final progress = quest.target == 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label:
                'Daily observation. ${quest.title}. ${quest.progress} of ${quest.target}. Reward ${quest.rewardXp} experience points. ${quest.completed ? 'Complete.' : 'In progress.'} $todayXp experience earned today.',
            child: _GlassPanel(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 52,
                    child: CustomPaint(
                      painter: _MedallionRingPainter(progress: progress),
                      child: Center(
                        child: quest.completed
                            ? const Icon(
                                Icons.check_rounded,
                                size: 22,
                                color: GaussColors.signalBright,
                              )
                            : Text(
                                '${quest.progress}',
                                style: const TextStyle(
                                  color: GaussColors.signalBright,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'DAILY OBSERVATION',
                              style: TextStyle(
                                color: GaussColors.signalBright,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${quest.rewardXp} XP',
                              style: const TextStyle(
                                color: GaussColors.brassLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          quest.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: GaussColors.hairline,
                            color: GaussColors.signalBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quest.progress}/${quest.target}',
                        style: const TextStyle(
                          color: GaussColors.ivory,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$todayXp XP today',
                        style: const TextStyle(
                          color: GaussColors.fog,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _OfflineSignal extends StatelessWidget {
  const _OfflineSignal();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Private and available offline',
    child: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GaussColors.signal.withValues(alpha: .1),
        border: Border.all(
          color: GaussColors.signalBright.withValues(alpha: .35),
        ),
      ),
      child: const Icon(
        Icons.offline_bolt_outlined,
        size: 20,
        color: GaussColors.signalBright,
      ),
    ),
  );
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
              final columns = constraints.maxWidth >= 800 ? 4 : 2;
              // The plate stacks icon, value, label, and an optional hint.
              // Narrow phones get proportionally taller cells so that stack
              // always fits instead of clipping its last line.
              final cellWidth =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              final ratio = columns == 4
                  ? 1.62
                  : (cellWidth / 128).clamp(1.05, 1.34);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: ratio,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _MetricPlate(
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
    padding: const EdgeInsets.all(15),
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
        const SizedBox(height: 9),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (totalHint != null)
          Text(
            totalHint!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: GaussColors.muted, fontSize: 8),
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
                              fontSize: 9,
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
                        fontSize: 9,
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
                      fontSize: 9,
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
              style: const TextStyle(color: GaussColors.fog, fontSize: 9),
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
                      fontSize: 9,
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
                Row(
                  children: [
                    const Icon(
                      Icons.auto_graph_rounded,
                      color: GaussColors.brassLight,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Last 28 days',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Text(
                      'first reflections only',
                      style: TextStyle(color: GaussColors.muted, fontSize: 9),
                    ),
                  ],
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
                  'Empty days are simply empty days. Gauss does not erase progress or demand a streak.',
                  style: TextStyle(
                    color: GaussColors.muted,
                    fontSize: 9,
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
                fontSize: 9,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$reflected/$total',
              style: const TextStyle(color: GaussColors.muted, fontSize: 9),
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
      final columns = constraints.crossAxisExtent >= 960
          ? 3
          : constraints.crossAxisExtent >= 600
          ? 2
          : 1;
      return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: columns == 1 ? 2.35 : 1.5,
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
      container: true,
      excludeSemantics: true,
      label:
          '${definition.accessibilityLabel}. ${earned?.title ?? 'Uncharted'}. '
          '$progressLabel. ${rarity.label} tier.',
      child: _GlassPanel(
        radius: 21,
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 68,
              child: CustomPaint(
                painter: _AchievementSealPainter(
                  family: definition.family,
                  color: color,
                  earned: earned != null,
                  tier: rarity.index + 1,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          definition.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: earned == null
                                ? GaussColors.fog
                                : GaussColors.ivory,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _RarityNotches(count: rarity.index + 1, color: color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    earned?.title ?? 'Uncharted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    definition.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progressLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                      Text(
                        rarity.label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .55,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
