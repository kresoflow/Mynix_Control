// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ==============================================================================
// 2. ВСПЛЫВАЮЩАЯ ШТОРКА КОРЗИНЫ ПЕРЕСЧЕТА
// ==============================================================================
/// [ИНВАРИАНТ] Шторка-корзина со сводным списком посчитанных позиций ревизии.
class BlindInventoryCartSheet extends StatelessWidget {
  final List<Ingredient> allItems;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<Ingredient> onRemove;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  const BlindInventoryCartSheet({
    super.key,
    required this.allItems,
    required this.controllers,
    required this.onRemove,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validItems = allItems.where((it) {
      final text = controllers[it.uniqueKey]?.text.trim();
      return text != null && text.isNotEmpty;
    }).toList();

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          _buildHeader(context, isDark, validItems.length),
          _buildTableHeader(isDark),
          Expanded(
            child: validItems.isEmpty
                ? _buildEmpty(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: validItems.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : AppColors.lightBorder.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final item = validItems[index];
                      return _buildCartRow(context, item, isDark);
                    },
                  ),
          ),
          _buildFooter(context, isDark, validItems.length),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    final style = AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureWhite.withValues(alpha: 0.03) : AppColors.pureBlack.withValues(alpha: 0.03),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Номенклатура', style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text('Цех / Зона', style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text('Факт. остаток', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.xs)),
            child: Icon(PhosphorIconsRegular.clipboardText, size: 20, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text('Посчитанные остатки ревизии', style: AppTextStyles.h2.copyWith(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.xs)),
                  child: Text('$count поз.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(PhosphorIconsRegular.x, size: 18), tooltip: 'Закрыть', onPressed: onClose),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Всего посчитано: $count поз.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkText : AppColors.lightText),
          ),
          AppSecondaryButton(
            label: 'Назад к ревизии',
            size: AppButtonSize.sm,
            icon: PhosphorIconsRegular.arrowLeft,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow(BuildContext context, Ingredient item, bool isDark) {
    final ctrl = controllers.putIfAbsent(item.uniqueKey, () => TextEditingController());
    final isRetail = item.isRetail;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final currentQty = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isRetail ? AppColors.brandPrimary.withValues(alpha: 0.12) : AppColors.brandTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Text(isRetail ? 'Витрина' : 'Сырьё', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isRetail ? AppColors.brandPrimary : AppColors.brandTertiary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(item.categoryName ?? 'Без категории', style: TextStyle(fontSize: 11, color: subColor), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          AppQuantityStepper(
            value: currentQty,
            allowDecimals: true,
            size: AppStepperSize.sm,
            unit: UnitFormatter.format(item.unit),
            min: 0,
            onChanged: (val) {
              final d = val.toDouble();
              ctrl.text = d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
              onChanged();
            },
            onRemove: () => onRemove(item),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger), tooltip: 'Сбросить остаток', onPressed: () => onRemove(item)),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.clipboardText, size: 40, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          const SizedBox(height: 8),
          Text(
            'Ни одной позиции пока не посчитано',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
