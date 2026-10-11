// ============================================================================
// Kreso Flow | Superadmin View | Edit Tenant Modules Section
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ─── 1. Modules Configuration Section ───────────────────────────────────────

class EditTenantModulesSection extends StatelessWidget {
  final bool? useKds;
  final bool useOrders;
  final bool enableInventoryDeduction;
  final ValueChanged<bool>? onKdsChanged;
  final ValueChanged<bool> onOrdersChanged;
  final ValueChanged<bool> onInventoryChanged;

  const EditTenantModulesSection({
    super.key,
    this.useKds,
    required this.useOrders,
    required this.enableInventoryDeduction,
    this.onKdsChanged,
    required this.onOrdersChanged,
    required this.onInventoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModuleTile(
          title: 'Складской учет и автосписание',
          subtitle: 'Автоматическое списание ингредиентов по техкартам при оплате чека',
          value: enableInventoryDeduction,
          onChanged: onInventoryChanged,
          icon: PhosphorIconsRegular.package,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildModuleTile(
          title: 'Вкладка «Заказы» на кассе',
          subtitle: 'Управление столами, бронями, залами и очередью сохраненных заказов',
          value: useOrders,
          onChanged: onOrdersChanged,
          icon: PhosphorIconsRegular.receipt,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.brandPrimary,
            activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
