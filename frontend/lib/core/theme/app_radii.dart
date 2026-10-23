import 'package:flutter/material.dart';

/// Kreso Flow Design System — Strict SaaS Border Radius Tokens
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
  static const double pill   = 24.0;

  // BorderRadius объекты (Компилируются в const для нулевой нагрузки на GC)
  static const BorderRadius inputRadius  = BorderRadius.all(Radius.circular(input));
  static const BorderRadius tabRadius    = BorderRadius.all(Radius.circular(tab));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardRadius   = BorderRadius.all(Radius.circular(card));
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(dialog));
  static const BorderRadius badgeRadius  = BorderRadius.all(Radius.circular(badge));
  static const BorderRadius pillRadius   = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius maxRadius    = BorderRadius.all(Radius.circular(max));

  // Константные алиасы по базовой шкале
  static const BorderRadius radiusXs  = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl  = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));
}
