import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Large Text Style
  static TextStyle large = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  // Medium Text Style
  static TextStyle medium = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: Colors.white
  );

  // Small Text Style
  static TextStyle small = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.2,
    color: Colors.white
  );
}
