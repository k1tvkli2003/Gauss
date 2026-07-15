import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/mission_start_guard.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    if (controller.fatalError != null) {
      return const _FatalDatasetView();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final showInspector = constraints.maxWidth >= 1120;
        return Stack(
          children: [
            Positioned.fill(
              right: showInspector ? 336 : 0,
              child: _OrrerySurface(controller: controller),
            ),
            Positioned(
              left: 18,
              top: 16,
              right: showInspector ? 354 : 18,
              child: _MapHud(controller: controller),
            ),
            if (showInspector)
              Positioned(
                right: 16,
                top: 16,
                bottom: 16,
                width: 304,
                child: _TopicInspector(controller: controller),
              )
            else
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: SafeArea(
                  top: false,
                  child: _CompactTopicCard(controller: controller),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MapHud extends StatelessWidget {
  const _MapHud({required this.controller});
  final GaussController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      return Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: GaussColors.ink.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GaussColors.line),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore,
                    color: GaussColors.brassLight,
                    size: 21,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Gauss',
                    style: compact
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.titleLarge,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GaussColors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Offline',
                      style: TextStyle(color: GaussColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          _HudMetric(
            icon: Icons.auto_awesome,
            value: '${controller.xp} XP',
            compact: compact,
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            _HudMetric(
              icon: Icons.all_inclusive,
              value: '${controller.topics.length} topics',
            ),
          ],
        ],
      );
    },
  );
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.icon,
    required this.value,
    this.compact = false,
  });
  final IconData icon;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: GaussColors.ink.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GaussColors.line),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: GaussColors.brassLight),
          const SizedBox(width: 7),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _OrrerySurface extends StatefulWidget {
  const _OrrerySurface({required this.controller});
  final GaussController controller;

  @override
  State<_OrrerySurface> createState() => _OrrerySurfaceState();
}

class _OrrerySurfaceState extends State<_OrrerySurface> {
  final TransformationController _transformation = TransformationController();
  Size? _lastViewport;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: GaussColors.voidBlack,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (_lastViewport != viewport) {
          _lastViewport = viewport;
          final fit = math.min(viewport.width, viewport.height) / 1100;
          final scale = viewport.width < 600
              ? .68
              : (fit * .96).clamp(.42, 1.0);
          final dx = (viewport.width - 1100 * scale) / 2;
          final dy = (viewport.height - 1100 * scale) / 2;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _transformation.value = Matrix4.identity()
              ..setEntry(0, 0, scale)
              ..setEntry(1, 1, scale)
              ..setEntry(0, 3, dx)
              ..setEntry(1, 3, dy);
          });
        }
        return InteractiveViewer(
          transformationController: _transformation,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(250),
          minScale: .36,
          maxScale: 1.55,
          child: SizedBox.square(
            dimension: 1100,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _OrreryPainter()),
                ),
                const Positioned(left: 450, top: 450, child: _TheoremEngine()),
                for (var i = 0; i < widget.controller.topics.length; i++)
                  _positionedNode(
                    context,
                    widget.controller.topics[i],
                    i,
                    widget.controller,
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _positionedNode(
    BuildContext context,
    TopicDescriptor topic,
    int index,
    GaussController controller,
  ) {
    final orbit = index < 7 ? 0 : (index < 18 ? 1 : 2);
    final start = orbit == 0 ? 0 : (orbit == 1 ? 7 : 18);
    final count = orbit == 0 ? 7 : (orbit == 1 ? 11 : 11);
    final radius = orbit == 0 ? 235.0 : (orbit == 1 ? 350.0 : 470.0);
    final slot = index - start;
    final angle = -math.pi / 2 + (2 * math.pi * slot / count) + orbit * .08;
    final left = 550 + math.cos(angle) * radius - 47;
    final top = 550 + math.sin(angle) * radius - 47;
    return Positioned(
      left: left,
      top: top,
      child: _TopicNode(
        topic: topic,
        index: index,
        selected: controller.selectedTopicKey == topic.key,
        completed: controller.completedInTopic(topic.key),
        onPressed: () => controller.selectTopic(topic.key),
      ),
    );
  }
}

class _TopicNode extends StatelessWidget {
  const _TopicNode({
    required this.topic,
    required this.index,
    required this.selected,
    required this.completed,
    required this.onPressed,
  });
  final TopicDescriptor topic;
  final int index;
  final bool selected;
  final int completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = topic.subject == Subject.math
        ? GaussColors.violet
        : GaussColors.ice;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${topic.label}, ${topic.missionReadyCount} mission-ready questions, ${topic.preservedArchiveCount} preserved archive items',
      child: InkResponse(
        onTap: onPressed,
        radius: 60,
        child: SizedBox(
          width: 94,
          height: 118,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: selected ? 82 : 70,
                height: selected ? 82 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GaussColors.raised,
                  border: Border.all(
                    color: selected
                        ? GaussColors.brassLight
                        : accent.withValues(alpha: .65),
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: GaussColors.brass.withValues(alpha: .55),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(_topicIcon(topic.key), color: accent, size: 30),
                    Positioned(
                      top: 3,
                      right: 7,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: GaussColors.muted,
                        ),
                      ),
                    ),
                    if (topic.missionReadyCount == 0)
                      const Positioned(
                        left: 5,
                        bottom: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GaussColors.line,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 10,
                              color: GaussColors.muted,
                            ),
                          ),
                        ),
                      )
                    else if (completed > 0)
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: GaussColors.teal,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.check,
                              size: 10,
                              color: GaussColors.voidBlack,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  topic.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, height: 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _topicIcon(String key) {
  if (key.contains('geometry')) return Icons.change_history;
  if (key.contains('function')) return Icons.show_chart;
  if (key.contains('derivative')) return Icons.multiline_chart;
  if (key.contains('probability')) return Icons.casino_outlined;
  if (key.contains('electric')) return Icons.bolt;
  if (key.contains('magnet')) return Icons.blur_circular;
  if (key.contains('motion')) return Icons.speed;
  if (key.contains('heat')) return Icons.thermostat;
  if (key.contains('wave')) return Icons.waves;
  if (key.contains('atomic')) return Icons.science_outlined;
  return Icons.functions;
}

class _TheoremEngine extends StatelessWidget {
  const _TheoremEngine();

  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    height: 200,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xFF263437), Color(0xFF111719), Color(0xFF080B0C)],
      ),
      border: Border.all(color: GaussColors.brass, width: 2),
      boxShadow: [
        BoxShadow(
          color: GaussColors.brass.withValues(alpha: .28),
          blurRadius: 45,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.functions, color: GaussColors.brassLight, size: 50),
        const SizedBox(height: 9),
        Text('Theorem Engine', style: Theme.of(context).textTheme.titleMedium),
        const Text(
          'Core of mathematics\nand physics',
          textAlign: TextAlign.center,
          style: TextStyle(color: GaussColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _OrreryPainter extends CustomPainter {
  const _OrreryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final background = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF14252A), Color(0xFF090E10), GaussColors.voidBlack],
        stops: [.0, .5, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final random = math.Random(1847);
    for (var i = 0; i < 170; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = random.nextDouble() * 1.4 + .25;
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = const Color(
            0xFFD9F2F5,
          ).withValues(alpha: random.nextDouble() * .55 + .15),
      );
    }
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GaussColors.brass.withValues(alpha: .28);
    for (final radius in [150.0, 235.0, 350.0, 470.0]) {
      canvas.drawCircle(center, radius, ringPaint);
    }
    final ticks = Paint()
      ..strokeWidth = 1.5
      ..color = GaussColors.brassLight.withValues(alpha: .4);
    for (var i = 0; i < 72; i++) {
      final a = i * math.pi * 2 / 72;
      final inner = i % 6 == 0 ? 492.0 : 500.0;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * inner;
      final p2 = center + Offset(math.cos(a), math.sin(a)) * 510;
      canvas.drawLine(p1, p2, ticks);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopicInspector extends StatelessWidget {
  const _TopicInspector({required this.controller});
  final GaussController controller;

  @override
  Widget build(BuildContext context) {
    final topic = controller.selectedTopic;
    final completed = controller.completedInTopic(topic.key);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MISSION INSPECTOR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: GaussColors.brassLight,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: GaussColors.brass.withValues(alpha: .14),
                  child: Icon(
                    _topicIcon(topic.key),
                    color: GaussColors.brassLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.subject == Subject.math
                            ? 'Math orbit'
                            : 'Physics orbit',
                        style: const TextStyle(color: GaussColors.muted),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          topic.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _InspectorStat(
              label: 'Question archive',
              value: '${topic.questionCount}',
            ),
            _InspectorStat(
              label: 'Mission-ready',
              value: '${topic.missionReadyCount}',
            ),
            _InspectorStat(
              label: 'Preserved only',
              value: '${topic.preservedArchiveCount}',
            ),
            _InspectorStat(label: 'Solved correctly', value: '$completed'),
            _InspectorStat(label: 'Available offline', value: 'Yes'),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: topic.missionReadyCount == 0
                  ? 0
                  : (completed / topic.missionReadyCount).clamp(0, 1),
              minHeight: 7,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: GaussColors.line,
            ),
            const SizedBox(height: 10),
            Text(
              topic.missionReadyCount == 0
                  ? 'Preserved locally. Scoring stays off until the source contract is repaired.'
                  : (completed == 0
                        ? 'Begin this orbit to reveal your mastery.'
                        : '$completed questions mastered.'),
              style: const TextStyle(color: GaussColors.muted),
            ),
            const Spacer(),
            const _ParchmentPreview(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: topic.missionReadyCount == 0
                  ? null
                  : () async {
                      if (await confirmMissionReplacement(
                            context,
                            controller.resumableMission,
                          ) &&
                          context.mounted) {
                        context.push('/mission/${topic.key}');
                      }
                    },
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                topic.missionReadyCount == 0 ? 'Archive only' : 'Start mission',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorStat extends StatelessWidget {
  const _InspectorStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: GaussColors.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _ParchmentPreview extends StatelessWidget {
  const _ParchmentPreview();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: GaussColors.parchment,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GaussColors.brass.withValues(alpha: .55)),
    ),
    child: const Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Text(
            'نمونهٔ مأموریت',
            style: TextStyle(
              color: GaussColors.parchmentInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'اگر  x² − 5x + 6 = 0  باشد، ریشه‌ها را بیابید.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GaussColors.parchmentInk),
          ),
        ],
      ),
    ),
  );
}

class _CompactTopicCard extends StatelessWidget {
  const _CompactTopicCard({required this.controller});
  final GaussController controller;

  @override
  Widget build(BuildContext context) {
    final topic = controller.selectedTopic;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: GaussColors.brass.withValues(alpha: .16),
              child: Icon(_topicIcon(topic.key), color: GaussColors.brassLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      topic.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${topic.missionReadyCount} ready · ${topic.preservedArchiveCount} preserved',
                    style: const TextStyle(color: GaussColors.muted),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: topic.missionReadyCount == 0
                  ? null
                  : () async {
                      if (await confirmMissionReplacement(
                            context,
                            controller.resumableMission,
                          ) &&
                          context.mounted) {
                        context.push('/mission/${topic.key}');
                      }
                    },
              child: Text(topic.missionReadyCount == 0 ? 'Archive' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FatalDatasetView extends StatelessWidget {
  const _FatalDatasetView();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: GaussColors.error, size: 44),
              const SizedBox(height: 16),
              Text(
                'The offline archive could not be verified.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'The local archive was left untouched. Restart Gauss or try opening it again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GaussColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
