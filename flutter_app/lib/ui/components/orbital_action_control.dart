import 'package:flutter/material.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

/// A symbol-first primary action for Gauss' map and study surfaces.
///
/// The visible control is a plain filled disc rather than a generic text box. Its
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
              color: enabled ? GaussColors.ivory : GaussColors.muted,
              fontSize: GaussTypeScale.caption,
              fontWeight: FontWeight.w800,
              letterSpacing: .1,
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

  // A plain filled disc: the action is the brightest object on the screen,
  // so it needs no halo, gradient or tick ring to be found.
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    if (!enabled) {
      canvas.drawCircle(center, radius, Paint()..color = GaussColors.surface);
      canvas.drawCircle(
        center,
        radius - .5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = GaussColors.line,
      );
      return;
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = pressed
            ? Color.lerp(accent, GaussColors.brass, .45)!
            : accent,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalGatePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.enabled != enabled ||
      oldDelegate.pressed != pressed;
}
