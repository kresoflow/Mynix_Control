// ==============================================================================
// МОДУЛЬ: Настройки / Витрина UI Kit / Секция компонентов Спринта 2
// ДОМЕН: lib/features/settings/view/widgets/showcase/showcase_sprint2_section.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// Витрина новых компонентов Спринта 2 (Approval Gate 1).
class ShowcaseSprint2Section extends StatefulWidget {
  final bool isDark;

  const ShowcaseSprint2Section({super.key, required this.isDark});

  @override
  State<ShowcaseSprint2Section> createState() => _ShowcaseSprint2SectionState();
}

class _ShowcaseSprint2SectionState extends State<ShowcaseSprint2Section> {
  num _stepperSmValue = 1.5;
  num _stepperMdValue = 3;
  num _stepperLgValue = 10;
  AppEmptyStateSize _emptySize = AppEmptyStateSize.md;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Шапка секции ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '9. Интерактивные компоненты (EmptyState, Stepper, ConfirmDialog)',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Компоненты ввода количества, пустых состояний и диалогов подтверждения.',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              const AppStatusBadge(
                label: 'УТВЕРЖДЕНО',
                variant: AppBadgeVariant.success,
                hasDot: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── БЛОК 1: AppQuantityStepper ────────────────────────────────────
          Text(
            'Счетчики количества (AppQuantityStepper: SM, MD, LG):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // SM (Таблицы)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SM (28px): ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  AppQuantityStepper(
                    value: _stepperSmValue,
                    size: AppStepperSize.sm,
                    step: 0.5,
                    allowDecimals: true,
                    unit: 'кг',
                    onChanged: (val) => setState(() => _stepperSmValue = val),
                    onRemove: () => AppToast.showInfo(context, 'Удаление строки'),
                  ),
                ],
              ),

              // MD (Корзины)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MD (36px): ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  AppQuantityStepper(
                    value: _stepperMdValue,
                    size: AppStepperSize.md,
                    unit: 'шт',
                    onChanged: (val) => setState(() => _stepperMdValue = val),
                    onRemove: () => AppToast.showInfo(context, 'Удаление из корзины'),
                  ),
                ],
              ),

              // LG (POS Touch)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('LG (44px POS): ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  AppQuantityStepper(
                    value: _stepperLgValue,
                    size: AppStepperSize.lg,
                    onChanged: (val) => setState(() => _stepperLgValue = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── БЛОК 2: AppConfirmDialog ──────────────────────────────────────
          Text(
            'Стандартизированные диалоги подтверждения (AppConfirmDialog):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Заменяют нестилизованный Material AlertDialog с поддержкой плавных переходов AppMotion.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              AppPrimaryButton(
                label: 'Диалог подтверждения',
                icon: PhosphorIconsRegular.question,
                size: AppButtonSize.sm,
                onPressed: () async {
                  final res = await AppConfirmDialog.show(
                    context: context,
                    title: 'Сохранить изменения?',
                    message: 'Все добавленные строки номенклатуры будут зафиксированы в черновике.',
                    confirmLabel: 'Сохранить',
                  );
                  if (context.mounted) {
                    AppToast.showInfo(context, res ? 'Подтверждено (true)' : 'Отменено (false)');
                  }
                },
              ),
              AppDangerButton(
                label: 'Опасное действие (Danger)',
                icon: PhosphorIconsRegular.trash,
                size: AppButtonSize.sm,
                onPressed: () async {
                  final res = await AppConfirmDialog.show(
                    context: context,
                    title: 'Очистить всю накладную?',
                    message: 'Это действие необратимо. Будут удалены все 14 позиций из текущего документа.',
                    confirmLabel: 'Удалить всё',
                    isDanger: true,
                  );
                  if (context.mounted) {
                    AppToast.showInfo(context, res ? 'Удалено (true)' : 'Отменено (false)');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── БЛОК 3: AppEmptyState ─────────────────────────────────────────
          Row(
            children: [
              Text(
                'Пустое состояние (AppEmptyState):',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              AppSegmentedControl<AppEmptyStateSize>(
                selectedValue: _emptySize,
                size: AppSegmentedSize.sm,
                onValueChanged: (val) => setState(() => _emptySize = val),
                items: const [
                  AppSegmentedItem(value: AppEmptyStateSize.sm, label: 'SM'),
                  AppSegmentedItem(value: AppEmptyStateSize.md, label: 'MD'),
                  AppSegmentedItem(value: AppEmptyStateSize.lg, label: 'LG'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: AppRadii.radiusLg,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: AppEmptyState(
              icon: PhosphorIconsRegular.shoppingBagOpen,
              title: 'В корзине пока пусто',
              description: 'Выберите блюда или напитки из меню слева, чтобы сформировать заказ гостя.',
              size: _emptySize,
              action: AppPrimaryButton(
                label: 'Перейти в каталог',
                icon: PhosphorIconsRegular.plus,
                size: AppButtonSize.sm,
                onPressed: () => AppToast.showInfo(context, 'Клик по действию EmptyState'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
