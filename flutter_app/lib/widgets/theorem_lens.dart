import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import 'gauss_brand.dart';
import 'scratchpad.dart';

/// The shared question-stage material for Mission and Study Room.
///
/// The frame is deterministic vector material. Question text, mathematical
/// content, media, ink, and semantics remain live children above it.
class TheoremLensSurface extends StatelessWidget {
  const TheoremLensSurface({
    required this.ink,
    required this.child,
    this.label = 'THEOREM LENS',
    super.key,
  });

  final ScratchInkController ink;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ink,
    child: child,
    builder: (context, question) {
      final marked = !ink.isEmpty;
      final accent = marked ? GaussColors.signalBright : GaussColors.brassLight;
      return RepaintBoundary(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Color(0x70000000),
                blurRadius: 28,
                offset: Offset(0, 13),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _TheoremLensFramePainter(accent: accent, marked: marked),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TheoremLensInsignia(
                    label: label,
                    accent: accent,
                    marked: marked,
                  ),
                  const SizedBox(height: GaussSpacing.space12),
                  Stack(
                    children: [
                      PositionedDirectional(
                        top: -8,
                        end: -8,
                        child: Opacity(
                          opacity: .055,
                          child: const TheoremStarMark(size: 88, darkInk: true),
                        ),
                      ),
                      question!,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TheoremLensInsignia extends StatelessWidget {
  const _TheoremLensInsignia({
    required this.label,
    required this.accent,
    required this.marked,
  });

  final String label;
  final Color accent;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final accessibleCompact = MediaQuery.textScalerOf(context).scale(8) >= 14;
    final visibleLabel = accessibleCompact ? 'LENS' : label;
    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(child: _LensRule(color: accent)),
          const SizedBox(width: GaussSpacing.space8),
          GaussScratchGlyph(
            size: 14,
            color: marked ? GaussColors.teal : GaussColors.parchmentInk,
          ),
          const SizedBox(width: GaussSpacing.space4),
          Text(
            visibleLabel,
            textAlign: TextAlign.center,
            softWrap: false,
            style: TextStyle(
              color: GaussColors.parchmentInk.withValues(alpha: .78),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.25,
              height: 1.2,
            ),
          ),
          const SizedBox(width: GaussSpacing.space8),
          Expanded(child: _LensRule(color: accent)),
        ],
      ),
    );
  }
}

class _LensRule extends StatelessWidget {
  const _LensRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, color.withValues(alpha: .5)],
      ),
    ),
  );
}

class _TheoremLensFramePainter extends CustomPainter {
  const _TheoremLensFramePainter({required this.accent, required this.marked});

  final Color accent;
  final bool marked;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      bounds.deflate(1.5),
      const Radius.circular(30),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7E6), GaussColors.parchment],
          stops: [0, 1],
        ).createShader(bounds),
    );

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = marked ? 1.8 : 1.35
      ..color = accent.withValues(alpha: marked ? .82 : .62);
    canvas.drawRRect(outer, frame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(6), const Radius.circular(25)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .75
        ..color = GaussColors.parchmentInk.withValues(alpha: .18),
    );

    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65
      ..color = GaussColors.parchmentInk.withValues(alpha: .055);
    final gridTop = math.min(54.0, size.height * .2);
    for (var index = 1; index <= 3; index++) {
      final x = size.width * index / 4;
      canvas.drawLine(Offset(x, gridTop), Offset(x, size.height - 18), guide);
    }
    for (var index = 1; index <= 2; index++) {
      final y = gridTop + (size.height - gridTop - 18) * index / 3;
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), guide);
    }

    final axis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: .45);
    final topArc = Rect.fromCenter(
      center: Offset(size.width / 2, 5.5),
      width: math.min(size.width * .42, 220),
      height: 22,
    );
    final bottomArc = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 5.5),
      width: math.min(size.width * .32, 168),
      height: 18,
    );
    canvas.drawArc(topArc, .16, math.pi - .32, false, axis);
    canvas.drawArc(bottomArc, math.pi + .16, math.pi - .32, false, axis);

    final markerPaint = Paint()..color = accent.withValues(alpha: .78);
    final markerCenters = [
      const Offset(15, 15),
      Offset(size.width - 15, 15),
      Offset(15, size.height - 15),
      Offset(size.width - 15, size.height - 15),
    ];
    for (final center in markerCenters) {
      canvas.drawCircle(center, 1.75, markerPaint);
      canvas.drawCircle(
        center,
        4.25,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6
          ..color = accent.withValues(alpha: .28),
      );
    }

    if (marked) {
      canvas.drawCircle(
        Offset(size.width - 10, size.height / 2),
        3.2,
        Paint()
          ..color = GaussColors.signalBright
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TheoremLensFramePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.marked != marked;
}

enum TheoremChoiceTone { neutral, selected, positive, negative, source }

/// Connects variable-height answer rows into one visual decision system.
/// The decorative rail never owns answer semantics or gesture handling.
class TheoremAnswerOrbit extends StatelessWidget {
  const TheoremAnswerOrbit({
    required this.children,
    this.selectedIndex,
    super.key,
  }) : assert(children.length > 1);

  final List<Widget> children;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: CustomPaint(
      key: const ValueKey('theorem-answer-orbit-rail'),
      painter: _AnswerOrbitPainter(
        count: children.length,
        selectedIndex: selectedIndex,
      ),
      child: Column(children: children),
    ),
  );
}

class _AnswerOrbitPainter extends CustomPainter {
  const _AnswerOrbitPainter({required this.count, required this.selectedIndex});

  final int count;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 48) return;
    const railX = 24.0;
    final start = const Offset(railX, 26);
    final end = Offset(railX, size.height - 26);
    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        railX - 5,
        size.height * .3,
        railX + 5,
        size.height * .7,
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GaussColors.brass.withValues(alpha: .34),
    );

    final active = selectedIndex;
    if (active == null) return;
    final focusY = size.height * ((active + .5) / count);
    canvas.drawCircle(
      Offset(railX, focusY),
      5,
      Paint()
        ..color = GaussColors.signalBright.withValues(alpha: .28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _AnswerOrbitPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.selectedIndex != selectedIndex;
}

/// A live, content-driven answer shell attached to the shared answer orbit.
class TheoremChoiceShell extends StatelessWidget {
  const TheoremChoiceShell({
    required this.tone,
    required this.emblem,
    required this.child,
    required this.onTap,
    super.key,
  });

  final TheoremChoiceTone tone;
  final Widget emblem;
  final Widget child;
  final VoidCallback? onTap;

  Color get _accent => switch (tone) {
    TheoremChoiceTone.neutral => GaussColors.line,
    TheoremChoiceTone.selected => GaussColors.brassLight,
    TheoremChoiceTone.positive => GaussColors.signalBright,
    TheoremChoiceTone.negative => GaussColors.error,
    TheoremChoiceTone.source => GaussColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final active = tone != TheoremChoiceTone.neutral;
    final accent = _accent;
    final duration = GaussMotion.resolve(context, GaussMotion.micro);
    final colors = switch (tone) {
      TheoremChoiceTone.positive => [
        GaussColors.signal.withValues(alpha: .21),
        GaussColors.deepInk,
      ],
      TheoremChoiceTone.negative => [
        GaussColors.error.withValues(alpha: .15),
        GaussColors.deepInk,
      ],
      TheoremChoiceTone.source => [
        GaussColors.warning.withValues(alpha: .14),
        GaussColors.deepInk,
      ],
      TheoremChoiceTone.selected => [
        GaussColors.brass.withValues(alpha: .17),
        GaussColors.deepInk,
      ],
      TheoremChoiceTone.neutral => [GaussColors.panelHigh, GaussColors.raised],
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: accent.withValues(alpha: .12),
          highlightColor: accent.withValues(alpha: .06),
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              PositionedDirectional(
                start: 22,
                top: 0,
                end: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? accent : GaussColors.line,
                      width: active ? 1.7 : 1,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: .13),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                  ),
                  child: active
                      ? CustomPaint(
                          painter: _ChoiceCurrentPainter(accent: accent),
                        )
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(70, 14, 16, 14),
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: child,
                ),
              ),
              SizedBox.square(
                dimension: GaussMetrics.minTouchTarget,
                child: CustomPaint(
                  painter: _ChoiceMedallionPainter(
                    accent: accent,
                    active: active,
                  ),
                  child: Center(child: emblem),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCurrentPainter extends CustomPainter {
  const _ChoiceCurrentPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(28, size.height * .62)
      ..cubicTo(
        size.width * .34,
        size.height * .36,
        size.width * .62,
        size.height * .78,
        size.width - 18,
        size.height * .45,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: .18),
    );
    canvas.drawCircle(
      Offset(size.width - 18, size.height * .45),
      2.2,
      Paint()..color = accent.withValues(alpha: .48),
    );
  }

  @override
  bool shouldRepaint(covariant _ChoiceCurrentPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _ChoiceMedallionPainter extends CustomPainter {
  const _ChoiceMedallionPainter({required this.accent, required this.active});

  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            active ? accent.withValues(alpha: .24) : GaussColors.panelHigh,
            GaussColors.deepInk,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = active ? 1.8 : 1.1
      ..color = accent.withValues(alpha: active ? .92 : .62);
    for (var index = 0; index < 4; index++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.5),
        -.34 + index * math.pi / 2,
        .54,
        false,
        ring,
      );
    }
    canvas.drawCircle(
      center,
      radius * .54,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = accent.withValues(alpha: .32),
    );
  }

  @override
  bool shouldRepaint(covariant _ChoiceMedallionPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.active != active;
}
