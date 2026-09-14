import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Dora {
  static const blue = Color(0xFF00A0E9);
  static const sky = Color(0xFF5EC8F0);
  static const deep = Color(0xFF0077C0);
  static const ink = Color(0xFF0A4A7A);
  static const red = Color(0xFFE60012);
  static const yellow = Color(0xFFF6C51A);
  static const cream = Color(0xFFFFFDF8);
  static const bg = Color(0xFFE6F6FF);
  static const muted = Color(0xFF4D7394);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Dora.blue,
      brightness: Brightness.light,
    ),
  );
  final text = GoogleFonts.beVietnamProTextTheme(base.textTheme).apply(
    bodyColor: Dora.ink,
    displayColor: Dora.ink,
  );
  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: Dora.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFFFFFF0),
      foregroundColor: Dora.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.beVietnamPro(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: 0.5,
        color: Dora.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Dora.blue,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00A0E9), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x8800A0E9), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Dora.blue, width: 2.4),
      ),
    ),
  );
}
