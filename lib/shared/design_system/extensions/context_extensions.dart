import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;

  double get width => screenSize.width;

  double get height => screenSize.height;

  bool get isMobile => width < 700;

  bool get isTablet => width >= 700 && width < 1100;

  bool get isDesktop => width >= 1100;
}
