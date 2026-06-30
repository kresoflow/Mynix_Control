import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'bulk_add/dish_row.dart';
import 'bulk_add/ingredient_row.dart';
import 'bulk_add/retail_row.dart';
import 'bulk_add/bulk_add_category_selector.dart';
import 'bulk_add/bulk_add_list_widget.dart';
import 'bulk_add/bulk_add_footer.dart';
import 'bulk_add/bulk_add_save_helper.dart';

class BulkAddModal extends StatefulWidget {
  final int initialTabIndex;
  const BulkAddModal({super.key, this.initialTabIndex = 0});

  @override
  State<BulkAddModal> createState() => _BulkAddModalState();
}

class _BulkAddModalState extends State<BulkAddModal> {
  int _tabIndex = 0; // 0 = Блюда, 1 = Товары витрины, 2 = Сырье

  int? _selectedParentId;
  int? _selectedChildId;

  final List<DishRowData> _dishRows = [];
  final List<RetailRowData> _retailRows = [];
  final List<IngredientRowData> _ingredientRows = [];

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _addRow();
  }

  void _addRow() {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.add(DishRowData());
      } else if (_tabIndex == 1) {
        _retailRows.add(RetailRowData());
      } else {
        _ingredientRows.add(IngredientRowData());
      }
    });
    _focusRow(
      _tabIndex == 0
          ? _dishRows.last.firstFocusNode
          : (_tabIndex == 1
                ? _retailRows.last.firstFocusNode
                : _ingredientRows.last.firstFocusNode),
    );
  }

  void _focusRow(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _duplicateRow(int index) {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.insert(index + 1, _dishRows[index].clone());
      } else if (_tabIndex == 1) {
        _retailRows.insert(index + 1, _retailRows[index].clone());
      } else {
        _ingredientRows.insert(index + 1, _ingredientRows[index].clone());
      }
    });
    _focusRow(
      _tabIndex == 0
          ? _dishRows[index + 1].firstFocusNode
          : (_tabIndex == 1
                ? _retailRows[index + 1].firstFocusNode
                : _ingredientRows[index + 1].firstFocusNode),
    );
  }

  void _removeRow(int index) {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.removeAt(index);
      } else if (_tabIndex == 1) {
        _retailRows.removeAt(index);
      } else {
        _ingredientRows.removeAt(index);
      }
    });
  }

  void _saveAll() {
    performBulkSave(
      context: context,
      tabIndex: _tabIndex,
      targetCategoryId: _selectedChildId ?? _selectedParentId,
      dishRows: _dishRows,
      ingredientRows: _ingredientRows,
      retailRows: _retailRows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabLabels = ['Блюда', 'Товары витрины', 'Сырьё'];
    final tabIcons = [
      PhosphorIconsRegular.cookingPot,
      PhosphorIconsRegular.storefront,
      PhosphorIconsRegular.leaf,
    ];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveAll,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _saveAll,
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Шапка ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(PhosphorIconsRegular.listBullets, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Массовое добавление',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(PhosphorIconsRegular.x,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Закрыть',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Pill-tabs + кнопка добавить ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      // Pill tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBg : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(tabLabels.length, (i) {
                            final selected = _tabIndex == i;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _tabIndex = i;
                                if ((i == 0 && _dishRows.isEmpty) ||
                                    (i == 1 && _retailRows.isEmpty) ||
                                    (i == 2 && _ingredientRows.isEmpty)) {
                                  _addRow();
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.brandPrimary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: selected
                                      ? [BoxShadow(
                                          color: AppColors.brandPrimary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tabIcons[i],
                                      size: 16,
                                      color: selected
                                          ? Colors.white
                                          : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tabLabels[i],
                                      style: TextStyle(
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                        fontSize: 13,
                                        color: selected
                                            ? Colors.white
                                            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                        label: const Text('Строка'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Выбор категорий ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: BulkAddCategorySelector(
                      tabIndex: _tabIndex,
                      selectedParentId: _selectedParentId,
                      selectedChildId: _selectedChildId,
                      onParentChanged: (val) => setState(() {
                        _selectedParentId = val;
                        _selectedChildId = null;
                      }),
                      onChildChanged: (val) => setState(() => _selectedChildId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Список строк ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: BulkAddListWidget(
                      tabIndex: _tabIndex,
                      dishRows: _dishRows,
                      retailRows: _retailRows,
                      ingredientRows: _ingredientRows,
                      onAddRow: _addRow,
                      onDuplicateRow: _duplicateRow,
                      onRemoveRow: _removeRow,
                    ),
                  ),
                ),

                // ── Footer ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                  child: BulkAddFooter(onSaveAll: _saveAll),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    for (var r in _dishRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in _retailRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in _ingredientRows) {
      r.firstFocusNode.dispose();
    }
    super.dispose();
  }
}
