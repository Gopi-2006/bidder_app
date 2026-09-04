import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Government Digital Service Design System
/// Official, Secure, Verified, Transparent
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Primary Official Government Palette
  static const Color primaryNavy = Color(0xFF0A2540);     // Deep official government navy
  static const Color darkNavy = Color(0xFF061B30);        // Deepest navy for contrast/headers
  static const Color accentNavy = Color(0xFF1E3A8A);      // Slightly elevated blue
  static const Color saffron = Color(0xFFE65100);         // Subtle Indian tricolor accent
  static const Color saffronLight = Color(0xFFFFF3E0);    // Saffron badge background

  // Functional / Status Colors (WCAG compliant)
  static const Color success = Color(0xFF15803D);         // Forest green (PASS / VERIFIED)
  static const Color successBg = Color(0xFFDCFCE7);       // Light green background
  static const Color successBorder = Color(0xFF86EFAC);   // Success border

  static const Color warning = Color(0xFFB45309);         // Dark amber (REVIEW / ATTENTION)
  static const Color warningBg = Color(0xFFFEF3C7);       // Light amber background
  static const Color warningBorder = Color(0xFFFCD34D);   // Warning border

  static const Color error = Color(0xFFB91C1C);           // Deep red (FAIL / REJECTED)
  static const Color errorBg = Color(0xFFFEE2E2);         // Light red background
  static const Color errorBorder = Color(0xFFFCA5A5);     // Error border

  static const Color info = Color(0xFF1D4ED8);            // Official blue (INFO / IN PROGRESS)
  static const Color infoBg = Color(0xFFEFF6FF);          // Light blue background
  static const Color infoBorder = Color(0xFFBFDBFE);      // Info border

  // Neutral Background & Surface
  static const Color background = Color(0xFFF8FAFC);      // Very light cool gray
  static const Color surface = Colors.white;              // Pure white cards
  static const Color surfaceElevated = Color(0xFFF1F5F9);  // Subtle secondary container
  static const Color border = Color(0xFFE2E8F0);           // Crisp border
  static const Color borderFocus = Color(0xFF94A3B8);      // Focused border

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF0F172A);      // Charcoal black (87%+)
  static const Color textSecondary = Color(0xFF334155);    // Medium charcoal (60%)
  static const Color textMuted = Color(0xFF64748B);        // Accessible secondary text
  static const Color textDisabled = Color(0xFF94A3B8);     // Muted labels
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 18.0;
  static const double pill = 999.0;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];
}
