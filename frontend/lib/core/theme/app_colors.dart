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
    if (paletteName.contains('contrast') || paletteName == 'high_contrast_light' || paletteName == 'basic') {
      // ⚡ High Contrast / Classic Theme
      // Dark Mode (Classic Ember Dark)
      brandPrimary   = const Color(0xFFE8A020); // Amber Gold
      brandSecondary = const Color(0xFFFF6B35); // Warm Coral
      brandTertiary  = const Color(0xFF2DD4BF); // Teal Mint
      
      darkBg         = const Color(0xFF0E1016);
      darkSurface    = const Color(0xFF161B22);
      darkCard       = const Color(0xFF1C2130);
      darkCardHover  = const Color(0xFF212840);
      darkBorder     = const Color(0xFF2A3245);
      darkText       = const Color(0xFFE8EDF5);
      darkSubtext    = const Color(0xFF8B95A9);
      
      // Light Mode (High Contrast Light - Screenshot 1 & 4)
      lightPrimary   = const Color(0xFF0284C7); // Sky Blue 600
      lightSecondary = const Color(0xFF0369A1); // Sky Blue 700
      lightTertiary  = const Color(0xFF0F766E); // Teal
      
      lightBg        = const Color(0xFFEAECEF); // Cool Contrast Light Grey
      lightSurface   = const Color(0xFFFFFFFF); // Pure White Surface
      lightCard      = const Color(0xFFFFFFFF); // Pure White Card
      lightBorder    = const Color(0xFF9CA3AF); // High Contrast Grey Border
      lightText      = const Color(0xFF000000); // Pure Black Text
      lightSubtext   = const Color(0xFF4B5563); // Dark Grey Subtext
    } else {
      // 🌊 Deep Ocean Theme
      // Dark Mode (Deep Ocean - Screenshot 2 & 3)
      brandPrimary   = const Color(0xFF00F0FF); // Neon Cyan
      brandSecondary = const Color(0xFFFF007A); // Neon Pink
      brandTertiary  = const Color(0xFF7000FF); // Deep Purple
      
      darkBg         = const Color(0xFF050B14); // Ultra Deep Midnight Navy
      darkSurface    = const Color(0xFF0A1220); // Navy Surface
      darkCard       = const Color(0xFF0E1A2D); // Dark Card Surface
      darkCardHover  = const Color(0xFF15243C); // Hover state
      darkBorder     = const Color(0xFF1E3250); // Navy Border
      darkText       = const Color(0xFFE0F2FE); // Ice Blue Text
      darkSubtext    = const Color(0xFF7DD3FC); // Cyan Subtext
      
      // Light Mode (Ocean Light)
      lightPrimary   = const Color(0xFF0284C7); // Sky Blue 600
      lightSecondary = const Color(0xFF0369A1); // Sky Blue 700
      lightTertiary  = const Color(0xFF00F0FF); // Neon Cyan
      
      lightBg        = const Color(0xFFF0F8FF); // Soft Ice Light Blue
      lightSurface   = const Color(0xFFFFFFFF); // Pure White
      lightCard      = const Color(0xFFFFFFFF); // Pure White
      lightBorder    = const Color(0xFFBAE6FD); // Sky Blue Border
      lightText      = const Color(0xFF0C4A6E); // Navy Dark Text
      lightSubtext   = const Color(0xFF0284C7); // Sky Blue Subtext
    }
  }

  // Backward compatibility alias
  static void applyThemeVariant(String variant) {
    applyPalette(variant);
  }
}
