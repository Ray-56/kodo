import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData kodoTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: KodoTokens.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: KodoTokens.primary,
    brightness: Brightness.light,
    primary: KodoTokens.primary,
    surface: KodoTokens.surface,
    error: KodoTokens.error,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: KodoTokens.text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: KodoTokens.text,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: KodoTokens.text),
    bodyMedium: TextStyle(fontSize: 16, height: 1.5, color: KodoTokens.text),
    bodySmall: TextStyle(
      fontSize: 14,
      height: 1.4,
      color: KodoTokens.textSecondary,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: KodoTokens.background,
    foregroundColor: KodoTokens.text,
    centerTitle: false,
    scrolledUnderElevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF79867B)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: KodoTokens.border),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
);
