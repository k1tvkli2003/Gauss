import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import 'gauss_brand.dart';

/// A single calm visual and semantic language for loading, empty, and failure
/// states across Gauss. It scrolls as one unit so 200% text never strands an
/// action outside the viewport.
class GaussStatePanel extends StatelessWidget {
  const GaussStatePanel({
    required this.title,
    required this.detail,
    this.icon,
    this.loading = false,
    this.accent = GaussColors.brass,
    this.actions,
    this.liveRegion = true,
    super.key,
  });

  final String title;
  final String detail;
  final IconData? icon;
  final bool loading;
  final Color accent;
  final Widget? actions;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(GaussSpacing.space24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Semantics(
          container: true,
          liveRegion: liveRegion,
          label: '$title. $detail',
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: .1),
                  GaussColors.deepInk.withValues(alpha: .97),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: .38)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x85000000),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .09),
                    border: Border.all(color: accent.withValues(alpha: .38)),
                  ),
                  child: loading
                      ? SizedBox.square(
                          dimension: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: accent,
                          ),
                        )
                      : icon == null
                      ? const TheoremStarMark(size: 42, monochrome: true)
                      : Icon(icon, color: accent, size: 31),
                ),
                const SizedBox(height: GaussSpacing.space16),
                ExcludeSemantics(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: GaussSpacing.space8),
                ExcludeSemantics(
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: GaussTypeScale.metadata,
                      height: 1.5,
                    ),
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(height: GaussSpacing.space20),
                  actions!,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
