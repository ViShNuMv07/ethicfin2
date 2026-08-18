import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

enum DeviceType { mobile, tablet, desktop }

DeviceType deviceTypeOf(BuildContext context) =>
    deviceTypeForWidth(MediaQuery.of(context).size.width);

DeviceType deviceTypeForWidth(double width) {
  if (width >= Breakpoints.desktop) return DeviceType.desktop;
  if (width >= Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.mobile;
}


int repoGridColumns(double width) {
  if (width >= Breakpoints.desktop) return 3;
  if (width >= Breakpoints.tablet) return 2;
  return 1;
}

double responsiveHorizontalPadding(double width) {
  if (width >= Breakpoints.desktop) return 32;
  if (width >= Breakpoints.tablet) return 24;
  return 16;
}