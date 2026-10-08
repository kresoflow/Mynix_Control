// ==============================================================================
// ВИТРИНА ФОРМ И СКЛАДСКИХ СПЕЦИФИКАЦИЙ (SHOWCASE FORMS SECTION)
// ==============================================================================
//
// Демонстрация стандартизированных компонентов AppSwitch, AppCheckbox,
// AppDropdownField, AppDialogScaffold v2 и AppStockCategoryAccordion.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseFormsSection extends StatefulWidget {
  const ShowcaseFormsSection({super.key});

  @override
  State<ShowcaseFormsSection> createState() => _ShowcaseFormsSectionState();
}

class _ShowcaseFormsSectionState extends State<ShowcaseFormsSection> {
  // ─── Состояния для AppSwitch & AppCheckbox ───
  bool _switchVal1 = true;
  bool _switchVal2 = false;
  final bool _switchVal3 = false; // Заблокирован (Выкл)
  bool _checkVal1 = true;
  bool _checkVal2 = false;

  String _selectedUnit = 'кг';
  bool _isStockCatExpanded = true;

  // ─── Данные для AppSpecificationTable ───
  final List<AppSpecificationRowData> _specItems = [
    const AppSpecificationRowData(
      id: '1',
      title: 'Тропик Киви 1 л',
      subtitle: 'Сок натуральный',
      quantity: 12.0,
      unit: 'шт',
      price: 15.0,
      total: 180.0,
    ),
    const AppSpecificationRowData(
      id: '2',
      title: 'Тропик персик 1 л',
      subtitle: 'Дефицит: -1 шт',
      quantity: 24.0,
      unit: 'шт',
      price: 15.0,
      total: 360.0,
    ),
  ];

  void _handleQuantityChange(int index, double newQty) {
    setState(() {
      final old = _specItems[index];
      _specItems[index] = AppSpecificationRowData(
        id: old.id,
        title: old.title,
        subtitle: old.subtitle,
        quantity: newQty,
        unit: old.unit,
        price: old.price,
        total: newQty * old.price,
      );
    });
  }

  void _handleDeleteRow(int index) {
    setState(() => _specItems.removeAt(index));
  }

  void _openDemoDialog(BuildContext context, AppDialogSize size) {
    final title = switch (size) {
      AppDialogSize.sm => 'Новое блюдо (SM: 440 px)',
      AppDialogSize.md => 'Карточка CRM / Смена (MD: 720 px)',
      AppDialogSize.lg => 'Приходная накладная (LG: 1080 px)',
    };
    final subtitle = switch (size) {
      AppDialogSize.sm => 'Быстрая форма создания объекта',
      AppDialogSize.md => 'Детализация смены и гостя',
      AppDialogSize.lg => 'Поставщик: ООО "Кофейный Дом"',
    };

    showDialog(
      context: context,
      builder: (_) => AppDialogScaffold(
        title: title,
        subtitle: subtitle,
        icon: PhosphorIconsRegular.fileText,
        dialogSize: size,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: size == AppDialogSize.sm
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Компактный размер для форм ввода, категорий и подтверждений.', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    Text('Вход разменного фонда / наименование блюда без расползания на весь экран.', style: AppTextStyles.caption),
                  ],
                )
              : AppSpecificationTable(
                  items: _specItems,
                  onQuantityChanged: _handleQuantityChange,
                  onDeleteRow: _handleDeleteRow,
                ),
        ),
        bottomSummary: Text(
          'ИТОГО: 540.00 ₽',
          style: AppTextStyles.monoBold.copyWith(
            color: AppColors.brandPrimary,
            fontSize: 16,
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', size: AppButtonSize.md, onPressed: () => Navigator.pop(context)),
          AppPrimaryButton(label: 'Сохранить', icon: PhosphorIconsRegular.checkCircle, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '6. Формы, Документы и Складские Спецификации',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Стандартизация форм ввода, выпадающих списков, модалок и иерархических складских аккордеонов.',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        const SizedBox(height: 18),

        // ─── 6.1. Переключатели и Чекбоксы ───
        Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppSwitch(value: _switchVal1, size: AppSwitchSize.sm, onChanged: (v) => setState(() => _switchVal1 = v), label: 'SM (36x20) [Вкл]'),
            AppSwitch(value: _switchVal2, size: AppSwitchSize.md, onChanged: (v) => setState(() => _switchVal2 = v), label: 'MD (44x24) [Выкл]'),
            AppSwitch(value: _switchVal3, disabled: true, onChanged: null, label: 'Заблокирован'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppCheckbox(value: _checkVal1, size: AppCheckboxSize.sm, onChanged: (v) => setState(() => _checkVal1 = v), label: 'Чекбокс SM (18x18)'),
            AppCheckbox(value: _checkVal2, size: AppCheckboxSize.md, onChanged: (v) => setState(() => _checkVal2 = v), label: 'Чекбокс MD (22x22) с описанием', subtitle: 'Тактильный полнострочный тап'),
            const AppCheckbox(value: false, isIndeterminate: true, onChanged: null, label: 'Минус'),
            const AppCheckbox(value: true, disabled: true, onChanged: null, label: 'Заблокирован'),
          ],
        ),
        const SizedBox(height: 20),

        // ─── 6.2. Выпадающие списки и Модальные диалоги ───
        Wrap(
          spacing: 24,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            // Поле выбора единиц
            SizedBox(
              width: 100,
              child: AppDropdownField<String>(
                labelText: 'Ед. изм.',
                value: _selectedUnit,
                isCompact: true,
                items: const [
                  DropdownMenuItem(value: 'кг', child: Text('кг')),
                  DropdownMenuItem(value: 'г', child: Text('г')),
                  DropdownMenuItem(value: 'л', child: Text('л')),
                  DropdownMenuItem(value: 'мл', child: Text('мл')),
                  DropdownMenuItem(value: 'шт', child: Text('шт')),
                ],
                onChanged: (v) { if (v != null) setState(() => _selectedUnit = v); },
              ),
            ),

            // Кнопки открытия диалогов с четким выравниванием
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Стандарты модальных окон:',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton.secondary(
                      label: 'SM (440 px)',
                      icon: PhosphorIconsRegular.cards,
                      size: AppButtonSize.md,
                      onPressed: () => _openDemoDialog(context, AppDialogSize.sm),
                    ),
                    AppButton.secondary(
                      label: 'MD (720 px)',
                      icon: PhosphorIconsRegular.browser,
                      size: AppButtonSize.md,
                      onPressed: () => _openDemoDialog(context, AppDialogSize.md),
                    ),
                    AppPrimaryButton(
                      label: 'LG (1080 px)',
                      icon: PhosphorIconsRegular.arrowSquareOut,
                      size: AppButtonSize.md,
                      onPressed: () => _openDemoDialog(context, AppDialogSize.lg),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── 6.3. Складской аккордеон категории (Стандарт Остатков и Приходки) ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Иерархический аккордеон склада (Родитель + Подпапка + Спецификация):',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            AppGhostButton(
              label: _isStockCatExpanded ? 'Свернуть всё' : 'Развернуть всё',
              icon: _isStockCatExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
              size: AppButtonSize.xs,
              onPressed: () => setState(() => _isStockCatExpanded = !_isStockCatExpanded),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // L1: Родительская группа «Напитки» (как на Скрине 3 Остатков)
        AppStockCategoryAccordion(
          title: 'Напитки (Корневая группа L1)',
          icon: PhosphorIconsRegular.drop,
          itemCount: 30,
          lowStockCount: 29,
          totalSum: 540.0,
          currency: '₽',
          isExpanded: _isStockCatExpanded,
          onExpansionChanged: (v) => setState(() => _isStockCatExpanded = v),
          child: Column(
            children: [
              // L2: Вложенная подпапка «Соки» (isSubcategory: true)
              AppStockCategoryAccordion(
                title: 'Соки (Вложенная подпапка L2)',
                icon: PhosphorIconsRegular.folder,
                itemCount: 2,
                lowStockCount: 1,
                totalSum: 540.0,
                currency: '₽',
                isSubcategory: true,
                isExpanded: true,
                onExpansionChanged: (_) {},
                child: AppSpecificationTable(
                  items: _specItems,
                  onQuantityChanged: _handleQuantityChange,
                  onDeleteRow: _handleDeleteRow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
