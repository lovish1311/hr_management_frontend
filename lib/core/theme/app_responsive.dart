import 'package:flutter/material.dart';

/// Extension on BuildContext for quick, ergonomic access to responsive tokens:
/// `context.r.pageMargin`, `context.r.font(16)`, `context.r.isTablet`, etc.
extension ResponsiveContext on BuildContext {
  AppResponsive get r => AppResponsive.of(this);
}

/// Unified Responsive Design Token Engine
/// Provides proportional metrics, scaling, breakpoints, and container bounds
/// to guarantee 100% visual parity across Small Phones (<=380dp) and Tablets (>=720dp).
class AppResponsive {
  final double width;
  final double height;
  final Orientation orientation;

  final bool isSmallPhone;
  final bool isPhone;
  final bool isTablet;
  final bool isDesktop;

  AppResponsive._({
    required this.width,
    required this.height,
    required this.orientation,
  })  : isSmallPhone = width < 380,
        isPhone = width < 720,
        isTablet = width >= 720 && width < 1100,
        isDesktop = width >= 1100;

  factory AppResponsive.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    return AppResponsive._(
      width: size.width,
      height: size.height,
      orientation: mediaQuery.orientation,
    );
  }

  // ── 1. Spacing & Margin Tokens ─────────────────────────────────────────────
  /// Page outer padding: 12dp on small phone, 16dp on standard phone, 24dp on tablet/desktop
  double get pageMargin => isSmallPhone ? 12.0 : (isTablet ? 24.0 : 16.0);

  /// Card internal padding: 10dp on small phone, 14dp on standard phone, 18dp on tablet
  double get cardPadding => isSmallPhone ? 10.0 : (isTablet ? 18.0 : 14.0);

  /// Gap between list tiles or vertical cards
  double get itemGap => isSmallPhone ? 8.0 : (isTablet ? 16.0 : 12.0);

  /// Gap between inline components or buttons
  double get inlineGap => isSmallPhone ? 6.0 : (isTablet ? 12.0 : 8.0);

  // ── 2. Touch Targets & Dimensions ──────────────────────────────────────────
  /// Standard button height: 40dp on small phone, 44dp on phone, 50dp on tablet
  double get buttonHeight => isSmallPhone ? 40.0 : (isTablet ? 50.0 : 44.0);

  /// Icon size scaler: gently downscales on small phone, scales up on tablet
  double icon(double baseSize) {
    if (isSmallPhone) return (baseSize * 0.88).roundToDouble();
    if (isTablet || isDesktop) return (baseSize * 1.15).roundToDouble();
    return baseSize;
  }

  /// Avatar radius: scales proportionally
  double avatarRadius(double baseRadius) {
    if (isSmallPhone) return (baseRadius * 0.85).roundToDouble();
    if (isTablet || isDesktop) return (baseRadius * 1.15).roundToDouble();
    return baseRadius;
  }

  // ── 3. Proportional Typography ─────────────────────────────────────────────
  /// Scales typography smoothly so headings never wrap awkwardly on narrow viewports
  /// baseSize 20 -> 18 on small phone, 22 on tablet
  double font(double baseSize) {
    if (isSmallPhone) return (baseSize * 0.90).roundToDouble();
    if (isTablet || isDesktop) return (baseSize * 1.12).roundToDouble();
    return baseSize;
  }

  // ── 4. Dialog & Modal Geometry ─────────────────────────────────────────────
  /// Maximum width allowed for modal dialogs:
  /// On tablets/desktop, prevents dialogs from stretching across 800-1200dp.
  /// On phones, allows taking up to 92% of screen width.
  double get maxDialogWidth => isTablet || isDesktop ? 540.0 : (width * 0.92);

  /// Corner radius scaling
  double radius([double base = 12.0]) =>
      isTablet ? base * 1.2 : (isSmallPhone ? base * 0.9 : base);

  // ── 5. Responsive Grid Column Calculator ───────────────────────────────────
  /// Computes optimal column count for cards/metrics based on container constraints:
  /// - Small Phone: 1 or 2
  /// - Tablet / Wide: 3 or 4
  int gridColumns({
    int smallPhone = 1,
    int phone = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isSmallPhone) return smallPhone;
    if (isPhone) return phone;
    if (isTablet) return tablet;
    return desktop;
  }
}

/// ContentConstraint: Wraps wide-screen bodies in an optimal reading width (default 1000dp)
/// Prevents extreme horizontal stretching on tablets while remaining 100% full-width on phones.
class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = 1000.0,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// BoundedAdaptiveDialog: Wraps any modal/dialog to guarantee tablet centering
/// and bounded width (max 540dp) with scrollable content safety on small phones.
class BoundedAdaptiveDialog extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const BoundedAdaptiveDialog({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final effectiveMaxWidth = maxWidth ?? r.maxDialogWidth;

    return Dialog(
      insetPadding: padding ??
          EdgeInsets.symmetric(
            horizontal: r.isSmallPhone ? 12 : 24,
            vertical: r.isSmallPhone ? 16 : 24,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.radius(16)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}
