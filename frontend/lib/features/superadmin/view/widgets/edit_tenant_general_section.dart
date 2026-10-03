// ============================================================================
// Kreso Flow | Superadmin View | Edit Tenant General Section
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'tenant_form_field.dart';

// ─── 1. General Settings Section ────────────────────────────────────────────

class EditTenantGeneralSection extends StatelessWidget {
  final String schemaName;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController currencyController;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  const EditTenantGeneralSection({
    super.key,
    required this.schemaName,
    required this.nameController,
    required this.addressController,
    required this.currencyController,
    required this.isActive,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Информационный баннер схемы PostgreSQL
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: AppRadii.inputRadius,
            border: Border.all(
              color: AppColors.brandPrimary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.database, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 10),
              Text(
                'Схема PostgreSQL: ',
                style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.w600),
              ),
              Text(
                schemaName,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Название заведения
        TenantFormField(
          label: 'Название ресторана *',
          hint: 'Например: Family Cafe & Bar',
          icon: PhosphorIconsRegular.storefront,
          controller: nameController,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Введите название ресторана';
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Валюта и адрес в строку/колонку
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: TenantFormField(
                label: 'Фактический адрес',
                hint: 'г. Бишкек, пр. Чуй 140',
                icon: PhosphorIconsRegular.mapPin,
                controller: addressController,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TenantFormField(
                label: 'Валюта',
                hint: 'сом (с)',
                icon: PhosphorIconsRegular.currencyCircleDollar,
                controller: currencyController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Статус активности заведения
        Container(
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
                isActive ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.prohibit,
                size: 20,
                color: isActive ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Заведение активно' : 'Заведение заморожено',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    Text(
                      isActive
                          ? 'Кассы и персонал могут пробивать чеки'
                          : 'Вход на терминалы заблокирован для персонала',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                activeThumbColor: AppColors.success,
                activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                onChanged: onActiveChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
