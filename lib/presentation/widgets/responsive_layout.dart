import 'package:flutter/material.dart';

class AppResponsive {
  static bool isCompact(BuildContext context, {double breakpoint = 360}) {
    return MediaQuery.sizeOf(context).width < breakpoint;
  }

  static bool isNarrow(double width, {double breakpoint = 420}) {
    return width < breakpoint;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double minHorizontal = 12,
    double maxHorizontal = 24,
    double top = 16,
    double bottom = 16,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 360
        ? minHorizontal
        : width < 600
        ? 16.0
        : maxHorizontal;
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static int gridColumns(double width) {
    if (width < 420) return 1;
    if (width < 760) return 2;
    if (width < 1080) return 3;
    return 4;
  }

  static double cardWidthForGrid(double width, int columns, double spacing) {
    if (columns <= 0) return width;
    return (width - spacing * (columns - 1)) / columns;
  }
}
