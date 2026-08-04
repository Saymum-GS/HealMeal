import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// lib/core/utils/app_layout.dart - FULL REPLACEMENT

class AppBreakpoints {
  // These values are in logical pixels (dp).
  static const double xs = 0; // 0-359: Compact phone (small Android)
  static const double sm = 360; // 360-599: Standard phone
  static const double md = 600; // 600-839: Large phone / phablet
  static const double lg = 840; // 840-1199: Tablet
  static const double xl = 1200; // 1200+: Desktop / web
}

enum ScreenClass { xs, sm, md, lg, xl }

class AppLayout {
  // -- Screen classification -------------------------------------------------

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static ScreenClass classify(double width) {
    if (width >= AppBreakpoints.xl) return ScreenClass.xl;
    if (width >= AppBreakpoints.lg) return ScreenClass.lg;
    if (width >= AppBreakpoints.md) return ScreenClass.md;
    if (width >= AppBreakpoints.sm) return ScreenClass.sm;
    return ScreenClass.xs;
  }

  static ScreenClass classifyContext(BuildContext context) =>
      classify(screenWidth(context));

  static bool isCompact(BuildContext context) {
    final sc = classifyContext(context);
    return sc == ScreenClass.xs || sc == ScreenClass.sm;
  }

  static bool isTabletOrLarger(BuildContext context) {
    final sc = classifyContext(context);
    return sc == ScreenClass.lg || sc == ScreenClass.xl;
  }

  // -- Product grid delegate -------------------------------------------------
  //
  // mainAxisExtent values are calculated from exact product card content height.
  // See Phase 8 for derivation. Do NOT change these values arbitrarily.
  //
  // Standard phone (360px, 2 cols, 12px gap, 16px padding): card width = 158px
  // Large phone  (600px, 3 cols, 12px gap, 16px padding): card width = 184px
  // Tablet       (840px, 4 cols, 12px gap, 16px padding): card width = 190px
  // Desktop      (1200px,5 cols, 12px gap, 24px padding): card width = 205px
  //
  static SliverGridDelegate productGridDelegate(double width) {
    final sc = classify(width);
    switch (sc) {
      case ScreenClass.xs:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 248,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        );
      case ScreenClass.sm:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 256,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        );
      case ScreenClass.md:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 268,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        );
      case ScreenClass.lg:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 272,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        );
      case ScreenClass.xl:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisExtent: 278,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        );
    }
  }

  // -- Page padding ----------------------------------------------------------

  static EdgeInsets pagePadding(double width) {
    final sc = classify(width);
    switch (sc) {
      case ScreenClass.xs:
      case ScreenClass.sm:
        return EdgeInsets.symmetric(horizontal: 16.w);
      case ScreenClass.md:
        return EdgeInsets.symmetric(horizontal: 20.w);
      case ScreenClass.lg:
        return EdgeInsets.symmetric(horizontal: 24.w);
      case ScreenClass.xl:
        return EdgeInsets.symmetric(horizontal: 32.w);
    }
  }

  // -- Max content width (for desktop/web centering) -------------------------

  static double maxContentWidth(double width) {
    if (width >= AppBreakpoints.xl) return 1140.0;
    if (width >= AppBreakpoints.lg) return 960.0;
    return double.infinity;
  }

  // -- Content container for wide screens -----------------------------------

  static Widget constrained({
    required BuildContext context,
    required Widget child,
  }) {
    final width = screenWidth(context);
    final maxWidth = maxContentWidth(width);
    if (maxWidth == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  // -- Category grid ---------------------------------------------------------

  static SliverGridDelegate categoryGridDelegate(double width) {
    final sc = classify(width);
    switch (sc) {
      case ScreenClass.xs:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.75,
          mainAxisSpacing: 12,
          crossAxisSpacing: 4,
        );
      case ScreenClass.sm:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.78,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
        );
      case ScreenClass.md:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 0.78,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
        );
      case ScreenClass.lg:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 0.75,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
        );
      case ScreenClass.xl:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          childAspectRatio: 0.75,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
        );
    }
  }

  // -- Admin dashboard grid --------------------------------------------------

  static int adminStatColumns(double width) {
    if (width >= AppBreakpoints.xl) return 4;
    if (width >= AppBreakpoints.lg) return 3;
    if (width >= AppBreakpoints.md) return 2;
    return 2;
  }

  // Helper for existing code that expects isCompactPhone
  static bool isCompactPhone(BuildContext context) {
    return classifyContext(context) == ScreenClass.xs;
  }
}
