import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'tenant_form_field.dart';

class CreateTenantBusinessSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController schemaController;
  final TextEditingController currencyController;
  final TextEditingController addressController;
  final ValueChanged<String> onSchemaManualChanged;

  const CreateTenantBusinessSection({
    super.key,
    required this.nameController,
    required this.schemaController,
    required this.currencyController,
    required this.addressController,
    required this.onSchemaManualChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(PhosphorIconsRegular.buildings, size: 18, color: AppColors.brandPrimary),
            const SizedBox(width: 8),
            Text(
              '1. Данные Заведения (Бизнес)',
              style: AppTextStyles.h3.copyWith(
                fontSize: 15,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TenantFormField(
          label: 'Название ресторана',
          hint: 'Например: Krunchy Burger & Co',
          icon: PhosphorIconsRegular.textT,
          controller: nameController,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TenantFormField(
                label: 'Схема БД (Автогенерация)',
                hint: 'krunchy_burger',
                icon: PhosphorIconsRegular.database,
                controller: schemaController,
                onChanged: onSchemaManualChanged,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Укажите схему БД';
                  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val)) {
                    return 'Только латинские буквы, цифры и подчеркивание';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TenantFormField(
                label: 'Валюта заведения',
                hint: 'сом (с)',
                icon: PhosphorIconsRegular.currencyCircleDollar,
                controller: currencyController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TenantFormField(
          label: 'Адрес заведения',
          hint: 'г. Бишкек, пр. Чуй 140',
          icon: PhosphorIconsRegular.mapPin,
          controller: addressController,
          isRequired: false,
        ),
      ],
    );
  }
}
