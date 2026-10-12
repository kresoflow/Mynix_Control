// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_stock_category_accordion.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. АККОРДЕОН КАТЕГОРИИ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Заголовок категории склада для быстрого списания (плоская виртуализация).
class WriteOffCategoryAccordion extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final List<WriteOffItemEntry> activeEntries;
  final String currency;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const WriteOffCategoryAccordion({
    super.key,
    required this.categoryName,
    required this.items,
    required this.activeEntries,
    required this.currency,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  WriteOffItemEntry? _findEntry(Ingredient item) {
    for (final e in activeEntries) {
      if (e.item.isSameAs(item)) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int writtenOffCount = 0;
    double writtenOffSum = 0.0;

    for (final item in items) {
      final entry = _findEntry(item);
      if (entry != null && entry.quantity > 0) {
        writtenOffCount++;
        writtenOffSum += entry.total;
      }
    }

    final iconString = context.select<CategoryBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is CategoryLoaded) {
        return state.categories
            .where((c) => c.name == categoryName)
            .firstOrNull
            ?.getInheritedIcon(state.categories);
      }
      return null;
    });

    return AppStockCategoryAccordion(
      title: categoryName,
      leading: (iconString != null && iconString.isNotEmpty)
          ? IconHelper.buildIcon(
              iconString,
              size: 18,
              color: isExpanded
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            )
          : null,
      isExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      itemCount: items.length,
      totalSum: writtenOffSum > 0 ? writtenOffSum : null,
      currency: currency,
      isHighlighted: writtenOffCount > 0,
      trailingBadge: writtenOffCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Списано: $writtenOffCount поз.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            )
          : null,
      child: null, // [ОПТИМИЗАЦИЯ] child=null для плоской виртуализации (0 мс время раскрытия)
    );
  }
}

// ==============================================================================
// 3. ШАПКА ТАБЛИЦЫ ВНУТРИ КАТЕГОРИИ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Шапка колонок таблицы позиций внутри категории списания.
class WriteOffCategoryTableHeader extends StatelessWidget {
  final String currency;

  const WriteOffCategoryTableHeader({
    super.key,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        border: Border(
          left: borderSide,
          right: borderSide,
          bottom: borderSide,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Товар', style: style)),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text('Остаток', textAlign: TextAlign.right, style: style),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child:
                Text('К списанию', textAlign: TextAlign.center, style: style),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 95,
            child: Text(
              'Себестоимость',
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text('Сумма', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
