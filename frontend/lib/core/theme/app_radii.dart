import 'package:flutter/material.dart';

/// Mynix Design System — Strict SaaS Border Radius Tokens
abstract class AppRadii {
  // Базовые скругления (Strict & Sharp)
  static const double xs  = 4.0;
  static const double sm  = 6.0;
  static const double md  = 8.0;   // Поля ввода, вкладки, бейджи, ячейки
  static const double lg  = 12.0;  // Кнопки действия, внутренние контейнеры
  static const double xl  = 16.0;  // Карточки и панели
  static const double xxl = 20.0;  // Окна модалок и диалогов
  static const double max = 999.0;

  // Семантические скругления
  static const double input  = md;  // 8.0
  static const double tab    = md;  // 8.0
  static const double button = lg;  // 12.0
  static const double card   = xl;  // 16.0
  static const double dialog = xxl; // 20.0
  static const double badge  = sm;  // 6.0

  // BorderRadius объекты
  static final BorderRadius inputRadius  = BorderRadius.circular(input);
  static final BorderRadius tabRadius    = BorderRadius.circular(tab);
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius cardRadius   = BorderRadius.circular(card);
  static final BorderRadius dialogRadius = BorderRadius.circular(dialog);
  static final BorderRadius badgeRadius  = BorderRadius.circular(badge);
  static final BorderRadius maxRadius    = BorderRadius.circular(max);
}
