import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'tenant_form_field.dart';

class CreateTenantOwnerSection extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController pinController;

  const CreateTenantOwnerSection({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.pinController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(PhosphorIconsRegular.shieldCheck, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              '2. Данные Владельца (Owner)',
              style: AppTextStyles.h3.copyWith(
                fontSize: 15,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TenantFormField(
          label: 'ФИО Владельца',
          hint: 'Алмазов Данияр Русланович',
          icon: PhosphorIconsRegular.user,
          controller: fullNameController,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TenantFormField(
                label: 'Телефон владельца',
                hint: '+996 (555) 01-23-45',
                icon: PhosphorIconsRegular.phone,
                controller: phoneController,
                isRequired: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TenantFormField(
                label: 'Email владельца',
                hint: 'owner@krunchyburger.test',
                icon: PhosphorIconsRegular.envelope,
                controller: emailController,
                isRequired: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TenantFormField(
                label: 'Логин',
                hint: 'daniyar_owner',
                icon: PhosphorIconsRegular.identificationCard,
                controller: usernameController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TenantFormField(
                label: 'Пароль',
                icon: PhosphorIconsRegular.lockKey,
                isPassword: true,
                controller: passwordController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TenantFormField(
                label: 'PIN кассы',
                hint: '1234',
                icon: PhosphorIconsRegular.key,
                controller: pinController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
