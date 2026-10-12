// ==============================================================================
// МОДУЛЬ: Ядро / Форматирование ролей и бейджей сотрудников
// ДОМЕН: lib/core/utils/role_formatter.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

// ─── 1. Форматтер и фабрика бейджей ролей ────────────────────────────────────
/// Вспомогательный класс для отображения человекопонятных названий,
/// семантических иконок, цветов и бейджей ролей персонала в Kreso Flow.
class RoleFormatter {
  /// Возвращает локализованное название роли.
  static String formatName(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return 'Владелец платформы';
    if (r == 'owner') return 'Владелец заведения';
    if (r == 'manager') return 'Управляющий';
    if (r == 'cashier') return 'Кассир';
    return role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1)}' : 'Сотрудник';
  }

  /// Возвращает Phosphor-иконку для роли.
  static IconData getRoleIcon(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return PhosphorIconsRegular.lightning;
    if (r == 'owner') return PhosphorIconsRegular.crown;
    if (r == 'manager') return PhosphorIconsRegular.briefcase;
    if (r == 'cashier') return PhosphorIconsRegular.receipt;
    return PhosphorIconsRegular.user;
  }

  /// Возвращает семантический цвет дизайн-системы для роли.
  static Color getRoleColor(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return AppColors.danger;
    if (r == 'owner') return AppColors.brandPrimary;
    if (r == 'manager') return AppColors.info;
    if (r == 'cashier') return AppColors.success;
    return AppColors.brandSecondary;
  }

  /// Возвращает вариант бейджа AppStatusBadge для роли.
  static AppBadgeVariant getRoleVariant(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return AppBadgeVariant.danger;
    if (r == 'owner') return AppBadgeVariant.brand;
    if (r == 'manager') return AppBadgeVariant.info;
    if (r == 'cashier') return AppBadgeVariant.success;
    return AppBadgeVariant.neutral;
  }

  /// Создает стандартизированный бейдж роли на базе UI Kit компонента AppStatusBadge.
  static Widget buildBadge(String role) {
    final label = formatName(role);
    final icon = getRoleIcon(role);
    final variant = getRoleVariant(role);

    return AppStatusBadge(
      label: label,
      icon: icon,
      variant: variant,
    );
  }
}
