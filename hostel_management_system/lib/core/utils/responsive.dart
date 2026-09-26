import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

/// Centralized responsive design utility for the Hostel Management System.
///
/// Handles screen breakpoints:
/// - Mobile: < 768px (Smartphones, narrow windows)
/// - Tablet: 768px - 1024px (Tablets, iPad, small laptop windows with scaling)
/// - Desktop: 1024px - 1440px (Standard 1080p laptops and desktops)
/// - LargeDesktop: >= 1440px (2K, 4K monitors, large LED/LCD displays)
class Responsive {
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => screenWidth(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= mobileBreakpoint && screenWidth(context) < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint && screenWidth(context) < desktopBreakpoint;

  static bool isLargeDesktop(BuildContext context) => screenWidth(context) >= desktopBreakpoint;

  static bool isMobileOrTablet(BuildContext context) => screenWidth(context) < tabletBreakpoint;

  /// Returns a responsive value depending on the current screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint && largeDesktop != null) {
      return largeDesktop;
    }
    if (width >= tabletBreakpoint && desktop != null) {
      return desktop;
    }
    if (width >= mobileBreakpoint && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Calculates dynamic card width for responsive wrap grids.
  /// Guarantees that cards never squish below [minCardWidth].
  static double calculateCardWidth({
    required double availableWidth,
    required double minCardWidth,
    double spacing = 16,
    int maxColumns = 4,
  }) {
    if (availableWidth <= 0) return minCardWidth;
    int columns = (availableWidth / (minCardWidth + spacing)).floor();
    if (columns < 1) columns = 1;
    if (columns > maxColumns) columns = maxColumns;

    final totalSpacing = (columns - 1) * spacing;
    final calculated = (availableWidth - totalSpacing) / columns;
    return calculated > 0 ? calculated : availableWidth;
  }
}

/// A responsive page header that renders Title/Subtitle and Action items.
/// On wide screens, it sits side-by-side. On narrower screens or when space is tight,
/// it smoothly wraps/stacks without ever producing a RenderFlex overflow.
class ResponsiveHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final double spacing;

  const ResponsiveHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < (actions.length > 1 ? 920 : 750);

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppStyles.h1.copyWith(
                fontSize: constraints.maxWidth < 500 ? 22 : 28,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppStyles.bodySmall,
              ),
            ],
          ],
        );

        if (actions.isEmpty) {
          return titleSection;
        }

        final actionsSection = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleSection,
              SizedBox(height: spacing),
              actionsSection,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            actionsSection,
          ],
        );
      },
    );
  }
}
