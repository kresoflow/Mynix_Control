// ==============================================================================
// УНИФИЦИРОВАННАЯ ТАБЛИЦА СПЕЦИФИКАЦИИ ДОКУМЕНТОВ (APP SPECIFICATION TABLE)
// ==============================================================================
//
// [ИНВАРИАНТ] Стандартизированная интерактивная таблица для документов склада:
// Приходная накладная, Списание, Массовое добавление, Инвентаризация.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'app_empty_state.dart';
import 'app_quantity_stepper.dart';

/// Модель строки спецификации документа
class AppSpecificationRowData {
  final String id;
  final String title;
  final String? subtitle;
  final double quantity;
  final String unit;
  final double price;
  final double total;

  const AppSpecificationRowData({
    required this.id,
    required this.title,
    this.subtitle,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.total,
  });
}

/// [UI-KIT] Таблица редактирования спецификации документа
class AppSpecificationTable extends StatelessWidget {
  final List<AppSpecificationRowData> items;
  final void Function(int index, double newQuantity)? onQuantityChanged;
  final void Function(int index)? onDeleteRow;
  final String emptyTitle;
  final String emptyDescription;

  const AppSpecificationTable({
    super.key,
    required this.items,
    this.onQuantityChanged,
    this.onDeleteRow,
    this.emptyTitle = 'В документе нет позиций',
    this.emptyDescription = 'Добавьте товары или ингредиенты через поиск выше',
  });

  Widget _buildHeaderCell(String text, {double? width, bool isCenter = false, bool isRight = false, int flex = 1, bool isExpanded = false, required bool isDark}) {
    final style = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );
    final child = Text(text, style: style);
    final aligned = isCenter ? Center(child: child) : isRight ? Align(alignment: Alignment.centerRight, child: child) : child;
    return isExpanded ? Expanded(flex: flex, child: aligned) : SizedBox(width: width, child: aligned);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: borderColor),
        ),
        child: AppEmptyState(
          icon: PhosphorIconsRegular.shoppingBagOpen,
          title: emptyTitle,
          description: emptyDescription,
          size: AppEmptyStateSize.sm,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // ─── Шапка таблицы ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                _buildHeaderCell('№', width: 32, isDark: isDark),
                _buildHeaderCell('Позиция', isExpanded: true, flex: 3, isDark: isDark),
                _buildHeaderCell('Количество', width: 110, isCenter: true, isDark: isDark),
                _buildHeaderCell('Цена', width: 100, isRight: true, isDark: isDark),
                _buildHeaderCell('Сумма', width: 110, isRight: true, isDark: isDark),
                const SizedBox(width: 44),
              ],
            ),
          ),

          // ─── Строки спецификации ───
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final row = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text('${index + 1}', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
                          if (row.subtitle != null)
                            Text(row.subtitle!, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Center(
                        child: AppQuantityStepper(
                          value: row.quantity,
                          unit: row.unit,
                          size: AppStepperSize.sm,
                          onChanged: (val) => onQuantityChanged?.call(index, val.toDouble()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(CurrencyFormatter.format(context, row.price), style: AppTextStyles.mono.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText, fontSize: 13)),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(CurrencyFormatter.format(context, row.total), style: AppTextStyles.monoBold.copyWith(color: AppColors.brandPrimary, fontSize: 13)),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
                          onPressed: () => onDeleteRow?.call(index),
                          tooltip: 'Удалить строку',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
