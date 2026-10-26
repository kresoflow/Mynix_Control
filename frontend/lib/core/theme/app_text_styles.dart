import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // ── Display (крупные суммы на кассе) ──────────────────────────────────────
  static final TextStyle _display = GoogleFonts.jetBrainsMono(
    textStyle: const TextStyle(inherit: true),
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );
  static TextStyle get display => _display;

  // ── Headings ───────────────────────────────────────────────────────────────
  static final TextStyle _h1 = GoogleFonts.spaceGrotesk(
    textStyle: const TextStyle(inherit: true),
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static TextStyle get h1 => _h1;

  static final TextStyle _h2 = GoogleFonts.spaceGrotesk(
    textStyle: const TextStyle(inherit: true),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get h2 => _h2;

  static final TextStyle _h3 = GoogleFonts.spaceGrotesk(
    textStyle: const TextStyle(inherit: true),
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get h3 => _h3;

  // ── Body ───────────────────────────────────────────────────────────────────
  static final TextStyle _bodyLarge = GoogleFonts.inter(
    textStyle: const TextStyle(inherit: true),
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static TextStyle get bodyLarge => _bodyLarge;

  static final TextStyle _body = GoogleFonts.inter(
    textStyle: const TextStyle(inherit: true),
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static TextStyle get body => _body;

  static final TextStyle _bodyMedium = GoogleFonts.inter(
    textStyle: const TextStyle(inherit: true),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static TextStyle get bodyMedium => _bodyMedium;

  // ── Caption ────────────────────────────────────────────────────────────────
  static final TextStyle _caption = GoogleFonts.inter(
    textStyle: const TextStyle(inherit: true),
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  static TextStyle get caption => _caption;

  // ── Mono (табличные финансовые расчеты) ──────────────────────────────────
  static final TextStyle _mono = GoogleFonts.jetBrainsMono(
    textStyle: const TextStyle(inherit: true),
    fontSize: 13,
  );
  static TextStyle get mono => _mono;

  static final TextStyle _monoBold = GoogleFonts.jetBrainsMono(
    textStyle: const TextStyle(inherit: true),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get monoBold => _monoBold;

  // ── Price (цены в сетке товаров) ──────────────────────────────────────────
  static TextStyle get price => GoogleFonts.jetBrainsMono(
    textStyle: const TextStyle(inherit: true),
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.brandPrimary,
  );

  static final TextStyle _priceLarge = GoogleFonts.jetBrainsMono(
    textStyle: const TextStyle(inherit: true),
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );
  static TextStyle get priceLarge => _priceLarge;

  // ── Button ─────────────────────────────────────────────────────────────────
  static final TextStyle _button = GoogleFonts.spaceGrotesk(
    textStyle: const TextStyle(inherit: true),
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  static TextStyle get button => _button;

  static final TextStyle _buttonLarge = GoogleFonts.spaceGrotesk(
    textStyle: const TextStyle(inherit: true),
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  static TextStyle get buttonLarge => _buttonLarge;

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
