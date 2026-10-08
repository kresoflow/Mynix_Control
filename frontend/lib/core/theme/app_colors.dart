import 'package:flutter/material.dart';

/// Kreso Flow Brand Color System — Dynamic Theme Tokens
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

  // ── Contextual Semantic Resolvers ──────────────────────────────────────────
  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color cardHover(bool isDark) => isDark ? darkCardHover : lightCardHover;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color text(bool isDark) => isDark ? darkText : lightText;
  static Color subtext(bool isDark) => isDark ? darkSubtext : lightSubtext;
  static Color trackBg(bool isDark) => isDark ? darkTrackBg : lightTrackBg;

  // ── Dynamic Theming ────────────────────────────────────────────────────────
  static void applyPalette({required dynamic palette, bool isDark = true}) {
    final paletteStr = palette.toString().toLowerCase();

    if (paletteStr.contains('ocean') || paletteStr == 'deep_ocean' || paletteStr.contains('contrast') || paletteStr == 'high_contrast_light') {
      // 🌊 Ocean / Contrast Pair
      darkBg         = const Color(0xFF050B14);
      darkSurface    = const Color(0xFF0A1220);
      darkCard       = const Color(0xFF0E1A2D);
      darkCardHover  = const Color(0xFF15243C);
      darkTrackBg    = const Color(0xFF0E1A2D);
      darkBorder     = const Color(0xFF1E3250);
      darkText       = const Color(0xFFE0F2FE);
      darkSubtext    = const Color(0xFF7DD3FC);

      lightBg        = const Color(0xFFEAECEF);
      lightSurface   = const Color(0xFFFFFFFF);
      lightCard      = const Color(0xFFFFFFFF);
      lightCardHover = const Color(0xFFF1F5F9);
      lightTrackBg   = const Color(0xFFE2E8F0);
      lightBorder    = const Color(0xFFCBD5E1);
      lightText      = const Color(0xFF0F172A);
      lightSubtext   = const Color(0xFF475569);

      brandPrimary   = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      brandSecondary = isDark ? const Color(0xFF0284C7) : const Color(0xFF0369A1);
      brandTertiary  = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    } else if (paletteStr.contains('cream') || paletteStr == 'soft_cream') {
      // ☕ Cream / Espresso Pair
      darkBg         = const Color(0xFF141210);
      darkSurface    = const Color(0xFF1C1917);
      darkCard       = const Color(0xFF292524);
      darkCardHover  = const Color(0xFF383330);
      darkTrackBg    = const Color(0xFF292524);
      darkBorder     = const Color(0xFF44403C);
      darkText       = const Color(0xFFF5F5F4);
      darkSubtext    = const Color(0xFFA8A29E);

      lightBg        = const Color(0xFFF8F5EE);
      lightSurface   = const Color(0xFFFCFAF5);
      lightCard      = const Color(0xFFFCFAF5);
      lightCardHover = const Color(0xFFF1EDE4);
      lightTrackBg   = const Color(0xFFEBE6DC);
      lightBorder    = const Color(0xFFDCD5C9);
      lightText      = const Color(0xFF2C2724);
      lightSubtext   = const Color(0xFF78716C);

      brandPrimary   = isDark ? const Color(0xFFD97706) : const Color(0xFFB45309);
      brandSecondary = isDark ? const Color(0xFFB45309) : const Color(0xFF92400E);
      brandTertiary  = const Color(0xFF047857);
    } else {
      // 🔥 Basic / Ember Pair
      darkBg         = const Color(0xFF0E1016);
      darkSurface    = const Color(0xFF161B22);
      darkCard       = const Color(0xFF1C2130);
      darkCardHover  = const Color(0xFF212840);
      darkTrackBg    = const Color(0xFF1C2130);
      darkBorder     = const Color(0xFF2A3245);
      darkText       = const Color(0xFFE8EDF5);
      darkSubtext    = const Color(0xFF8B95A9);

      lightBg        = const Color(0xFFF3F4F8);
      lightSurface   = const Color(0xFFFFFFFF);
      lightCard      = const Color(0xFFFFFFFF);
      lightCardHover = const Color(0xFFECEEF2);
      lightTrackBg   = const Color(0xFFE2E6ED);
      lightBorder    = const Color(0xFFCBD5E1);
      lightText      = const Color(0xFF0E1016);
      lightSubtext   = const Color(0xFF4B5563);

      brandPrimary   = isDark ? const Color(0xFFE8A020) : const Color(0xFFD97706);
      brandSecondary = isDark ? const Color(0xFFFF6B35) : const Color(0xFFB45309);
      brandTertiary  = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
    }
  }

  // Alias for backward compatibility
  static void applyThemeVariant(String variant) {
    final isDark = variant.contains('dark') || variant == 'deep_ocean' || variant == 'basic';
    applyPalette(palette: variant, isDark: isDark);
  }
}
