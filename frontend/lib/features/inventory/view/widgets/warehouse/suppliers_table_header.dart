// ==============================================================================
// МОДУЛЬ: Склад / Шапка таблицы поставщиков
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/suppliers_table_header.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// [ИНВАРИАНТ] Шапка таблицы контрагентов, соответствующая общему стилю карточных таблиц склада.
class SuppliersTableHeader extends StatelessWidget {
  const SuppliersTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCardHover,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text('ID', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('НАЗВАНИЕ', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('КОНТАКТНЫЕ ДАННЫЕ', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('БАЛАНС / ДОЛГ', style: textStyle),
          ),
          SizedBox(
            width: 90,
            child: Text('СТАТУС', style: textStyle),
          ),
          const SizedBox(width: 130),
        ],
      ),
    );
  }
}
