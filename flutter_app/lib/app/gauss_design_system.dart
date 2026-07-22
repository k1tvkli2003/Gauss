import 'package:flutter/widgets.dart';

/// The single adaptive vocabulary for every Gauss surface.
///
/// Breakpoints describe the whole app window, not the remaining width inside
/// a rail or inspector. Components may still use named *content* thresholds
/// when their own material needs a minimum usable width.
enum GaussWindowClass {
  compact,
  medium,
  expanded,
  wide;

  static GaussWindowClass fromWidth(double width) {
    if (width < GaussBreakpoints.medium) return GaussWindowClass.compact;
    if (width < GaussBreakpoints.expanded) return GaussWindowClass.medium;
    if (width < GaussBreakpoints.wide) return GaussWindowClass.expanded;
    return GaussWindowClass.wide;
  }

  static GaussWindowClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == GaussWindowClass.compact;
  bool get isMedium => this == GaussWindowClass.medium;
  bool get isExpanded =>
      this == GaussWindowClass.expanded || this == GaussWindowClass.wide;
  bool get isWide => this == GaussWindowClass.wide;

  bool get usesNavigationRail => !isCompact;
  bool get extendsNavigationRail => isWide;
  bool get showsPersistentInspector => isExpanded;

  double get pageGutter => switch (this) {
    GaussWindowClass.compact => GaussSpacing.space16,
    GaussWindowClass.medium => GaussSpacing.space20,
    GaussWindowClass.expanded => GaussSpacing.space24,
    GaussWindowClass.wide => GaussSpacing.space32,
  };

  double get pageBottomInset => switch (this) {
    GaussWindowClass.compact => GaussMetrics.compactChromeReserve,
    GaussWindowClass.medium => GaussSpacing.space32,
    GaussWindowClass.expanded || GaussWindowClass.wide => GaussSpacing.space40,
  };
}

abstract final class GaussBreakpoints {
  static const medium = 600.0;
  static const expanded = 1024.0;
  static const wide = 1440.0;

  /// A split Study Room is useful only when each pane remains readable.
  static const studyRoomSplitContent = 840.0;

  /// Four metrics remain glanceable above this *usable content* width.
  static const insightsFourMetricsContent = 600.0;
}

abstract final class GaussSpacing {
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;
  static const space48 = 48.0;
}

abstract final class GaussMetrics {
  static const minTouchTarget = 48.0;
  static const compactNavigationHeight = 68.0;
  static const compactNavigationOuterInset = 10.0;
  static const compactChromeReserve = 96.0;
  static const mapDockHeight = 76.0;
  static const mapOverlayGap = 12.0;
  static const mapCompactDockBottom = 92.0;
  static const mapRailDockBottom = 14.0;
  static const mapInspectorWidth = 346.0;
  static const mapWideInspectorWidth = 378.0;

  static double mapDockBottom(GaussWindowClass window) =>
      window.isCompact ? mapCompactDockBottom : mapRailDockBottom;

  static double mapBottomObstruction(GaussWindowClass window) =>
      window.showsPersistentInspector
      ? GaussSpacing.space24
      : mapDockBottom(window) + mapDockHeight + mapOverlayGap;

  static double mapScrollEndInset(GaussWindowClass window) =>
      mapBottomObstruction(window) + GaussSpacing.space32;
}

abstract final class GaussTypeScale {
  /// Reserved for compact insignia such as LVL, never explanatory copy.
  static const insignia = 10.0;
  static const caption = 11.0;
  static const metadata = 12.0;
  static const body = 14.0;
}

abstract final class GaussMotion {
  static const micro = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const spatial = Duration(milliseconds: 520);

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
