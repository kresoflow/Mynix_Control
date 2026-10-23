// ==============================================================================
// МОДУЛЬ: POS / Открытие смены (OpenShiftModal)
// ДОМЕН: lib/features/pos/view/widgets/open_shift_modal.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Модальный экран открытия кассовой смены:
// 1. Предоставляет компактный диалог и полноразмерную посадочную карточку.
// 2. Требует обязательного внесения разменного фонда для начала операций.
// 3. Использует официальные токены дизайн-системы (AppRadii, AppColors, AppButton).
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_text_field.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_card_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';

// ── 1. Компактный диалог открытия смены ───────────────────────────────────────

void showOpenShiftDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _OpenShiftDialog(),
  );
}

class _OpenShiftDialog extends StatefulWidget {
  const _OpenShiftDialog();

  @override
  State<_OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<_OpenShiftDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCardDialog(
      title: 'Открытие смены',
      subtitle: 'Внесите разменный фонд в кассу для начала смены',
      icon: PhosphorIconsRegular.wallet,
      width: 420,
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          label: 'Открыть смену',
          onPressed: () {
            final amount = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0.0;
            context.read<ShiftBloc>().add(OpenShiftRequested(amount));
            Navigator.of(context).pop();
          },
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _controller,
            labelText: 'Разменный фонд (с)',
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(PhosphorIconsRegular.money, size: 18),
            autofocus: true,
          ),
        ],
      ),
    );
  }
}

// ── 2. Посадочная карточка открытия смены (Полноразмерная) ───────────────────

class OpenShiftModal extends StatefulWidget {
  const OpenShiftModal({super.key});

  @override
  State<OpenShiftModal> createState() => _OpenShiftModalState();
}

class _OpenShiftModalState extends State<OpenShiftModal> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: AppColors.transparent,
            child: Container(
              width: isMobile ? screenWidth - 32 : 420,
              padding: EdgeInsets.all(isMobile ? 24 : 40),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: isMobile ? AppRadii.cardRadius : AppRadii.dialogRadius,
                boxShadow: AppShadows.dialog,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.wallet,
                      size: isMobile ? 40 : 56,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20 : 32),
                  Text(
                    'Открытие смены',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.vSm,
                  Text(
                    'Внесите разменный фонд в кассу для начала рабочего дня.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.h2.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      labelText: 'Разменный фонд (с)',
                      labelStyle: AppTextStyles.body.copyWith(color: AppColors.brandPrimary),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.2)
                          : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.cardRadius,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadii.cardRadius,
                        borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 36),
                  AppPrimaryButton(
                    label: 'ОТКРЫТЬ СМЕНУ',
                    size: AppButtonSize.xl,
                    isFullWidth: true,
                    onPressed: () {
                      final amount = double.tryParse(_amountController.text) ?? 0.0;
                      context.read<ShiftBloc>().add(OpenShiftRequested(amount));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
