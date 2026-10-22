import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';
import 'tables/pos_active_tables_dialog.dart';

class TablePickerModal extends StatefulWidget {
  final String? currentTable;
  final ValueChanged<String?> onSelect;

  const TablePickerModal({
    super.key,
    required this.currentTable,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    String? currentTable,
    required ValueChanged<String?> onSelect,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => TablePickerModal(
        currentTable: currentTable,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<TablePickerModal> createState() => _TablePickerModalState();
}

class _TablePickerModalState extends State<TablePickerModal> {
  final _customController = TextEditingController();
  final List<String> _presetTables = [
    'Стол 1', 'Стол 2', 'Стол 3', 'Стол 4',
    'Стол 5', 'Стол 6', 'Стол 7', 'Стол 8',
    'VIP',  'Стойка',
  ];
  Set<String> _occupiedTables = {};

  @override
  void initState() {
    super.initState();
    if (widget.currentTable != null && !_presetTables.contains(widget.currentTable)) {
      _customController.text = widget.currentTable!;
    }
    _loadOccupiedTables();
  }

  Future<void> _loadOccupiedTables() async {
    try {
      final tables = await OrderRepository(apiClient.dio).fetchActiveTables();
      if (mounted) {
        setState(() {
          _occupiedTables = tables.map((t) => t['table_number']?.toString() ?? '').toSet();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeCount = context.watch<PosTabCubit>().state.activeTablesCount;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsBold.chair, color: AppColors.brandPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Выбор столика', style: AppTextStyles.h3),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$activeCount в зале',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Укажите стол для подачи заказа',
                        style: TextStyle(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.currentTable != null)
                  TextButton(
                    onPressed: () {
                      widget.onSelect(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Сбросить', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(PhosphorIconsRegular.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Presets Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.3,
              ),
              itemCount: _presetTables.length,
              itemBuilder: (context, index) {
                final table = _presetTables[index];
                final isSelected = widget.currentTable == table;
                final isOccupied = _occupiedTables.contains(table);
                return InkWell(
                  onTap: () {
                    widget.onSelect(table);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandPrimary.withValues(alpha: 0.18)
                          : isOccupied
                              ? AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.1)
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : isOccupied
                                ? AppColors.warning.withValues(alpha: 0.6)
                                : border,
                        width: (isSelected || isOccupied) ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          table,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.brandPrimary
                                : isOccupied
                                    ? AppColors.warning
                                    : (isDark ? AppColors.darkText : AppColors.lightText),
                            fontWeight: (isSelected || isOccupied) ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (isOccupied && !isSelected) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Custom table input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: InputDecoration(
                      hintText: 'Другой стол (напр. Бар 2)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _customController.text.trim();
                    if (text.isNotEmpty) {
                      widget.onSelect(text);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ОК', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  PosActiveTablesDialog.show(context);
                },
                icon: const Icon(PhosphorIconsBold.chair, size: 14),
                label: Text(
                  activeCount > 0
                      ? 'Открыть табло занятых столиков ($activeCount)'
                      : 'Открыть табло занятых столиков',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

