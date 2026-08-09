import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Color(0x22000000)),
  ];

  static const floating = [
    BoxShadow(blurRadius: 24, offset: Offset(0, 8), color: Color(0x33000000)),
  ];
}
