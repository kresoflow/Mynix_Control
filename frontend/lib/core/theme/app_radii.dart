import 'package:flutter/material.dart';

/// Mynix Design System — Border Radius Tokens
abstract class AppRadii {
  // Базовые скругления
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double max = 999.0; // Для полностью круглых кнопок/аватаров

  // Семантические скругления
  static const double button = lg; // 12.0
  static const double input = lg; // 12.0
  static const double card = xl; // 16.0
  static const double dialog = xxl; // 24.0
  static const double badge = sm; // 4.0

  // BorderRadius объекты (готовые к использованию в BoxDecoration)
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius inputRadius = BorderRadius.circular(input);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius dialogRadius = BorderRadius.circular(dialog);
  static final BorderRadius badgeRadius = BorderRadius.circular(badge);
  static final BorderRadius maxRadius = BorderRadius.circular(max);
}
