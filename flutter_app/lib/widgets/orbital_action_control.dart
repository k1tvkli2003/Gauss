import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';

/// A symbol-first primary action for Gauss' map and study surfaces.
///
/// The visible control is an orbital gate rather than a generic text box. Its
/// meaning remains explicit to assistive technology and through the optional
/// external caption, so brand expression never comes at the cost of clarity.
class OrbitalActionControl extends StatefulWidget {
  const OrbitalActionControl({
    required this.semanticLabel,
    required this.onPressed,
    this.caption,
    this.icon = Icons.play_arrow_rounded,
    this.dimension = 56,
    this.accent = GaussColors.brassLight,
    super.key,
  }) : assert(dimension >= 48);

  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? caption;
  final IconData icon;
  final double dimension;
  final Color accent;

  @override
  State<OrbitalActionControl> createState() => _OrbitalActionControlState();
}

class _OrbitalActionControlState extends State<OrbitalActionControl> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final duration = GaussMotion.resolve(context, GaussMotion.micro);
    final control = Tooltip(
      message: widget.semanticLabel,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        child: AnimatedScale(
          scale: _pressed ? .94 : 1,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: SizedBox.square(
            dimension: widget.dimension,
            child: CustomPaint(
              painter: _OrbitalGatePainter(
                accent: widget.accent,
                enabled: enabled,
                pressed: _pressed,
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkResponse(
                    onTap: widget.onPressed,
                    onHighlightChanged: _setPressed,
                    containedInkWell: true,
                    highlightShape: BoxShape.circle,
                    radius: widget.dimension / 2,
                    splashColor: widget.accent.withValues(alpha: .18),
                    highlightColor: widget.accent.withValues(alpha: .09),
                    focusColor: widget.accent.withValues(alpha: .12),
                    hoverColor: widget.accent.withValues(alpha: .08),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: widget.dimension * .42,
                        color: enabled ? GaussColors.abyss : GaussColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final caption = widget.caption;
    if (caption == null) return control;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        control,
        const SizedBox(height: GaussSpacing.space4),
        ExcludeSemantics(
          child: Text(
            caption,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: enabled ? GaussColors.brassLight : GaussColors.muted,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w900,
              letterSpacing: .45,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbitalGatePainter extends CustomPainter {
  const _OrbitalGatePainter({
    required this.accent,
    required this.enabled,
    required this.pressed,
  });

  final Color accent;
  final bool enabled;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final activeAccent = enabled ? accent : GaussColors.muted;

    canvas.drawCircle(
      center,
      radius - 3,
      Paint()
        ..color = GaussColors.deepInk.withValues(alpha: .96)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      center,
      radius - 6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            activeAccent.withValues(alpha: enabled ? .96 : .34),
            GaussColors.brass.withValues(alpha: enabled ? .72 : .2),
          ],
          stops: const [.42, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius - 6)),
    );

    final outer = Rect.fromCircle(center: center, radius: radius - 1.5);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = pressed ? 2.4 : 1.7
      ..color = activeAccent.withValues(alpha: enabled ? .92 : .35);
    for (var index = 0; index < 4; index++) {
      final start = -.42 + index * math.pi / 2;
      canvas.drawArc(outer, start, .56, false, ring);
    }

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GaussColors.abyss.withValues(alpha: .48);
    canvas.drawCircle(center, radius * .48, innerRing);

    for (var index = 0; index < 4; index++) {
      final angle = index * math.pi / 2;
      final marker =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 4.3);
      canvas.drawCircle(marker, 1.55, Paint()..color = activeAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalGatePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.enabled != enabled ||
      oldDelegate.pressed != pressed;
}
