import 'package:flutter/material.dart';

class Breakpoints {
  static const compact = 600.0;
  static const medium = 905.0;
  static const expanded = 1240.0;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isLandscape => screenWidth > screenHeight;
  bool get isShortScreen => screenHeight < 650;
  bool get isCompactLayout => isLandscape || isShortScreen;

  bool get isCompact => screenWidth < Breakpoints.compact;

  bool get isMedium =>
      screenWidth >= Breakpoints.compact &&
      screenWidth < Breakpoints.expanded;

  bool get isExpanded => screenWidth >= Breakpoints.expanded;

  bool get useRailNavigation => screenWidth >= Breakpoints.compact;

  int get gridColumns {
    if (isExpanded) return 4;
    if (screenWidth >= 900) return 3;
    return 2;
  }

  double get horizontalPadding {
    if (isExpanded) return 32;
    if (isMedium) return 24;
    return 16;
  }

  double get verticalPadding => isCompactLayout ? 12 : 24;

  double get contentSpacing => isCompactLayout ? 12 : 20;

  double get responsiveHeightFactor => isCompactLayout ? 0.85 : 1.0;
}

class ContentBounds extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentBounds({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
