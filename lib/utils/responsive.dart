import 'package:flutter/material.dart';

class Breakpoints {
  static const compact = 600.0;
  static const medium = 905.0;
  static const expanded = 1240.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isMedium =>
      screenWidth >= Breakpoints.compact && screenWidth < Breakpoints.expanded;
  bool get isExpanded => screenWidth >= Breakpoints.expanded;

  bool get useRailNavigation => screenWidth >= Breakpoints.compact;

  int get gridColumns {
    if (isExpanded) return 4;
    if (isMedium) return 3;
    return 2;
  }
}

class ContentBounds extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentBounds({super.key, required this.child, this.maxWidth = 720});

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
