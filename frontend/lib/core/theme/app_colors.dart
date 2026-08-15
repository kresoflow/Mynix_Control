import 'package:flutter/material.dart';

/// Mynix Ember — Brand Color System
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static Color brandPrimary   = const Color(0xFFE8A020); // Amber Gold
  static Color brandSecondary = const Color(0xFFFF6B35); // Warm Coral
  static Color brandTertiary  = const Color(0xFF2DD4BF); // Teal Mint

  // ── Dark Theme Surfaces ────────────────────────────────────────────────────
  static Color darkBg         = const Color(0xFF0E1016);
  static Color darkSurface    = const Color(0xFF161B22);
  static Color darkCard       = const Color(0xFF1C2130);
  static Color darkCardHover  = const Color(0xFF212840);
  static Color darkBorder     = const Color(0xFF2A3245);
  static Color darkText       = const Color(0xFFE8EDF5);
  static Color darkSubtext    = const Color(0xFF8B95A9);

  // ── Light Theme Surfaces ───────────────────────────────────────────────────
  static Color lightBg        = const Color(0xFFF3F4F8);
  static Color lightSurface   = const Color(0xFFFFFFFF);
  static Color lightCard      = const Color(0xFFFFFFFF);
  static Color lightBorder    = const Color(0xFFE2E6ED);
  static Color lightText      = const Color(0xFF0E1016);
  static Color lightSubtext   = const Color(0xFF6B7280);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static Color success = const Color(0xFF16A34A);
  static Color warning = const Color(0xFFD97706);
  static Color danger  = const Color(0xFFDC2626);
  static Color info    = const Color(0xFF2563EB);

  // ── Palettes for Cards and Charts ──────────────────────────────────────────
  static final List<Color> categoryRainbowPalette = [
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF97316), // Orange
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEAB308), // Yellow
  ];

  static List<Color> get chartPalette => [
    brandPrimary,
    const Color(0xFF34D399),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF3B82F6),
  ];

  // ── Gradients ─────────────────────────────────────────────────────────────
  static LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPrimary, brandSecondary],
  );

  static LinearGradient get logoGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A020), Color(0xFFFF6B35)],
  );

  static LinearGradient get surfaceGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C2130), Color(0xFF161B22)],
  );

  static Color lightPrimary   = const Color(0xFF0284C7);
  static Color lightSecondary = const Color(0xFF0369A1);
  static Color lightTertiary  = const Color(0xFF0F766E);

  // ── Unified Palette Application ──────────────────────────────────────────
  static void applyPalette(dynamic palette) {
    final paletteName = palette.toString();
    if (paletteName.contains('ocean') || paletteName == 'deep_ocean' || paletteName == 'high_contrast_light') {
      // Dark Mode (Deep Ocean)
      brandPrimary = const Color(0xFF00F0FF); // Neon Cyan
      brandSecondary = const Color(0xFFFF007A); // Neon Pink
      brandTertiary = const Color(0xFF7000FF); // Deep Purple
      
      darkBg = const Color(0xFF050B14);
      darkSurface = const Color(0xFF0A1220);
      darkCard = const Color(0xFF0E1A2D);
      darkCardHover = const Color(0xFF15243C);
      darkBorder = const Color(0xFF1E3250);
      darkText = const Color(0xFFE0F2FE);
      darkSubtext = const Color(0xFF7DD3FC);
      
      // Light Mode (High Contrast Light)
      lightPrimary = const Color(0xFF0284C7); // Sky Blue 600
      lightSecondary = const Color(0xFF0369A1); // Sky Blue 700
      lightTertiary = const Color(0xFF0F766E); // Teal
      
      lightBg = const Color(0xFFEAECEF); // Cool Contrast Light Grey
      lightSurface = const Color(0xFFFFFFFF); // Pure White Surface
      lightCard = const Color(0xFFFFFFFF); // Pure White Card
      lightBorder = const Color(0xFF9CA3AF); // High Contrast Grey Border
      lightText = const Color(0xFF000000); // Pure Black Text
      lightSubtext = const Color(0xFF4B5563); // Dark Grey Subtext
    } else if (paletteName.contains('cream') || paletteName == 'soft_cream') {
      brandPrimary = const Color(0xFFD97706); // Warm Amber
      brandSecondary = const Color(0xFFB45309); // Roast Coffee
      brandTertiary = const Color(0xFF047857); // Sage Green
      
      darkBg = const Color(0xFF141210);
      darkSurface = const Color(0xFF1C1917);
      darkCard = const Color(0xFF292524);
      darkCardHover = const Color(0xFF383330);
      darkBorder = const Color(0xFF44403C);
      darkText = const Color(0xFFF5F5F4);
      darkSubtext = const Color(0xFFA8A29E);
      
      lightBg = const Color(0xFFFDFBF7);
      lightSurface = const Color(0xFFFCFAF5);
      lightCard = const Color(0xFFFFFFFF);
      lightBorder = const Color(0xFFE5E0D8);
      lightText = const Color(0xFF292524);
      lightSubtext = const Color(0xFF78716C);
    } else {
      // Ember
      brandPrimary = const Color(0xFFE8A020);
      brandSecondary = const Color(0xFFFF6B35);
      brandTertiary = const Color(0xFF2DD4BF);
      
      darkBg = const Color(0xFF0E1016);
      darkSurface = const Color(0xFF161B22);
      darkCard = const Color(0xFF1C2130);
      darkCardHover = const Color(0xFF212840);
      darkBorder = const Color(0xFF2A3245);
      darkText = const Color(0xFFE8ECF5);
      darkSubtext = const Color(0xFF7A889B);
      
      lightBg = const Color(0xFFF3F4F8);
      lightSurface = const Color(0xFFFFFFFF);
      lightCard = const Color(0xFFFFFFFF);
      lightBorder = const Color(0xFFE2E6ED);
      lightText = const Color(0xFF0E1016);
      lightSubtext = const Color(0xFF6B7280);
    }
  }

  // Backward compatibility alias
  static void applyThemeVariant(String variant) {
    applyPalette(variant);
  }
}
