// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Централизованный реестр анимаций и движения
// ДОМЕН: lib/core/theme/app_motion.dart
// ==============================================================================

import 'package:flutter/widgets.dart';

/// Единый источник истины (SSOT) для параметров анимации в Kreso Flow.
/// 
/// Предоставляет стандартизированные тайминги, кривые плавности и глобальный
/// флаг отключения анимаций (Instant Touch) для сенсорных POS-терминалов.
abstract class AppMotion {
  // ─── 1. Стандартизированные тайминги ─────────────────────────────────────────

  /// Быстрые микро-анимации (100 мс): ховеры кнопок, нажатия, тумблеры, чекбоксы
  static const Duration fastDuration = Duration(milliseconds: 100);

  /// Стандартные компонентные анимации (180 мс): табы, аккордеоны, чипы, смена иконок
  static const Duration standardDuration = Duration(milliseconds: 180);

  /// Модальные и контекстные переходы (250 мс): появление диалогов, шторки, дропдауны
  static const Duration modalDuration = Duration(milliseconds: 250);

  /// Крупные экранные переходы (320 мс): смена страниц, выдвижные боковые панели
  static const Duration pageDuration = Duration(milliseconds: 320);

  // ─── 2. Стандартизированные кривые плавности ─────────────────────────────────

  /// Основная органичная кривая (easeOutCubic) — плавный вход и естественное замедление
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Кривая акцентированного входа (decelerate) — быстрое появление модальных окон
  static const Curve enterCurve = Curves.decelerate;

  /// Кривая плавного затухания (easeInCubic) — закрытие шторок и исчезновение подсказок
  static const Curve exitCurve = Curves.easeInCubic;

  /// Пружинящая кривая (elastic/bounce) для тактильного отклика бейджей и счетчиков
  static const Curve bounceCurve = Curves.easeOutBack;

  // ─── 3. Режим мгновенного отклика (Instant Touch / POS Mode) ──────────────────

  /// Глобальный флаг принудительного отключения анимаций.
  /// 
  /// При значении `true` все анимации интерфейса становятся мгновенными (Duration.zero),
  /// исключая задержки отклика и подвисания на сенсорных кассовых терминалах.
  static bool disableAnimations = false;

  /// Возвращает адаптированную длительность с учетом режима сенсорного терминала.
  static Duration duration(Duration normalDuration) {
    if (disableAnimations) return Duration.zero;
    return normalDuration;
  }

  /// Адаптированная быстрая длительность
  static Duration get fast => duration(fastDuration);

  /// Адаптированная стандартная длительность
  static Duration get standard => duration(standardDuration);

  /// Адаптированная модальная длительность
  static Duration get modal => duration(modalDuration);

  /// Адаптированная экранная длительность
  static Duration get page => duration(pageDuration);

  // ─── 4. Утилиты переходов и построения анимаций ─────────────────────────────

  /// Возвращает анимацию затухания и масштабирования для модальных окон
  static Widget scaleFadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    if (disableAnimations) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: enterCurve,
      reverseCurve: exitCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}

