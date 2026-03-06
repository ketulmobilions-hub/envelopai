import 'package:flutter/material.dart';

/// Semantic color palette for EnvelopAI.
///
/// These colors map directly to ZBB concepts:
/// - [available] / [availableDark]: category has money available (positive)
/// - [overspent] / [overspentDark]: category is overspent (negative available)
/// - [tbbPositive]: To Be Budgeted has unallocated money
/// - [tbbNegative]: To Be Budgeted is in the red
abstract final class AppColors {
  // --- Brand ---
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);

  // --- Semantic: budget status ---
  static const Color available = Color(0xFF1DB954);
  static const Color availableDark = Color(0xFF1DB954);

  static const Color overspent = Color(0xFFE53935);
  static const Color overspentDark = Color(0xFFEF5350);

  static const Color tbbPositive = Color(0xFF4CAF50);
  static const Color tbbNegative = Color(0xFFF44336);

  static const Color goalFunded = Color(0xFF1DB954);
  static const Color goalUnderfunded = Color(0xFFFFA726);

  // --- Neutrals ---
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);

  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF1E1E1E);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);

  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF3A3A3A);

  // --- Text ---
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);

  static const Color textPrimaryDark = Color(0xFFEEEEEE);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
}
