import 'package:flutter/material.dart';

// ─── App Colors ───────────────────────────────────────────────────────────────
class AppColors {
  static const Color background   = Color(0xFF0A1628);
  static const Color surface      = Color(0xFF162033);
  static const Color card         = Color(0xFF1C2B42);
  static const Color accent       = Color(0xFFF5A623);
  static const Color accentLight  = Color(0xFFFFC55C);
  static const Color textPrimary  = Colors.white;
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color divider      = Color(0xFF243049);
  static const Color error        = Color(0xFFFF5252);
  static const Color success      = Color(0xFF4CAF50);
  static const Color chipSelected = Color(0xFFF5A623);
  static const Color chipUnselected = Color(0xFF243049);
}

// ─── App Text Styles ──────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
  static const TextStyle heading2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle heading3 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
  );
  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
  );
  static const TextStyle caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  );
  static const TextStyle accent = TextStyle(
    color: AppColors.accent,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

// ─── App Theme ────────────────────────────────────────────────────────────────
ThemeData appTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.heading2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.chipUnselected,
      selectedColor: AppColors.accent,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.background,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    useMaterial3: true,
  );
}

// ─── Categories ───────────────────────────────────────────────────────────────
const List<String> kCategories = [
  'All',
  'Hospital',
  'Police Station',
  'Library',
  'Restaurant',
  'Café',
  'Park',
  'Tourist Attraction',
  'Pharmacy',
  'School',
  'Bank',
  'Utility Office',
];

const Map<String, IconData> kCategoryIcons = {
  'All': Icons.apps_rounded,
  'Hospital': Icons.local_hospital_rounded,
  'Police Station': Icons.local_police_rounded,
  'Library': Icons.local_library_rounded,
  'Restaurant': Icons.restaurant_rounded,
  'Café': Icons.local_cafe_rounded,
  'Park': Icons.park_rounded,
  'Tourist Attraction': Icons.photo_camera_rounded,
  'Pharmacy': Icons.medication_rounded,
  'School': Icons.school_rounded,
  'Bank': Icons.account_balance_rounded,
  'Utility Office': Icons.electrical_services_rounded,
};
