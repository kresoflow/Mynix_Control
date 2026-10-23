// ==============================================================================
// МОДУЛЬ: POS / Выбор столика (TablePickerModal)
// ДОМЕН: lib/features/pos/view/widgets/table_picker_modal.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Модальное окно выбора столика в зале:
// 1. Отображает сетку пресетов столиков с цветовой индикацией занятости.
// 2. Позволяет ввести произвольное имя/номер столика вручную.
// 3. Использует официальный эталон AppDialog и компоненты AppButton.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';
import 'tables/pos_active_tables_dialog.dart';

// ── 1. Модальное окно выбора столика ──────────────────────────────────────────

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
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeCount = context.watch<PosTabCubit>().state.activeTablesCount;

    return AppDialog(
      title: 'Выбор столика',
      subtitle: activeCount > 0
          ? 'Укажите стол для подачи ($activeCount в зале)'
          : 'Укажите стол для подачи заказа',
      icon: PhosphorIconsBold.chair,
      width: 460,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Сетка пресетов столиков ────────────────────────────────────────
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
                borderRadius: AppRadii.radiusMd,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPrimary.withValues(alpha: 0.18)
                        : isOccupied
                            ? AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.1)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: AppRadii.radiusMd,
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
                        AppSpacing.hXxs,
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
          AppSpacing.vMd,

          // ── Ручной ввод столика ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  decoration: InputDecoration(
                    hintText: 'Другой стол (напр. Бар 2)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: AppRadii.radiusMd),
                  ),
                ),
              ),
              AppSpacing.hSm,
              AppPrimaryButton(
                label: 'ОК',
                size: AppButtonSize.md,
                onPressed: () {
                  final text = _customController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onSelect(text);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          AppSpacing.vSm,

          // ── Ссылка на табло столиков ──────────────────────────────────────
          Center(
            child: AppGhostButton(
              icon: PhosphorIconsBold.chair,
              label: activeCount > 0
                  ? 'Открыть табло занятых столиков ($activeCount)'
                  : 'Открыть табло занятых столиков',
              size: AppButtonSize.sm,
              onPressed: () {
                Navigator.pop(context);
                PosActiveTablesDialog.show(context);
              },
            ),
          ),
        ],
      ),
      actions: [
        if (widget.currentTable != null)
          AppGhostButton(
            label: 'Сбросить выбор',
            customColor: AppColors.danger,
            size: AppButtonSize.md,
            onPressed: () {
              widget.onSelect(null);
              Navigator.pop(context);
            },
          ),
        AppGhostButton(
          label: 'Закрыть',
          size: AppButtonSize.md,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
