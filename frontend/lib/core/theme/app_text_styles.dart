import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // ── Display (крупные суммы на кассе) ──────────────────────────────────────
  static TextStyle get display => GoogleFonts.jetBrainsMono(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  ).copyWith(inherit: true);

  // ── Headings ───────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  ).copyWith(inherit: true);

  static TextStyle get h2 => GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ).copyWith(inherit: true);

  static TextStyle get h3 => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ).copyWith(inherit: true);

  // ── Body ───────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  ).copyWith(inherit: true);

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  ).copyWith(inherit: true);

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ).copyWith(inherit: true);

  // ── Caption ────────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  ).copyWith(inherit: true);

  // ── Price (цены в сетке товаров) ──────────────────────────────────────────
  static TextStyle get price => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.brandPrimary,
  ).copyWith(inherit: true);

  static TextStyle get priceLarge => GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  ).copyWith(inherit: true);

  // ── Button ─────────────────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  ).copyWith(inherit: true);

  static TextStyle get buttonLarge => GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  ).copyWith(inherit: true);

  // ── TextTheme для ThemeData ────────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
  );
}
