import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static final title = GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static final subtitle = GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final body = GoogleFonts.roboto(fontSize: 16);

  static final caption = GoogleFonts.roboto(fontSize: 12);
}
