import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class RoleFormatter {
  static String formatName(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return 'Владелец платформы';
    if (r == 'owner') return 'Владелец заведения';
    if (r == 'manager') return 'Управляющий';
    if (r == 'cashier') return 'Кассир';
    if (r == 'cook') return 'Шеф-повар';
    if (r == 'admin') return 'Администратор';
    return role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1)}' : 'Сотрудник';
  }

  static IconData getRoleIcon(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return PhosphorIconsRegular.lightning;
    if (r == 'owner') return PhosphorIconsRegular.crown;
    if (r == 'manager') return PhosphorIconsRegular.briefcase;
    if (r == 'cashier') return PhosphorIconsRegular.receipt;
    if (r == 'cook') return PhosphorIconsRegular.cookingPot;
    return PhosphorIconsRegular.user;
  }

  static Color getRoleColor(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'superadmin' || r == 'platform_owner') return const Color(0xFFEC4899); // Rose
    if (r == 'owner') return AppColors.brandPrimary; // Golden Orange
    if (r == 'manager') return const Color(0xFF818CF8); // Indigo
    if (r == 'cashier') return const Color(0xFF10B981); // Emerald
    if (r == 'cook') return const Color(0xFFF59E0B); // Amber
    return AppColors.brandPrimary;
  }

  static Widget buildBadge(String role, {double fontSize = 11}) {
    final color = getRoleColor(role);
    final label = formatName(role);
    final icon = getRoleIcon(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
