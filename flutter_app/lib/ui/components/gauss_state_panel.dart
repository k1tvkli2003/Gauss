import 'package:flutter/material.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/ui/components/gauss_brand.dart';

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
          // Flat, after the SonusKt EmptyState: the message sits on the
          // page itself, no tinted card, gradient or shadow around it.
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: GaussSpacing.space40,
              horizontal: GaussSpacing.space12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: Center(
                    child: loading
                        ? SizedBox.square(
                            dimension: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: accent,
                            ),
                          )
                        : icon == null
                        ? const TheoremStarMark(size: 56)
                        : Icon(icon, color: accent, size: 36),
                  ),
                ),
                const SizedBox(height: 18),
                ExcludeSemantics(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                    textScaler: gaussHeadingScaler(context),
                  ),
                ),
                const SizedBox(height: 6),
                ExcludeSemantics(
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GaussColors.muted,
                      fontSize: GaussTypeScale.body,
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
