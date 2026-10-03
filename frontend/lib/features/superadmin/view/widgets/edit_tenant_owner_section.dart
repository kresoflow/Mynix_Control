// ============================================================================
// Kreso Flow | Superadmin View | Edit Tenant Owner Section
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'tenant_form_field.dart';

// ─── 1. Owner Profile Management Section ─────────────────────────────────────

class EditTenantOwnerSection extends StatelessWidget {
  final String? ownerUsername;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController pinController;
  final TextEditingController passwordController;

  const EditTenantOwnerSection({
    super.key,
    required this.ownerUsername,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.pinController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Баннер учетной записи владельца
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: AppRadii.inputRadius,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.shieldCheck, size: 18, color: AppColors.success),
              const SizedBox(width: 10),
              Text(
                'Логин владельца: ',
                style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
              ),
              Text(
                ownerUsername?.isNotEmpty == true ? ownerUsername! : 'не назначен',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ФИО владельца
        TenantFormField(
          label: 'ФИО Владельца',
          hint: 'Алмазов Данияр Русланович',
          icon: PhosphorIconsRegular.user,
          controller: fullNameController,
          isRequired: false,
        ),
        const SizedBox(height: 12),

        // Телефон и Email в одну строку
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TenantFormField(
                label: 'Телефон',
                hint: '+996 (555) 01-23-45',
                icon: PhosphorIconsRegular.phone,
                controller: phoneController,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TenantFormField(
                label: 'Email',
                hint: 'owner@restaurant.test',
                icon: PhosphorIconsRegular.envelope,
                controller: emailController,
                isRequired: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // PIN-код и новый пароль
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TenantFormField(
                label: 'PIN кассы (4 цифры)',
                hint: '1234',
                icon: PhosphorIconsRegular.key,
                controller: pinController,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: TenantFormField(
                label: 'Новый пароль (сброс)',
                hint: 'Оставьте пустым, если не меняется',
                icon: PhosphorIconsRegular.lockKey,
                isPassword: true,
                controller: passwordController,
                isRequired: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
