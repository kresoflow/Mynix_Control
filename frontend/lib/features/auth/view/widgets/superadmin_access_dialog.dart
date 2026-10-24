// ==============================================================================
// МОДУЛЬ: Авторизация / Диалог доступа супер-администратора
// ДОМЕН: lib/features/auth/view/widgets/superadmin_access_dialog.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [БЕЗОПАСНОСТЬ] Ввод мастер-токена доступа к платформе:
// 1. Скрытый доступ по долгому нажатию на логотип / заголовок.
// 2. Инициализирует SuperadminBloc с системным мастер-токеном.
//
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_text_field.dart';
import 'package:kreso_frontend/features/superadmin/bloc/superadmin_bloc.dart';
import 'package:kreso_frontend/features/superadmin/repository/superadmin_repository.dart';
import 'package:kreso_frontend/features/superadmin/view/superadmin_screen.dart';

class SuperadminAccessDialog {
  const SuperadminAccessDialog._();

  static Future<void> show(BuildContext context) async {
    final defaultToken = kDebugMode ? 'super_secret_kreso_token_2026' : '';
    final controller = TextEditingController(text: defaultToken);
    try {
      await showDialog(
        context: context,
        builder: (ctx) => AppDialog(
          title: 'Супер-администратор',
          icon: PhosphorIconsRegular.shieldCheck,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Введите мастер-токен для доступа к платформе:',
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: controller,
                labelText: 'Мастер-токен',
                hintText: 'токен доступа...',
                obscureText: true,
                prefixIcon: const Icon(PhosphorIconsRegular.key, size: 18),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Dev токен: super_secret_kreso_token_2026',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPrimary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            AppGhostButton(
              label: 'Отмена',
              onPressed: () => Navigator.pop(ctx),
            ),
            AppPrimaryButton(
              label: 'Войти',
              icon: PhosphorIconsRegular.signIn,
              onPressed: () {
                final token = controller.text.trim();
                Navigator.pop(ctx);
                if (token.isNotEmpty) {
                  final apiClient = context.read<ApiClient>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => SuperadminBloc(
                          repository: SuperadminRepository(dio: apiClient.dio),
                        ),
                        child: SuperadminScreen(systemToken: token),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
