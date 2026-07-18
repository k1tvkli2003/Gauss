import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
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
                  child: _ActivityStarChart(heatmap: study.heatmap),
                ),
                const SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: 'ATLAS COVERAGE',
                    title: 'Your explored sky',
                    detail:
                        'Progress means you reflected on a source question. It never implies that its imported answer was verified.',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SubjectProgressAtlas(controller: controller),
                ),
                const SliverToBoxAdapter(
                  child: _SectionHeading(
                    eyebrow: 'PRIVATE CONSTELLATION',
                    title: 'Study seals',
                    detail:
                        'Quiet milestones for breadth and deliberate return—no streak loss, leaderboard, or score.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 128),
                  sliver: _StudySealGrid(study: study),
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
  const _ObservatoryHeader({required this.totalQuestions});

  final int totalQuestions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 18, 13),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Row(
          children: [
            const GaussWordmark(width: 122),
            const SizedBox(width: 14),
            Container(width: 1, height: 30, color: GaussColors.hairline),
            const SizedBox(width: 14),
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
                    '${_formatCount(totalQuestions)} preserved coordinates · local to this device',
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
            const _OfflineSignal(),
          ],
        ),
      ),
    ),
  );
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
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: columns == 4 ? 1.62 : 1.34,
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
        FittedBox(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: _GlassPanel(
            radius: 25,
            padding: const EdgeInsets.all(19),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gauge = SizedBox.square(
                  dimension: 132,
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
                    children: [gauge, const SizedBox(height: 15), copy],
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

class _StudySealGrid extends StatelessWidget {
  const _StudySealGrid({required this.study});

  final StudySummary study;

  @override
  Widget build(BuildContext context) {
    final seals = <_SealDefinition>[
      _SealDefinition(
        title: 'First coordinate',
        detail: 'Reflect on one source question.',
        icon: Icons.explore_outlined,
        current: study.totalReflected,
        target: 1,
      ),
      _SealDefinition(
        title: 'Measured orbit',
        detail: 'Chart 25 questions at your own pace.',
        icon: Icons.track_changes_outlined,
        current: study.totalReflected,
        target: 25,
      ),
      _SealDefinition(
        title: 'Deep reading',
        detail: 'Chart 100 preserved questions.',
        icon: Icons.menu_book_outlined,
        current: study.totalReflected,
        target: 100,
      ),
      _SealDefinition(
        title: 'Wide sky',
        detail: 'Touch 10 different curriculum units.',
        icon: Icons.hub_outlined,
        current: study.touchedTopics,
        target: 10,
      ),
      _SealDefinition(
        title: 'Patient cartographer',
        detail: 'Chart 500 questions without a deadline.',
        icon: Icons.map_outlined,
        current: study.totalReflected,
        target: 500,
      ),
      _SealDefinition(
        title: 'Whole constellation',
        detail: 'Visit all 29 curriculum units.',
        icon: Icons.auto_awesome_outlined,
        current: study.touchedTopics,
        target: 29,
      ),
    ];
    return SliverLayoutBuilder(
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
            childAspectRatio: columns == 1 ? 2.25 : 1.62,
          ),
          itemCount: seals.length,
          itemBuilder: (context, index) => _StudySeal(definition: seals[index]),
        );
      },
    );
  }
}

class _SealDefinition {
  const _SealDefinition({
    required this.title,
    required this.detail,
    required this.icon,
    required this.current,
    required this.target,
  });

  final String title;
  final String detail;
  final IconData icon;
  final int current;
  final int target;
}

class _StudySeal extends StatelessWidget {
  const _StudySeal({required this.definition});

  final _SealDefinition definition;

  @override
  Widget build(BuildContext context) {
    final complete = definition.current >= definition.target;
    final ratio = (definition.current / definition.target).clamp(0.0, 1.0);
    return _GlassPanel(
      radius: 21,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: complete
                  ? const RadialGradient(
                      colors: [Color(0xFFE5B454), Color(0xFF6E4310)],
                    )
                  : null,
              color: complete ? null : GaussColors.raised,
              border: Border.all(
                color: complete ? GaussColors.brassLight : GaussColors.line,
              ),
              boxShadow: complete
                  ? [
                      BoxShadow(
                        color: GaussColors.brass.withValues(alpha: .25),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              definition.icon,
              color: complete ? GaussColors.deepInk : GaussColors.muted,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  definition.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: complete ? GaussColors.ivory : GaussColors.fog,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  definition.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GaussColors.muted,
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: ratio,
                          backgroundColor: GaussColors.line,
                          color: complete
                              ? GaussColors.brass
                              : GaussColors.signal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      complete
                          ? 'charted'
                          : '${definition.current}/${definition.target}',
                      style: TextStyle(
                        color: complete
                            ? GaussColors.brassLight
                            : GaussColors.fog,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
