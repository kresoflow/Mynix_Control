// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';

// ==============================================================================
// 2. ТАБЛИЦА ПОЗИЦИЙ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Таблица позиций с внесенным фактическим остатком.
class BlindInventoryItemsTable extends StatelessWidget {
  final List<Ingredient> activeItems;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<Ingredient> onRemove;
  final VoidCallback onChanged;

  const BlindInventoryItemsTable({
    super.key,
    required this.activeItems,
    required this.controllers,
    required this.onRemove,
    required this.onChanged,
  });

  static const double colNumWidth = 32.0;
  static const double colCategoryWidth = 110.0;
  static const double colQtyWidth = 90.0;
  static const double colUnitWidth = 55.0;
  static const double colActionWidth = 36.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeItems.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 180, maxHeight: 290),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          _buildTableHeader(isDark),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: activeItems.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, idx) {
                final item = activeItems[idx];
                return _buildRow(context, item, idx, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    final headerStyle = AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      child: Row(
        children: [
          SizedBox(width: colNumWidth, child: Text('№', style: headerStyle, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(child: Text('Наименование', style: headerStyle)),
          const SizedBox(width: 8),
          SizedBox(width: colCategoryWidth, child: Text('Цех / Зона', style: headerStyle)),
          const SizedBox(width: 8),
          SizedBox(width: colQtyWidth, child: Text('Факт. остаток', style: headerStyle, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: colUnitWidth, child: Text('Ед.', style: headerStyle, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          const SizedBox(width: colActionWidth),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, Ingredient item, int idx, bool isDark) {
    final ctrl = controllers.putIfAbsent(item.uniqueKey, () => TextEditingController());
    final isRetail = item.isRetail;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: colNumWidth,
            child: Text(
              '${idx + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRetail ? AppColors.brandPrimary.withValues(alpha: 0.12) : AppColors.brandTertiary.withValues(alpha: 0.12),
                    borderRadius: AppRadii.badgeRadius,
                  ),
                  child: Text(
                    isRetail ? 'Витрина' : 'Сырьё',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isRetail ? AppColors.brandPrimary : AppColors.brandTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colCategoryWidth,
            child: Text(
              item.categoryName ?? 'Без категории',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colQtyWidth,
            height: 34,
            child: TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: buildBulkInputDecoration(
                context,
                '0',
                isHintOnly: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colUnitWidth,
            child: Text(
              UnitFormatter.format(item.unit),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colActionWidth,
            child: IconButton(
              icon: const Icon(PhosphorIconsRegular.x, size: 15, color: AppColors.danger),
              tooltip: 'Сбросить остаток',
              onPressed: () => onRemove(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.clipboardText, size: 40, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          const SizedBox(height: 12),
          Text(
            'Позиции для ревизии не внесены',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Используйте строку поиска или перейдите в каталог по категориям',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
