import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class CreateTenantModulesSection extends StatelessWidget {
  final bool useKds;
  final bool enableInventoryDeduction;
  final ValueChanged<bool> onKdsChanged;
  final ValueChanged<bool> onInventoryChanged;

  const CreateTenantModulesSection({
    super.key,
    required this.useKds,
    required this.enableInventoryDeduction,
    required this.onKdsChanged,
    required this.onInventoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(PhosphorIconsRegular.gear, size: 18, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              '3. Модули и возможности',
              style: AppTextStyles.h3.copyWith(
                fontSize: 15,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSwitchRow(
          context: context,
          isDark: isDark,
          title: 'Кухонный дисплей (KDS)',
          subtitle: 'Заказы с кассы мгновенно поступают на экран кухни поварам',
          value: useKds,
          onChanged: onKdsChanged,
          icon: PhosphorIconsRegular.cookingPot,
        ),
        const SizedBox(height: 10),
        _buildSwitchRow(
          context: context,
          isDark: isDark,
          title: 'Складской учет и автосписание',
          subtitle: 'Списание ингредиентов по техкартам и контроль остатков сырья',
          value: enableInventoryDeduction,
          onChanged: onInventoryChanged,
          icon: PhosphorIconsRegular.package,
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.brandPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
