import 'package:flutter/material.dart';

/// Mynix Design System — BoxShadow & Ambient Glow Tokens
abstract class AppShadows {
  // Легкая тень для светлой темы
  static final List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Средняя тень
  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Глубокая тень для модалок и диалогов
  static final List<BoxShadow> deep = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.65),
      blurRadius: 48,
      spreadRadius: 0,
      offset: const Offset(0, 16),
    ),
  ];
  
  // Ambient Glow для главных кнопок действия
  static List<BoxShadow> buttonGlow(Color brandColor) => [
    BoxShadow(
      color: brandColor.withValues(alpha: 0.40),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
  ];

  // Активная вкладка / селектор
  static List<BoxShadow> tabGlow(Color brandColor) => [
    BoxShadow(
      color: brandColor.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  // Legacy alias
  static List<BoxShadow> primaryButton(Color brandColor) => buttonGlow(brandColor);
}
