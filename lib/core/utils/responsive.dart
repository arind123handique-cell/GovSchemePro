import 'package:flutter/widgets.dart';

enum DeviceType { mobile, tablet, desktop }

/// Simple breakpoint helper for responsive layouts.
class Responsive {
  Responsive._();

  static const double mobileMax = 720;
  static const double tabletMax = 1100;

  static DeviceType of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return DeviceType.mobile;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      of(context) == DeviceType.desktop;

  /// Number of grid columns suited to the current width.
  static int gridColumns(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1300) return 3;
    return 4;
  }
}
