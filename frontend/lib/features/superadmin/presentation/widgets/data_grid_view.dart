import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DataGridView extends StatefulWidget {
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
  State<DataGridView> createState() => _DataGridViewState();
}

class _DataGridViewState extends State<DataGridView> {
  final ScrollController _hScrollController = ScrollController();
  final ScrollController _vScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _hScrollController.dispose();
    _vScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatCell(dynamic val) {
    if (val == null) return 'NULL';
    final str = val.toString();
    if (str.length > 19 && str.contains('T') && str.contains('-')) {
      final parts = str.split('.');
      return parts.first.replaceAll('T', ' ');
    }
    return str.length > 60 ? '${str.substring(0, 60)}...' : str;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    if (widget.columns.isEmpty) {
      return Center(
        child: Text('В таблице нет колонок', style: AppTextStyles.bodyMedium.copyWith(color: subtextColor)),
      );
    }

    final displayRows = _searchQuery.isEmpty
        ? widget.rows
        : widget.rows.where((r) => r.values.any((v) => v != null && v.toString().toLowerCase().contains(_searchQuery))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid Toolbar: Search & Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          child: Row(
            children: [
              SizedBox(
                width: 240,
                height: 32,
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Поиск по данным...',
                    hintStyle: AppTextStyles.caption.copyWith(fontSize: 12, color: subtextColor),
                    prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 14),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 13),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Spacer(),
              Icon(PhosphorIconsRegular.arrowsLeftRight, size: 14, color: subtextColor),
              const SizedBox(width: 6),
              Text('Горизонтальный скролл активен', style: AppTextStyles.caption.copyWith(fontSize: 11, color: subtextColor)),
            ],
          ),
        ),
        const Divider(height: 1),

        // Grid Content with visible scrollbars
        Expanded(
          child: displayRows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.magnifyingGlass, size: 40, color: subtextColor),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isNotEmpty ? 'Нет записей, соответствующих запросу' : 'В этой таблице пока нет записей',
                        style: AppTextStyles.bodyMedium.copyWith(color: subtextColor),
                      ),
                    ],
                  ),
                )
              : Scrollbar(
                  controller: _hScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: Scrollbar(
                    controller: _vScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _vScrollController,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        controller: _hScrollController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.brandPrimary.withValues(alpha: 0.12)),
                          dataTextStyle: AppTextStyles.body.copyWith(color: textColor),
                          headingTextStyle: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
                          columns: [
                            DataColumn(
                              label: Text('Действия', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                            ),
                            ...widget.columns.map((c) {
                              final colName = c['name'] as String;
                              final isPk = widget.primaryKeys.contains(colName);
                              return DataColumn(
                                label: Row(
                                  children: [
                                    if (isPk) Icon(PhosphorIconsRegular.key, size: 14, color: AppColors.brandPrimary),
                                    if (isPk) const SizedBox(width: 4),
                                    Text(colName, style: AppTextStyles.bodyMedium.copyWith(color: isPk ? AppColors.brandPrimary : textColor)),
                                  ],
                                ),
                              );
                            }),
                          ],
                          rows: displayRows.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.info),
                                        onPressed: () => widget.onEdit(row),
                                        splashRadius: 20,
                                        tooltip: 'Редактировать',
                                      ),
                                      IconButton(
                                        icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                                        onPressed: () => widget.onDelete(row),
                                        splashRadius: 20,
                                        tooltip: 'Удалить',
                                      ),
                                    ],
                                  ),
                                ),
                                ...widget.columns.map((c) {
                                  final val = row[c['name']];
                                  final formatted = _formatCell(val);
                                  return DataCell(
                                    Text(
                                      formatted,
                                      style: AppTextStyles.body.copyWith(
                                        color: val == null ? subtextColor : textColor,
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
                    ),
                  ),
                ),
        ),

        // Bottom Status Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _searchQuery.isNotEmpty
                    ? 'Найдено: ${displayRows.length} из ${widget.rows.length}'
                    : 'Всего строк: ${widget.rows.length}',
                style: AppTextStyles.caption.copyWith(color: subtextColor, fontWeight: FontWeight.w600),
              ),
              Text(
                'Скроллируйте ползунок вправо для просмотра всех колонок',
                style: AppTextStyles.caption.copyWith(color: subtextColor, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
