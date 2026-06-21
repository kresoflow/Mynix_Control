import 'package:flutter/material.dart';

/// Mynix Ember — Brand Color System
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color brandPrimary   = Color(0xFFE8A020); // Amber Gold
  static const Color brandSecondary = Color(0xFFFF6B35); // Warm Coral
  static const Color brandTertiary  = Color(0xFF2DD4BF); // Teal Mint

  // ── Dark Theme Surfaces ────────────────────────────────────────────────────
  static const Color darkBg         = Color(0xFF0E1016);
  static const Color darkSurface    = Color(0xFF161B22);
  static const Color darkCard       = Color(0xFF1C2130);
  static const Color darkCardHover  = Color(0xFF212840);
  static const Color darkBorder     = Color(0xFF2A3245);
  static const Color darkText       = Color(0xFFE8EDF5);
  static const Color darkSubtext    = Color(0xFF8B95A9);

  // ── Light Theme Surfaces ───────────────────────────────────────────────────
  static const Color lightBg        = Color(0xFFF3F4F8);
  static const Color lightSurface   = Color(0xFFFFFFFF);
  static const Color lightCard      = Color(0xFFFFFFFF);
  static const Color lightBorder    = Color(0xFFE2E6ED);
  static const Color lightText      = Color(0xFF0E1016);
  static const Color lightSubtext   = Color(0xFF6B7280);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger  = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPrimary, brandSecondary],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A020), Color(0xFFFF6B35)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C2130), Color(0xFF161B22)],
  );
}
