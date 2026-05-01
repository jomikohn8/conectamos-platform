import 'package:flutter/material.dart';
import 'colors.dart';

export 'colors.dart';
export 'text_styles.dart';

// ── Fuentes del proyecto ───────────────────────────────────────────────────────
// Onest  → títulos, headlines, nombres, KPI valores, botones (>= 15px o w600+)
// Geist  → descripciones, subtítulos, tabla, ayuda, placeholders (<= 14px w400-500)

abstract final class AppFonts {
  static TextStyle onest({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Onest',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle geist({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Geist',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ctBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ctTeal,
        onPrimary: AppColors.ctNavy,
        secondary: AppColors.ctTealDark,
        surface: AppColors.ctSurface,
        onSurface: AppColors.ctText,
        outline: AppColors.ctBorder,
        error: AppColors.ctDanger,
      ),
      textTheme: base.textTheme
          .apply(fontFamily: 'Onest')
          .copyWith(
            bodyMedium: const TextStyle(fontFamily: 'Geist', fontSize: 14),
            bodySmall: const TextStyle(fontFamily: 'Geist', fontSize: 12),
            labelSmall: const TextStyle(fontFamily: 'Geist', fontSize: 11),
          )
          .apply(
            bodyColor: AppColors.ctText,
            displayColor: AppColors.ctText,
          ),
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ctSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctBorder2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctBorder2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctDanger),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          color: AppColors.ctText3,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ctText,
        ),
      ),
      // Elevations apagadas — diseño flat
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.ctSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: AppColors.ctBorder,
      dividerTheme: const DividerThemeData(
        color: AppColors.ctBorder,
        thickness: 1,
        space: 0,
      ),
      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.ctBorder2),
        trackColor: WidgetStateProperty.all(AppColors.ctSurface2),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
