import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';

Future<void> showLogoutConfirmDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const LogoutConfirmDialog(),
  );
}

class LogoutConfirmDialog extends StatefulWidget {
  const LogoutConfirmDialog({super.key});

  @override
  State<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<LogoutConfirmDialog> {
  late final Future<List<Map<String, dynamic>>> _activeTablesFuture;

  @override
  void initState() {
    super.initState();
    _activeTablesFuture = _loadActiveTables();
  }

  Future<List<Map<String, dynamic>>> _loadActiveTables() async {
    try {
      final repo = context.read<OrderRepository>();
      return await repo.fetchActiveTables();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isShiftOpen = context.read<ShiftBloc>().state is ShiftOpen;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activeTablesFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final activeTables = snapshot.data ?? [];
        final hasActiveTables = activeTables.isNotEmpty;

        return AppDialog(
          title: hasActiveTables ? 'Внимание: открытые столы!' : 'Выход из системы',
          icon: hasActiveTables
              ? PhosphorIconsRegular.warning
              : PhosphorIconsRegular.signOut,
          isDestructive: hasActiveTables,
          width: 440,
          content: isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasActiveTables) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: isDark ? 0.16 : 0.08),
                          borderRadius: AppRadii.inputRadius,
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.warningCircle,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Обнаружено столов в зале: ${activeTables.length}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'В зале есть столы с открытыми заказами. Если выйти сейчас, заказы останутся активными.',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isShiftOpen) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: AppRadii.inputRadius,
                          border: Border.all(
                            color: AppColors.brandPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIconsRegular.cashRegister,
                              size: 18,
                              color: AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Кассовая смена открыта',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkText : AppColors.lightText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Смена останется открытой для кассиров. Вы сможете войти снова.',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Вы действительно хотите выйти из своего аккаунта?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
          actions: [
            AppGhostButton(
              label: 'Остаться',
              onPressed: () => Navigator.pop(context),
            ),
            AppDangerButton(
              label: 'Выйти из системы',
              icon: PhosphorIconsRegular.signOut,
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(LoggedOut());
              },
            ),
          ],
        );
      },
    );
  }
}
