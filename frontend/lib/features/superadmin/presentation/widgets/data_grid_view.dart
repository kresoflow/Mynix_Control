import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DataGridView extends StatelessWidget {
  final List<Map<String, dynamic>> columns;
  final List<Map<String, dynamic>> rows;
  final List<String> primaryKeys;
  final Function(Map<String, dynamic> row) onEdit;
  final Function(Map<String, dynamic> row) onDelete;

  const DataGridView({
    super.key,
    required this.columns,
    required this.rows,
    required this.primaryKeys,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return const Center(child: Text("No columns defined"));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.brandPrimary.withOpacity(0.1)),
          columns: [
            const DataColumn(label: Text('Действия', style: TextStyle(fontWeight: FontWeight.bold))),
            ...columns.map((c) {
              final isPk = primaryKeys.contains(c['name']);
              return DataColumn(
                label: Row(
                  children: [
                    if (isPk) Icon(PhosphorIcons.key(), size: 14, color: AppColors.brandPrimary),
                    if (isPk) const SizedBox(width: 4),
                    Text(c['name'], style: AppTextStyles.bodyMedium),
                  ],
                ),
              );
            }),
          ],
          rows: rows.map((row) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIcons.pencilSimple(), size: 18, color: AppColors.info),
                        onPressed: () => onEdit(row),
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.trash(), size: 18, color: AppColors.danger),
                        onPressed: () => onDelete(row),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                ...columns.map((c) {
                  final val = row[c['name']];
                  final strVal = val?.toString() ?? 'NULL';
                  return DataCell(
                    Text(
                      strVal.length > 50 ? '${strVal.substring(0, 50)}...' : strVal,
                      style: AppTextStyles.body.copyWith(
                        color: val == null ? AppColors.darkSubtext : null,
                        fontStyle: val == null ? FontStyle.italic : null,
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
