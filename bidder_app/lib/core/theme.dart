import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GemTheme {
  static const Color primaryNavy = Color(0xFF0B2545);
  static const Color darkNavy = Color(0xFF071D36);
  static const Color saffron = Color(0xFFF58220);
  static const Color tricolorGreen = Color(0xFF138808);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surfaceCard = Colors.white;
  static const Color borderLight = Color(0xFFCBD5E1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: saffron,
        surface: surfaceCard,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
