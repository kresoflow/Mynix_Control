// ============================================================================
// Kreso Flow | Superadmin View | Error View Widget
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';

// ─── 1. Error Display Widget ────────────────────────────────────────────────

class SuperadminErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const SuperadminErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTokenError = message.contains('Invalid System Admin Token');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.buttonRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTokenError ? PhosphorIconsRegular.lockKey : PhosphorIconsRegular.warningCircle,
                color: AppColors.danger,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTokenError ? 'Неверный мастер-токен' : 'Ошибка доступа',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isTokenError
                  ? 'Указанный системный токен отклонён сервером (403 Forbidden).\nДля управления мульти-тенант кластером требуется актуальный system_admin_token из конфигурации бэкенда.\n(В dev-режиме: super_secret_kreso_token_2026)'
                  : message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSecondaryButton(
                  label: 'Назад ко входу',
                  icon: PhosphorIconsRegular.arrowLeft,
                  size: AppButtonSize.md,
                  onPressed: onBack,
                ),
                const SizedBox(width: 12),
                AppPrimaryButton(
                  label: 'Повторить',
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  size: AppButtonSize.md,
                  onPressed: onRetry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
