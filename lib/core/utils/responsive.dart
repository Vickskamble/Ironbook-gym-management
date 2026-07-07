import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 1024;
  static bool isDesktop(BuildContext context) => width(context) >= 1024;

  static int gridColumns(BuildContext context) {
    final w = width(context);
    if (w >= 1024) return 4;
    if (w >= 600) return 3;
    return 2;
  }

  static double avatarSize(BuildContext context) {
    final w = width(context);
    if (w >= 600) return 56;
    if (w >= 400) return 48;
    return 42;
  }

  static double iconSize(BuildContext context) {
    final w = width(context);
    if (w >= 600) return 28;
    return 22;
  }

  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w >= 1024) return 48;
    if (w >= 600) return 32;
    return 16;
  }

  static double verticalSpacing(BuildContext context) {
    final w = width(context);
    if (w >= 600) return 20;
    return 12;
  }

  static double dialogWidth(BuildContext context) {
    final w = width(context);
    if (w >= 600) return 480;
    return w * 0.92;
  }

  static double sidebarWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1024) return 280;
    if (w >= 768) return 240;
    return min(200.0, w * 0.3);
  }

  static double min(double a, double b) => a < b ? a : b;

  static EdgeInsets screenPadding(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: 12);
  }

  static double fontSize(BuildContext context, double base) {
    final w = width(context);
    if (w >= 1024) return base + 4;
    if (w >= 600) return base + 2;
    return base;
  }
}
