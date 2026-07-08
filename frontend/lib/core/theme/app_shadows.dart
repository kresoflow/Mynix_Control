import 'package:flutter/material.dart';

/// Mynix Design System — BoxShadow Tokens
abstract class AppShadows {
  // Легкая тень (для карточек в светлой теме)
  static final List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Средняя тень (для дропдаунов, небольших модалок)
  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Глубокая тень (для главных диалогов и bottom sheets)
  static final List<BoxShadow> deep = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];
  
  // Тень для акцентных кнопок (бренд цвет)
  static List<BoxShadow> primaryButton(Color brandColor) => [
    BoxShadow(
      color: brandColor.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
