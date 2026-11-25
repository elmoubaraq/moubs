import 'dart:ui' show DisplayFeature, DisplayFeatureType;
import 'package:flutter/material.dart';

/// Window size classes and adaptive layout helpers for phones, foldables, and tablets.
class Responsive {
  Responsive._();

  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 840;
  static const double maxContentWidth = 960;
  static const double maxToolFormWidth = 720;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// True for standard phones & folded cover screens (< 600dp).
  static bool isCompact(BuildContext context) => width(context) < compactBreakpoint;

  /// True for unfolded foldables, small tablets, or landscape phones (600dp–839dp).
  static bool isMedium(BuildContext context) {
    final w = width(context);
    return w >= compactBreakpoint && w < expandedBreakpoint;
  }

  /// True for large tablets & desktop-sized windows (>= 840dp).
  static bool isExpanded(BuildContext context) => width(context) >= expandedBreakpoint;

  /// Use a side NavigationRail instead of a bottom navigation bar on >= 600dp screens.
  static bool useNavigationRail(BuildContext context) => width(context) >= compactBreakpoint;

  /// Horizontal padding that scales gracefully on larger screens.
  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w >= expandedBreakpoint) return 32;
    if (w >= compactBreakpoint) return 24;
    return 16;
  }

  /// Responsive column count for tool grids (HomeScreen).
  static int toolGridColumns(BuildContext context) {
    final w = width(context);
    if (w < 340) return 3; // Narrow folded cover screens
    if (w < compactBreakpoint) return 4;
    if (w < expandedBreakpoint) return 6;
    return 8;
  }

  /// Responsive column count for File Manager grid.
  static int fileGridColumns(BuildContext context) {
    final w = width(context);
    if (w < compactBreakpoint) return 2;
    if (w < expandedBreakpoint) return 3;
    return 4;
  }

  /// Responsive column count for image grids (Image-to-PDF, PDF-to-Image).
  static int imageGridColumns(BuildContext context) {
    final w = width(context);
    if (w < compactBreakpoint) return 3;
    if (w < expandedBreakpoint) return 4;
    return 6;
  }

  /// Returns the vertical hinge/fold DisplayFeature if the device is currently
  /// unfolded with a physical hinge or fold separating left and right panes.
  static DisplayFeature? verticalHinge(BuildContext context) {
    final features = MediaQuery.displayFeaturesOf(context);
    for (final f in features) {
      if ((f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold) &&
          f.bounds.height > f.bounds.width) {
        return f;
      }
    }
    return null;
  }
}

/// Centers [child] within [maxWidth] on large screens (tablets & unfolded foldables),
/// while remaining full-width on compact phone screens.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return content;
  }
}
