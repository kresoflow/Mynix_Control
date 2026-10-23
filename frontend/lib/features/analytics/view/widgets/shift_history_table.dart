// ==============================================================================
// МОДУЛЬ: Аналитика / Таблица кассовых смен (Shift History Table)
// ДОМЕН: lib/features/analytics/view/widgets/shift_history_table.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'analytics_shift_row.dart';

/// [UI-KIT] Стандартизированная таблица смен на базе AppDataTableHeader и AppDataTableRow
class ShiftHistoryTable extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onToggleSort;

  const ShiftHistoryTable({
    super.key,
    required this.shifts,
    required this.sortColumn,
    required this.sortAscending,
    required this.onToggleSort,
  });

  List<AppDataTableColumn> _buildColumns() {
    return [
      AppDataTableColumn(
        label: '#',
        width: 52,
        alignment: Alignment.centerLeft,
        isSortable: true,
        sortAscending: sortColumn == 'id' ? sortAscending : null,
        onSort: () => onToggleSort('id'),
      ),
      const AppDataTableColumn(
        label: 'Смена / Кассир',
        flex: 4,
        alignment: Alignment.centerLeft,
      ),
      const AppDataTableColumn(
        label: 'Размен / Продажи',
        flex: 3,
        alignment: Alignment.centerLeft,
      ),
      AppDataTableColumn(
        label: 'Выручка',
        flex: 2,
        alignment: Alignment.centerLeft,
        isSortable: true,
        sortAscending: sortColumn == 'revenue' ? sortAscending : null,
        onSort: () => onToggleSort('revenue'),
      ),
      const AppDataTableColumn(
        label: 'Результат кассы',
        width: 170,
        alignment: Alignment.centerLeft,
      ),
      const AppDataTableColumn(
        label: '',
        width: 24,
        alignment: Alignment.centerRight,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final columns = _buildColumns();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDataTableHeader(
            columns: columns,
            horizontalPadding: 16,
            height: 40,
          ),
          if (shifts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: AppEmptyState(
                icon: PhosphorIconsRegular.fileDashed,
                title: 'Смены не найдены',
                description: 'Попробуйте изменить параметры поиска или фильтрации',
                size: AppEmptyStateSize.sm,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shifts.length,
              itemBuilder: (context, index) => AnalyticsShiftRow(
                shift: shifts[index],
                columns: columns,
              ),
            ),
        ],
      ),
    );
  }
}
