// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Токены отступов и пространств (AppSpacing)
// ДОМЕН: lib/core/theme/app_spacing.dart
// ==============================================================================

import 'package:flutter/widgets.dart';

/// [UI-KIT] Единый реестр константных отступов 8pt-сетки Kreso Flow.
///
/// Использование константных отступов полностью исключает аллокацию памяти
/// и гарантирует идеальное визуальное выравнивание по всей системе.
abstract class AppSpacing {
  // ── Скалярные значения (double) ───────────────────────────────────────────
  static const double xxs = 2.0;
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double section = 32.0;

  // ── Вертикальные константные спейсеры (SizedBox) ──────────────────────────
  static const SizedBox vXxs = SizedBox(height: xxs);
  static const SizedBox vXs  = SizedBox(height: xs);
  static const SizedBox vSm  = SizedBox(height: sm);
  static const SizedBox vMd  = SizedBox(height: md);
  static const SizedBox vLg  = SizedBox(height: lg);
  static const SizedBox vXl  = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);

  // ── Горизонтальные константные спейсеры (SizedBox) ────────────────────────
  static const SizedBox hXxs = SizedBox(width: xxs);
  static const SizedBox hXs  = SizedBox(width: xs);
  static const SizedBox hSm  = SizedBox(width: sm);
  static const SizedBox hMd  = SizedBox(width: md);
  static const SizedBox hLg  = SizedBox(width: lg);
  static const SizedBox hXl  = SizedBox(width: xl);
  static const SizedBox hXxl = SizedBox(width: xxl);

  // ── Константные EdgeInsets ───────────────────────────────────────────────
  static const EdgeInsets pXxs = EdgeInsets.all(xxs);
  static const EdgeInsets pXs  = EdgeInsets.all(xs);
  static const EdgeInsets pSm  = EdgeInsets.all(sm);
  static const EdgeInsets pMd  = EdgeInsets.all(md);
  static const EdgeInsets pLg  = EdgeInsets.all(lg);
  static const EdgeInsets pXl  = EdgeInsets.all(xl);
  static const EdgeInsets pXxl = EdgeInsets.all(xxl);

  static const EdgeInsets pCard = EdgeInsets.all(lg);
  static const EdgeInsets pDialog = EdgeInsets.fromLTRB(xxl, xl, xxl, xl);
}
