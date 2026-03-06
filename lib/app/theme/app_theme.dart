import 'package:envelope/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Provides [lightTheme] and [darkTheme] for the EnvelopAI app.
abstract final class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surfaceLight,
          error: AppColors.overspent,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.cardLight,
        dividerColor: AppColors.dividerLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        textTheme: _textTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
        inputDecorationTheme: _inputDecorationTheme(Brightness.light),
        cardTheme: const CardThemeData(
          color: AppColors.cardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textSecondaryLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        extensions: const [AppColorExtension.light],
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surfaceDark,
          error: AppColors.overspentDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.cardDark,
        dividerColor: AppColors.dividerDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        textTheme: _textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
        inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
        cardTheme: const CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.available,
          unselectedItemColor: AppColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        extensions: const [AppColorExtension.dark],
      );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: primary,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primary,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondary,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: secondary,
          letterSpacing: 0.5,
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(
          color: isDark ? AppColors.available : AppColors.primaryLight,
          width: 2,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.overspent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Theme extension exposing ZBB-specific semantic colors to any widget via
/// `Theme.of(context).extension<AppColorExtension>()`.
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.available,
    required this.overspent,
    required this.tbbPositive,
    required this.tbbNegative,
    required this.goalFunded,
    required this.goalUnderfunded,
  });

  static const AppColorExtension light = AppColorExtension(
    available: AppColors.available,
    overspent: AppColors.overspent,
    tbbPositive: AppColors.tbbPositive,
    tbbNegative: AppColors.tbbNegative,
    goalFunded: AppColors.goalFunded,
    goalUnderfunded: AppColors.goalUnderfunded,
  );

  static const AppColorExtension dark = AppColorExtension(
    available: AppColors.availableDark,
    overspent: AppColors.overspentDark,
    tbbPositive: AppColors.tbbPositive,
    tbbNegative: AppColors.tbbNegative,
    goalFunded: AppColors.goalFunded,
    goalUnderfunded: AppColors.goalUnderfunded,
  );

  final Color available;
  final Color overspent;
  final Color tbbPositive;
  final Color tbbNegative;
  final Color goalFunded;
  final Color goalUnderfunded;

  @override
  AppColorExtension copyWith({
    Color? available,
    Color? overspent,
    Color? tbbPositive,
    Color? tbbNegative,
    Color? goalFunded,
    Color? goalUnderfunded,
  }) {
    return AppColorExtension(
      available: available ?? this.available,
      overspent: overspent ?? this.overspent,
      tbbPositive: tbbPositive ?? this.tbbPositive,
      tbbNegative: tbbNegative ?? this.tbbNegative,
      goalFunded: goalFunded ?? this.goalFunded,
      goalUnderfunded: goalUnderfunded ?? this.goalUnderfunded,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      available: Color.lerp(available, other.available, t)!,
      overspent: Color.lerp(overspent, other.overspent, t)!,
      tbbPositive: Color.lerp(tbbPositive, other.tbbPositive, t)!,
      tbbNegative: Color.lerp(tbbNegative, other.tbbNegative, t)!,
      goalFunded: Color.lerp(goalFunded, other.goalFunded, t)!,
      goalUnderfunded: Color.lerp(goalUnderfunded, other.goalUnderfunded, t)!,
    );
  }
}
