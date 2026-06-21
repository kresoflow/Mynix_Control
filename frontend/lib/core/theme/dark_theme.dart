import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData getDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brandPrimary,
    onPrimary: Color(0xFF0E1016),
    primaryContainer: Color(0xFF2A2210),
    onPrimaryContainer: AppColors.brandPrimary,
    secondary: AppColors.brandSecondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF2D1A0F),
    onSecondaryContainer: AppColors.brandSecondary,
    tertiary: AppColors.brandTertiary,
    onTertiary: Color(0xFF0E1016),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    surfaceContainerHighest: AppColors.darkCard,
    onSurfaceVariant: AppColors.darkSubtext,
    outline: AppColors.darkBorder,
    outlineVariant: Color(0xFF1E2535),
    error: AppColors.danger,
    onError: Colors.white,
    shadow: Colors.black,
    scrim: Colors.black87,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    textTheme: AppTextStyles.textTheme,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.h2,
      iconTheme: const IconThemeData(color: AppColors.darkText),
      surfaceTintColor: Colors.transparent,
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      labelStyle: AppTextStyles.caption,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.darkSubtext,
      ),
      prefixIconColor: AppColors.darkSubtext,
      suffixIconColor: AppColors.darkSubtext,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: const Color(0xFF0E1016),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppTextStyles.bodyMedium,
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        side: const BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.darkSubtext,
      ),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brandPrimary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(const Color(0xFF0E1016)),
      side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brandPrimary;
        return AppColors.darkSubtext;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brandPrimary.withValues(alpha: 0.3);
        return AppColors.darkBorder;
      }),
    ),

    // Navigation Rail
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedIconTheme: IconThemeData(color: AppColors.brandPrimary, size: 24),
      unselectedIconTheme: IconThemeData(color: AppColors.darkSubtext, size: 24),
      indicatorColor: Color(0x1AE8A020), // brandPrimary 10% opacity
      elevation: 0,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.darkText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      titleTextStyle: AppTextStyles.h2,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.darkSubtext),
    ),

    // List Tile
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      textColor: AppColors.darkText,
      iconColor: AppColors.darkSubtext,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.brandPrimary,
      unselectedLabelColor: AppColors.darkSubtext,
      indicatorColor: AppColors.brandPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTextStyles.bodyMedium,
      unselectedLabelStyle: AppTextStyles.body,
    ),
  );
}
