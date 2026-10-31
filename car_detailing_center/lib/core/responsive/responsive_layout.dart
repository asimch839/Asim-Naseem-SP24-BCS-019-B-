import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 1100) {
      return desktop;
    } else if (width >= 650 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// A responsive page header that renders Title/Subtitle and Action items.
/// On wide screens, it sits side-by-side. On narrower screens, it smoothly wraps/stacks without overflow.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < (actions.length > 1 ? 920 : 750);

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: constraints.maxWidth < 500 ? 20 : 26,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  fontWeight: FontWeight.w400,
                ),
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
