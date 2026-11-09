import 'package:flutter/material.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';

enum GaussSurfaceTone {
  /// Default card on the night background.
  raised,

  /// A quieter well inside another surface.
  inset,
}

/// The one card surface. Depth comes from tone and a neutral hairline, not
/// from blur, gradients or brass outlines: blur under scrolling cards cost a
/// full re-blur every frame, and a brass edge on every card spent the accent
/// that should mark the one action that matters.
class GaussSurface extends StatelessWidget {
  const GaussSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = GaussRadii.card,
    this.tone = GaussSurfaceTone.raised,
    this.emphasized = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final GaussSurfaceTone tone;

  /// Marks the single current or selected surface on a screen.
  final bool emphasized;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: switch (tone) {
        GaussSurfaceTone.raised => GaussColors.surface,
        GaussSurfaceTone.inset => GaussColors.surfaceInset,
      },
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: emphasized
            ? GaussColors.brass.withValues(alpha: .55)
            : GaussColors.hairline,
      ),
    ),
    child: Padding(padding: padding, child: child),
  );
}
