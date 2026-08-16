import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData getLightTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brandPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brandPrimary.withValues(alpha: 0.15),
    onPrimaryContainer: AppColors.brandPrimary,
    secondary: AppColors.brandSecondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.brandSecondary.withValues(alpha: 0.15),
    onSecondaryContainer: AppColors.brandSecondary,
    tertiary: AppColors.brandTertiary,
    onTertiary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightText,
    surfaceContainerHighest: AppColors.lightCard,
    onSurfaceVariant: AppColors.lightSubtext,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightBorder.withValues(alpha: 0.5),
    error: AppColors.danger,
    onError: Colors.white,
    shadow: Colors.black12,
    scrim: Colors.black54,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    textTheme: AppTextStyles.textTheme.apply(
      bodyColor: AppColors.lightText,
      displayColor: AppColors.lightText,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.lightText),
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.lightBorder,
    ),

    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black12,
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.lightSubtext),
      prefixIconColor: AppColors.lightSubtext,
      suffixIconColor: AppColors.lightSubtext,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedIconTheme: IconThemeData(color: AppColors.brandPrimary, size: 24),
      unselectedIconTheme: IconThemeData(color: AppColors.lightSubtext, size: 24),
      indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.15),
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.lightBorder),
      ),
      titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.lightText),
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.lightSubtext),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brandPrimary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: AppColors.lightBorder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
