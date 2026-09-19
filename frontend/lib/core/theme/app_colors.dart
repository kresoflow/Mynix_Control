import 'package:flutter/material.dart';

/// Mynix Brand Color System — Dynamic Theme Tokens
abstract class AppColors {
  // ── Brand Accents (Dynamic) ────────────────────────────────────────────────
  static Color brandPrimary   = const Color(0xFF0284C7); // Sky / Cobalt Blue
  static Color brandSecondary = const Color(0xFF0369A1); // Deep Cobalt
  static Color brandTertiary  = const Color(0xFF0D9488); // Teal Accent

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
  static const Color transparent = Color(0x00000000);
  static const Color pureWhite   = Color(0xFFFFFFFF);
  static const Color pureBlack   = Color(0xFF000000);
  static const Color white       = pureWhite;
  static const Color black       = pureBlack;

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger  = Color(0xFFDC2626);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // ── Subtext & Secondary Aliases ────────────────────────────────────────────
  static Color get textSecondaryDark => darkSubtext;
  static Color get textSecondaryLight => lightSubtext;
  static Color get textTertiaryDark => darkSubtext.withValues(alpha: 0.7);
  static Color get textTertiaryLight => lightSubtext.withValues(alpha: 0.7);

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
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFE8A020), // Amber
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Orange
    Color(0xFF14B8A6), // Teal
  ];

  // ── Track Backgrounds (Segmented Controls & Inputs) ────────────────────────
  static Color darkTrackBg   = const Color(0xFF0A1220);
  static Color lightTrackBg  = const Color(0xFFECEEF2);

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
        brandPrimary   = const Color(0xFF38BDF8); // Sky Blue 400
        brandSecondary = const Color(0xFF0284C7); // Sky Blue 600
        brandTertiary  = const Color(0xFF0D9488); // Teal
        
        darkBg         = const Color(0xFF050B14); // Deep Midnight Navy
        darkSurface    = const Color(0xFF0A1220); // Navy Surface
        darkCard       = const Color(0xFF0E1A2D); // Navy Card
        darkCardHover  = const Color(0xFF15243C);
        darkTrackBg    = const Color(0xFF0E1A2D);
        darkBorder     = const Color(0xFF1E3250);
        darkText       = const Color(0xFFE0F2FE);
        darkSubtext    = const Color(0xFF7DD3FC);
      } else {
        // Светлая (Contrast)
        brandPrimary   = const Color(0xFF0284C7); // Sky Blue (4.6:1 WCAG AA)
        brandSecondary = const Color(0xFF0369A1);
        brandTertiary  = const Color(0xFF0F766E); // Teal
        
        lightBg        = const Color(0xFFEAECEF); // Cool Contrast Grey
        lightSurface   = const Color(0xFFFFFFFF); // Pure White Surface
        lightCard      = const Color(0xFFFFFFFF); // Pure White Card
        lightCardHover = const Color(0xFFF1F5F9);
        lightTrackBg   = const Color(0xFFE2E8F0); // Distinct Track
        lightBorder    = const Color(0xFFCBD5E1); // Clean Grey Border
        lightText      = const Color(0xFF0F172A); // Pure Slate Text
        lightSubtext   = const Color(0xFF475569); // Dark Grey Subtext
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
        darkTrackBg    = const Color(0xFF292524);
        darkBorder     = const Color(0xFF44403C);
        darkText       = const Color(0xFFF5F5F4);
        darkSubtext    = const Color(0xFFA8A29E);
      } else {
        // Светлая (Soft Cream)
        brandPrimary   = const Color(0xFFB45309); // Deep Roast Amber (5.1:1 WCAG AA)
        brandSecondary = const Color(0xFF92400E); // Deep Coffee
        brandTertiary  = const Color(0xFF047857); // Sage Green
        
        lightBg        = const Color(0xFFF8F5EE); // Soft Cream Tint
        lightSurface   = const Color(0xFFFCFAF5); // Pure Warm Cream
        lightCard      = const Color(0xFFFCFAF5); // Warm Card
        lightCardHover = const Color(0xFFF1EDE4);
        lightTrackBg   = const Color(0xFFEBE6DC); // Distinct Warm Track
        lightBorder    = const Color(0xFFDCD5C9); // Soft Beige Border
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
        darkTrackBg    = const Color(0xFF1C2130);
        darkBorder     = const Color(0xFF2A3245);
        darkText       = const Color(0xFFE8EDF5);
        darkSubtext    = const Color(0xFF8B95A9);
      } else {
        // Светлая (Basic)
        brandPrimary   = const Color(0xFFD97706); // Rich Amber (4.6:1 WCAG AA)
        brandSecondary = const Color(0xFFB45309); // Warm Amber
        brandTertiary  = const Color(0xFF0D9488); // Teal
        
        lightBg        = const Color(0xFFF3F4F8); // Clean Light Grey
        lightSurface   = const Color(0xFFFFFFFF); // Pure White
        lightCard      = const Color(0xFFFFFFFF); // Pure White Card
        lightCardHover = const Color(0xFFECEEF2);
        lightTrackBg   = const Color(0xFFE2E6ED); // Distinct Track
        lightBorder    = const Color(0xFFCBD5E1); // Clean Border
        lightText      = const Color(0xFF0E1016); // Dark Text
        lightSubtext   = const Color(0xFF4B5563); // Subtext
      }
    }
  }

  // Alias for backward compatibility
  static void applyThemeVariant(String variant) {
    final isDark = variant.contains('dark') || variant == 'deep_ocean' || variant == 'basic';
    applyPalette(palette: variant, isDark: isDark);
  }
}
