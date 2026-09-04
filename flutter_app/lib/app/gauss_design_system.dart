import 'dart:math' as math;

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

/// The available vertical space, classified independently from width.
///
/// Android windows are dynamic: rotation, split-screen, foldables, and freeform
/// resizing can all change the usable height without changing the physical
/// device. Surfaces must therefore gate dense multi-pane compositions on both
/// axes instead of treating every wide window as a roomy tablet.
enum GaussWindowHeightClass {
  compact,
  medium,
  expanded;

  static GaussWindowHeightClass fromHeight(double height) {
    if (height < GaussBreakpoints.mediumHeight) {
      return GaussWindowHeightClass.compact;
    }
    if (height < GaussBreakpoints.expandedHeight) {
      return GaussWindowHeightClass.medium;
    }
    return GaussWindowHeightClass.expanded;
  }

  bool get isCompact => this == GaussWindowHeightClass.compact;
  bool get isMedium => this == GaussWindowHeightClass.medium;
  bool get isExpanded => this == GaussWindowHeightClass.expanded;
}

/// A two-axis, window-first adaptive profile shared by every Gauss route.
///
/// This deliberately does not expose an `isTablet` flag. A physical tablet can
/// present a compact split-screen window, while a foldable can present an
/// expanded one. Product decisions are made from the space the app actually
/// owns at this frame.
@immutable
final class GaussViewport {
  const GaussViewport._({
    required this.size,
    required this.widthClass,
    required this.heightClass,
  });

  factory GaussViewport.fromSize(Size size) => GaussViewport._(
    size: size,
    widthClass: GaussWindowClass.fromWidth(size.width),
    heightClass: GaussWindowHeightClass.fromHeight(size.height),
  );

  static GaussViewport of(BuildContext context) =>
      GaussViewport.fromSize(MediaQuery.sizeOf(context));

  final Size size;
  final GaussWindowClass widthClass;
  final GaussWindowHeightClass heightClass;

  bool get isPortrait => size.height > size.width;
  bool get isLandscape => size.width > size.height;
  bool get isSquare => size.width == size.height;

  bool get usesNavigationRail => widthClass.usesNavigationRail;

  /// A labelled rail costs vertical as well as horizontal space. In a short
  /// landscape window the compact icon rail stays usable without squeezing the
  /// destinations or the brand lockup.
  bool get extendsNavigationRail =>
      size.width >= GaussBreakpoints.threePane && !heightClass.isCompact;

  /// Supporting content may sit beside the primary task only when the window
  /// has both the minimum readable width and non-compact height.
  bool get supportsTwoPane =>
      size.width >= GaussBreakpoints.twoPane && !heightClass.isCompact;

  /// Three live panes are reserved for large landscape workspaces. Accessible
  /// text can still make an individual surface choose a simpler composition.
  bool get supportsThreePane =>
      size.width >= GaussBreakpoints.threePane &&
      size.height >= GaussBreakpoints.threePaneMinHeight;

  bool get showsPersistentInspector =>
      widthClass.showsPersistentInspector && !heightClass.isCompact;

  bool get isConstrainedLandscape => isLandscape && heightClass.isCompact;
}

abstract final class GaussBreakpoints {
  /// Below this width the compact composition must use its narrow-phone
  /// reflow: one reading column, no side-by-side explanatory controls, and
  /// no essential text truncation even at 200% text scale.
  static const narrowPhone = 360.0;
  static const medium = 600.0;
  static const expanded = 1024.0;
  static const wide = 1440.0;

  /// Canonical adaptive pane thresholds based on the space owned by a route.
  static const twoPane = 840.0;
  static const threePane = 1200.0;
  static const threePaneMinHeight = 600.0;

  /// Height is classified independently so short landscape and split-screen
  /// windows never inherit a tall-tablet composition.
  static const mediumHeight = 480.0;
  static const expandedHeight = 900.0;

  /// A split Study Room is useful only when each pane remains readable.
  static const studyRoomSplitContent = twoPane;

  /// Four metrics remain glanceable above this *usable content* width.
  static const insightsFourMetricsContent = 600.0;
}

abstract final class GaussSpacing {
  /// Two-pixel corrections are optical only; structural layout stays on the
  /// four-pixel rhythm below.
  static const optical2 = 2.0;
  static const space4 = 4.0;
  static const optical6 = 6.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;
  static const space48 = 48.0;
  static const space56 = 56.0;
  static const space64 = 64.0;
}

/// Physical interaction sizes. Visual glyphs may be smaller, but their live
/// semantic hit regions must use this ramp.
abstract final class GaussHitTargets {
  static const minimum = 48.0;
  static const standard = 56.0;
  static const prominent = 64.0;
  static const hero = 72.0;
}

abstract final class GaussIconSizes {
  static const compact = 18.0;
  static const standard = 20.0;
  static const navigation = 24.0;
  static const feature = 28.0;
  static const hero = 32.0;
}

/// Borders carry most of the dark-theme depth so moving map content does not
/// depend on stacked shadows or expensive backdrop blur.
abstract final class GaussStrokes {
  static const hairline = 1.0;
  static const emphasis = 1.5;
  static const selected = 2.0;
  static const focus = 3.0;
}

/// Material depth is deliberately shallow. Large blur is reserved for fixed
/// chrome and rare completion moments, never for every moving route node.
abstract final class GaussElevation {
  static const flat = 0.0;
  static const raised = 2.0;
  static const floating = 6.0;
  static const ceremonial = 12.0;
}

abstract final class GaussOpacity {
  static const hairline = .18;
  static const quiet = .42;
  static const secondary = .68;
  static const strong = .88;
  static const opaque = 1.0;
}

abstract final class GaussMetrics {
  static const minTouchTarget = GaussHitTargets.minimum;
  static const compactNavigationHeight = 58.0;
  static const compactNavigationOuterInset = 10.0;
  static const compactChromeReserve = 96.0;

  /// The compact mission dock carries a real next-action summary, not merely
  /// a navigation affordance. Keep the reserved map clearance in step with
  /// that readable two-line treatment so path nodes never hide behind it.
  static const mapDockHeight = 108.0;
  static const mapOverlayGap = 12.0;
  static const mapCompactDockBottom = compactNavigationHeight + mapOverlayGap;
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

  /// Keeps the floating compact footer above both gesture and three-button
  /// system navigation.  `viewPadding` is retained while the keyboard is
  /// visible; the extra optical inset keeps the app's own glass footer from
  /// visually touching the Android system controls.
  static double compactNavigationSafeBottom(BuildContext context) =>
      math.max(
        MediaQuery.paddingOf(context).bottom,
        MediaQuery.viewPaddingOf(context).bottom,
      ) +
      compactNavigationOuterInset;

  /// The content-hugging footer owns no internal system padding; the shell
  /// keeps Android's safe inset outside its glass. The map therefore clears
  /// exactly one system inset, the footer, and one visible optical gap.
  static double compactMapDockBottom(BuildContext context) {
    // A parent Scaffold may zero the nested MediaQuery padding after laying
    // out its bottom bar. Reconstructing from the root FlutterView keeps the
    // Android system inset authoritative inside the Map branch as well.
    final systemBottom = MediaQueryData.fromView(
      View.of(context),
    ).viewPadding.bottom;
    return compactNavigationHeight +
        systemBottom +
        compactNavigationOuterInset +
        mapOverlayGap;
  }
}

abstract final class GaussTypeScale {
  /// Reserved for compact insignia such as LVL, never explanatory copy.
  static const insignia = 10.0;
  static const caption = 11.0;
  static const metadata = 12.0;
  static const body = 14.0;
  static const bodyLarge = 16.0;
  static const title = 18.0;
  static const titleLarge = 22.0;
  static const headline = 28.0;
  static const display = 36.0;
}

/// Occupancy and reflow contracts shared by the Map and Astral Manuscript.
/// These are ratios of the route-owned content area after system safe insets,
/// not of the physical display.
abstract final class GaussComposition {
  static const mapPhoneHeaderMaxFraction = .23;
  static const mapTabletHeaderMaxFraction = .18;
  static const mapPhonePathMinFraction = .55;
  static const mapTabletPathFraction = .66;
  static const mapTabletInspectorFraction = .34;
  static const mapPhoneOverlayMaxFraction = .24;

  /// Single reading column for the manuscript; the stage centers it inside
  /// whatever width the window owns.
  static const questionMaxReadingWidth = 820.0;

  /// Writable reasoning space: bounded minimum while empty, comfortable once
  /// ink exists. The full scratchpad sheet is the expansion surface.
  static const questionReasoningMinHeight = 112.0;
  static const questionReasoningComfortHeight = 176.0;

  /// Accessible text can still read the two-pane mission composition, but
  /// above this scale the review workspace must return to the single column.
  static const questionSplitTextScaleCeiling = 1.35;

  /// The review workspace pane is a fixed-width reading pane, verified on a
  /// 1280x800 landscape tablet. A percentage split would stretch the
  /// manuscript too thin near the 1200dp three-pane threshold.
  static const questionSupportPaneWidth = 310.0;
  static const questionSupportPaneWideWidth = 350.0;
  static const questionSupportPaneWideAt = 1250.0;

  /// The largest text scale the responsive matrix must pass end to end
  /// (320dp at 200% text, no clipping, no 48dp regression).
  static const requiredMaximumTextScale = 2.0;

  /// The single gate for the mission review workspace: a landscape window
  /// that can hold three live panes, a stage that keeps a readable height
  /// after chrome, and text that still fits the split. The height is the
  /// stage remainder, while the pane capability comes from the whole window,
  /// so a real 1280x800 tablet never loses the pane to its own chrome.
  static bool usesQuestionSplit({
    required GaussViewport viewport,
    required double textScale,
    required double availableHeight,
  }) =>
      viewport.supportsThreePane &&
      availableHeight >= GaussBreakpoints.mediumHeight &&
      textScale < questionSplitTextScaleCeiling;
}

abstract final class GaussMotion {
  static const micro = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const feedback = Duration(milliseconds: 280);
  static const emphasized = Duration(milliseconds: 360);
  static const spatial = Duration(milliseconds: 520);
  static const ceremonial = Duration(milliseconds: 760);

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
