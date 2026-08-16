import 'package:flutter/material.dart';

/// Mynix Brand Color System — Dynamic Theme Tokens
abstract class AppColors {
  // ── Brand Accents (Dynamic) ────────────────────────────────────────────────
  static Color brandPrimary   = const Color(0xFF00F0FF); // Neon Cyan / Amber / Sky Blue
  static Color brandSecondary = const Color(0xFFFF007A); // Neon Pink / Coral
  static Color brandTertiary  = const Color(0xFF7000FF); // Deep Purple / Teal

  // ── Dark Theme Surfaces ────────────────────────────────────────────────────
  static Color darkBg         = const Color(0xFF050B14);
  static Color darkSurface    = const Color(0xFF0A1220);
  static Color darkCard       = const Color(0xFF0E1A2D);
  static Color darkCardHover  = const Color(0xFF15243C);
  static Color darkBorder     = const Color(0xFF1E3250);
  static Color darkText       = const Color(0xFFE0F2FE);
  static Color darkSubtext    = const Color(0xFF7DD3FC);

  // ── Light Theme Surfaces ───────────────────────────────────────────────────
  static Color lightBg        = const Color(0xFFEAECEF);
  static Color lightSurface   = const Color(0xFFFFFFFF);
  static Color lightCard      = const Color(0xFFFFFFFF);
  static Color lightCardHover = const Color(0xFFF3F4F6);
  static Color lightBorder    = const Color(0xFF9CA3AF);
  static Color lightText      = const Color(0xFF000000);
  static Color lightSubtext   = const Color(0xFF4B5563);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger  = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // ── Category Rainbow Palette ───────────────────────────────────────────────
  static const List<Color> categoryRainbowPalette = [
    Color(0xFFE8A020), // Amber Gold
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF16A34A), // Emerald Green
    Color(0xFF7C3AED), // Violet
    Color(0xFFE11D48), // Rose Red
    Color(0xFFD97706), // Orange
    Color(0xFF0D9488), // Teal
    Color(0xFF9333EA), // Purple
  ];

  // ── Chart Palette ──────────────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFFE8A020),
    Color(0xFF00F0FF),
    Color(0xFF10B981),
    Color(0xFFFF007A),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
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

  static LinearGradient get surfaceGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkCard, darkSurface],
  );

  // ── Dynamic Theming ────────────────────────────────────────────────────────
  static void applyPalette({required dynamic palette, bool isDark = true}) {
    final paletteStr = palette.toString().toLowerCase();

    if (paletteStr.contains('ocean') || paletteStr == 'deep_ocean' || paletteStr.contains('contrast') || paletteStr == 'high_contrast_light') {
      // 🌊 Ocean / Contrast Pair
      if (isDark) {
        // Темная (Deep Ocean)
        brandPrimary   = const Color(0xFF00F0FF); // Neon Cyan
        brandSecondary = const Color(0xFFFF007A); // Neon Pink
        brandTertiary  = const Color(0xFF7000FF); // Deep Purple
        
        darkBg         = const Color(0xFF050B14); // Deep Midnight Navy
        darkSurface    = const Color(0xFF0A1220); // Navy Surface
        darkCard       = const Color(0xFF0E1A2D); // Navy Card
        darkCardHover  = const Color(0xFF15243C);
        darkBorder     = const Color(0xFF1E3250);
        darkText       = const Color(0xFFE0F2FE);
        darkSubtext    = const Color(0xFF7DD3FC);
      } else {
        // Светлая (Contrast)
        brandPrimary   = const Color(0xFF0284C7); // Sky Blue
        brandSecondary = const Color(0xFF0369A1);
        brandTertiary  = const Color(0xFF0F766E); // Teal
        
        lightBg        = const Color(0xFFEAECEF); // Cool Contrast Grey
        lightSurface   = const Color(0xFFFFFFFF); // Pure White Surface
        lightCard      = const Color(0xFFFFFFFF); // Pure White Card
        lightBorder    = const Color(0xFF9CA3AF); // High Contrast Grey Border
        lightText      = const Color(0xFF000000); // Pure Black Text
        lightSubtext   = const Color(0xFF4B5563); // Dark Grey Subtext
      }
    } else if (paletteStr.contains('cream') || paletteStr == 'soft_cream') {
      // ☕ Cream / Espresso Pair
      if (isDark) {
        // Темная (Espresso / Dark Cream)
        brandPrimary   = const Color(0xFFD97706); // Warm Amber
        brandSecondary = const Color(0xFFB45309); // Roast Coffee
        brandTertiary  = const Color(0xFF047857); // Sage Green
        
        darkBg         = const Color(0xFF141210); // Warm Espresso Dark
        darkSurface    = const Color(0xFF1C1917); // Dark Coffee Surface
        darkCard       = const Color(0xFF292524); // Stone Card
        darkCardHover  = const Color(0xFF383330);
        darkBorder     = const Color(0xFF44403C);
        darkText       = const Color(0xFFF5F5F4);
        darkSubtext    = const Color(0xFFA8A29E);
      } else {
        // Светлая (Soft Cream)
        brandPrimary   = const Color(0xFFD97706); // Warm Amber
        brandSecondary = const Color(0xFFB45309); // Roast Coffee
        brandTertiary  = const Color(0xFF047857); // Sage Green
        
        lightBg        = const Color(0xFFF9F6F0); // Soft Cream Tint
        lightSurface   = const Color(0xFFFCFAF5); // Pure Warm Cream
        lightCard      = const Color(0xFFFCFAF5); // Warm Card
        lightBorder    = const Color(0xFFE5E0D8); // Soft Beige Border
        lightText      = const Color(0xFF2C2724); // Dark Warm Text
        lightSubtext   = const Color(0xFF78716C); // Stone Subtext
      }
    } else {
      // 🔥 Basic / Ember Pair
      if (isDark) {
        // Темная (Ember)
        brandPrimary   = const Color(0xFFE8A020); // Amber Gold
        brandSecondary = const Color(0xFFFF6B35); // Warm Coral
        brandTertiary  = const Color(0xFF2DD4BF); // Teal Mint
        
        darkBg         = const Color(0xFF0E1016); // Obsidian Background
        darkSurface    = const Color(0xFF161B22); // Graphite Surface
        darkCard       = const Color(0xFF1C2130); // Card Surface
        darkCardHover  = const Color(0xFF212840);
        darkBorder     = const Color(0xFF2A3245);
        darkText       = const Color(0xFFE8EDF5);
        darkSubtext    = const Color(0xFF8B95A9);
      } else {
        // Светлая (Basic)
        brandPrimary   = const Color(0xFFE8A020); // Amber Gold
        brandSecondary = const Color(0xFFFF6B35); // Warm Coral
        brandTertiary  = const Color(0xFF2DD4BF); // Teal Mint
        
        lightBg        = const Color(0xFFF3F4F8); // Clean Light Grey
        lightSurface   = const Color(0xFFFFFFFF); // Pure White
        lightCard      = const Color(0xFFFFFFFF); // Pure White Card
        lightBorder    = const Color(0xFFE2E6ED); // Light Border
        lightText      = const Color(0xFF0E1016); // Dark Text
        lightSubtext   = const Color(0xFF6B7280); // Subtext
      }
    }
  }

  // Alias for backward compatibility
  static void applyThemeVariant(String variant) {
    final isDark = variant.contains('dark') || variant == 'deep_ocean' || variant == 'basic';
    applyPalette(palette: variant, isDark: isDark);
  }
}
