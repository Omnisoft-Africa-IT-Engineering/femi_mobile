import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Thème unique de l'application, conforme à la charte graphique Femi.
/// Utilisation dans MaterialApp :  theme: AppTheme.light
class AppTheme {
  AppTheme._();

  static const String police = 'Poppins';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.vert,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.vert,
      onPrimary: Colors.white,
      secondary: AppColors.emeraude,
      error: AppColors.depense,
      surface: Colors.white,
      onSurface: AppColors.encre,
    );

    final arrondi12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: police,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.fondEcran,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondEcran,
        foregroundColor: AppColors.encre,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: police,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.encre,
        ),
      ),

      // Boutons : arrondi 12 (le bouton principal pleine largeur fait 52 de haut).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.vert,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: arrondi12,
          textStyle: const TextStyle(
            fontFamily: police,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vert,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: arrondi12,
          textStyle: const TextStyle(
            fontFamily: police,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.vert,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: arrondi12,
          textStyle: const TextStyle(
            fontFamily: police,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vert,
          shape: arrondi12,
        ),
      ),

      // Champs de saisie : arrondi 12, contour vert au focus.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vert, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.depense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.depense, width: 1.6),
        ),
      ),

      // Cartes : arrondi 16, sans ombre.
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.vert,
        foregroundColor: Colors.white,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
              ? AppColors.vert
              : const Color(0xFFCBD5E1),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.bordure,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.nuit,
        contentTextStyle: const TextStyle(
          fontFamily: police,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: arrondi12,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.vert,
      ),
    );
  }
}