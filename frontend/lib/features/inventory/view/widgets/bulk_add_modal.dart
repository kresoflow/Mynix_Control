import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'bulk_add/dish_row.dart';
import 'bulk_add/ingredient_row.dart';
import 'bulk_add/retail_row.dart';
import 'bulk_add/category_row.dart';
import 'bulk_add/bulk_add_header.dart';
import 'bulk_add/bulk_add_tabs_bar.dart';
import 'bulk_add/bulk_add_category_selector.dart';
import 'bulk_add/bulk_add_list_widget.dart';
import 'bulk_add/bulk_add_footer.dart';
import 'bulk_add/bulk_add_save_helper.dart';

class BulkAddModal extends StatefulWidget {
  final int initialTabIndex;
  final int? initialParentId;
  final int? initialChildId;

  const BulkAddModal({
    super.key,
    this.initialTabIndex = 0,
    this.initialParentId,
    this.initialChildId,
  });

  @override
  State<BulkAddModal> createState() => _BulkAddModalState();
}

class _BulkAddModalState extends State<BulkAddModal> {
  int _tabIndex = 0; // 0 = Блюда, 1 = Товары витрины, 2 = Сырье, 3 = Папки
  int? _selectedParentId;
  int? _selectedChildId;

  final List<DishRowData> _dishRows = [];
  final List<RetailRowData> _retailRows = [];
  final List<IngredientRowData> _ingredientRows = [];
  final List<CategoryRowData> _categoryRows = [];
  String _categoryType = 'dish';

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _selectedParentId = widget.initialParentId;
    _selectedChildId = widget.initialChildId;
    _addRow();
  }

  void _addRow() {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.add(DishRowData());
      } else if (_tabIndex == 1) {
        final newRow = RetailRowData();
        if (_retailRows.isNotEmpty) {
          newRow.selectedUnit = _retailRows.last.selectedUnit;
        }
        _retailRows.add(newRow);
      } else if (_tabIndex == 2) {
        final newRow = IngredientRowData();
        if (_ingredientRows.isNotEmpty) {
          newRow.selectedUnit = _ingredientRows.last.selectedUnit;
        }
        _ingredientRows.add(newRow);
      } else {
        _categoryRows.add(CategoryRowData());
      }
    });
    _focusRow(
      _tabIndex == 0
          ? _dishRows.last.firstFocusNode
          : (_tabIndex == 1
              ? _retailRows.last.firstFocusNode
              : (_tabIndex == 2
                  ? _ingredientRows.last.firstFocusNode
                  : _categoryRows.last.firstFocusNode)),
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
      } else if (_tabIndex == 2) {
        _ingredientRows.insert(index + 1, _ingredientRows[index].clone());
      } else {
        _categoryRows.insert(index + 1, _categoryRows[index].clone());
      }
    });
    _focusRow(
      _tabIndex == 0
          ? _dishRows[index + 1].firstFocusNode
          : (_tabIndex == 1
              ? _retailRows[index + 1].firstFocusNode
              : (_tabIndex == 2
                  ? _ingredientRows[index + 1].firstFocusNode
                  : _categoryRows[index + 1].firstFocusNode)),
    );
  }

  void _removeRow(int index) {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.removeAt(index);
      } else if (_tabIndex == 1) {
        _retailRows.removeAt(index);
      } else if (_tabIndex == 2) {
        _ingredientRows.removeAt(index);
      } else {
        _categoryRows.removeAt(index);
      }
    });
  }

  void _loadPreset(String presetType) {
    setState(() {
      if (_tabIndex == 3) {
        final List<Map<String, String>> preset = presetType == 'fastfood'
            ? [
                {'name': 'Мясо и полуфабрикаты', 'icon': 'meat'},
                {'name': 'Хлеб и выпечка', 'icon': 'bread'},
                {'name': 'Молочка и сыры', 'icon': 'cheese'},
                {'name': 'Соусы и приправы', 'icon': 'drop'},
                {'name': 'Овощи и зелень', 'icon': 'plant'},
                {'name': 'Заморозка', 'icon': 'snowflake'},
                {'name': 'Масла и жиры', 'icon': 'dropHalf'},
                {'name': 'Упаковка и расходники', 'icon': 'package'},
              ]
            : [
                {'name': 'Мясо и полуфабрикаты', 'icon': 'meat'},
                {'name': 'Хлеб и выпечка', 'icon': 'bread'},
                {'name': 'Молочка и сыры', 'icon': 'cheese'},
                {'name': 'Соусы и приправы', 'icon': 'drop'},
                {'name': 'Овощи и зелень', 'icon': 'plant'},
                {'name': 'Заморозка', 'icon': 'snowflake'},
                {'name': 'Масла и жиры', 'icon': 'dropHalf'},
                {'name': 'Упаковка и расходники', 'icon': 'package'},
                {'name': 'Рыба и морепродукты', 'icon': 'fishSimple'},
                {'name': 'Крупы и макароны', 'icon': 'grains'},
                {'name': 'Напитки', 'icon': 'beer'},
                {'name': 'Десертные ингредиенты', 'icon': 'cookie'},
              ];

        _categoryRows.clear();
        for (int i = 0; i < preset.length; i++) {
          final row = CategoryRowData();
          row.nameController.text = preset[i]['name']!;
          row.selectedIcon = preset[i]['icon'];
          row.sortOrderController.text = (i + 1).toString();
          _categoryRows.add(row);
        }
      } else if (_tabIndex == 2) {
        final List<Map<String, dynamic>> preset = presetType == 'fastfood'
            ? [
                {'name': 'Котлета говяжья п/ф 150г', 'unit': 'pcs', 'cost': 85.0, 'alert': 20.0},
                {'name': 'Булочка бриошь с кунжутом', 'unit': 'pcs', 'cost': 18.0, 'alert': 50.0},
                {'name': 'Сыр Чеддер слайсы', 'unit': 'kg', 'cost': 650.0, 'alert': 5.0},
                {'name': 'Соус Бургер фирменный', 'unit': 'kg', 'cost': 280.0, 'alert': 3.0},
                {'name': 'Салат Айсберг свежий', 'unit': 'kg', 'cost': 140.0, 'alert': 5.0},
                {'name': 'Помидоры свежие', 'unit': 'kg', 'cost': 120.0, 'alert': 10.0},
                {'name': 'Огурцы маринованные', 'unit': 'kg', 'cost': 190.0, 'alert': 4.0},
                {'name': 'Картофель фри 9мм зам.', 'unit': 'kg', 'cost': 135.0, 'alert': 30.0},
                {'name': 'Масло фритюрное', 'unit': 'l', 'cost': 160.0, 'alert': 40.0},
                {'name': 'Упаковка для бургера', 'unit': 'pcs', 'cost': 4.5, 'alert': 100.0},
              ]
            : [
                {'name': 'Стейк Рибай п/ф 300г', 'unit': 'pcs', 'cost': 550.0, 'alert': 10.0},
                {'name': 'Лосось свежий филе', 'unit': 'kg', 'cost': 1200.0, 'alert': 5.0},
                {'name': 'Сливки 33%', 'unit': 'l', 'cost': 380.0, 'alert': 8.0},
                {'name': 'Сыр Пармезан', 'unit': 'kg', 'cost': 1400.0, 'alert': 3.0},
                {'name': 'Паста Феттуччине', 'unit': 'kg', 'cost': 220.0, 'alert': 10.0},
                {'name': 'Оливковое масло Extra Virgin', 'unit': 'l', 'cost': 750.0, 'alert': 5.0},
                {'name': 'Томаты Черри', 'unit': 'kg', 'cost': 250.0, 'alert': 4.0},
                {'name': 'Зелень микс (руккола, шпинат)', 'unit': 'kg', 'cost': 450.0, 'alert': 3.0},
              ];

        _ingredientRows.clear();
        for (var item in preset) {
          final row = IngredientRowData();
          row.nameController.text = item['name'] as String;
          row.selectedUnit = item['unit'] as String;
          row.costController.text = (item['cost'] as num).toString();
          row.alertController.text = (item['alert'] as num).toString();
          _ingredientRows.add(row);
        }
      } else if (_tabIndex == 0) {
        final List<Map<String, dynamic>> preset = presetType == 'fastfood'
            ? [
                {'name': 'Бургер Классический', 'price': 280.0, 'options': 'Одинарный, Двойной', 'prices': '280, 380'},
                {'name': 'Чизбургер с чеддером', 'price': 310.0, 'options': '', 'prices': ''},
                {'name': 'Картофель фри хрустящий', 'price': 140.0, 'options': 'Стандарт, Большой', 'prices': '140, 190'},
                {'name': 'Наггетсы куриные', 'price': 180.0, 'options': '6 шт, 9 шт', 'prices': '180, 250'},
                {'name': 'Кола 0.5л', 'price': 90.0, 'options': '', 'prices': ''},
              ]
            : [
                {'name': 'Паста Карбонара', 'price': 450.0, 'options': '', 'prices': ''},
                {'name': 'Стейк Рибай', 'price': 1200.0, 'options': 'Medium, Well Done', 'prices': '1200, 1200'},
                {'name': 'Салат Цезарь с курицей', 'price': 390.0, 'options': '', 'prices': ''},
                {'name': 'Суп Том Ям с морепродуктами', 'price': 490.0, 'options': '', 'prices': ''},
              ];

        _dishRows.clear();
        for (var item in preset) {
          final row = DishRowData();
          row.nameController.text = item['name'] as String;
          row.priceController.text = (item['prices'] as String).isNotEmpty ? (item['prices'] as String) : (item['price'] as num).toString();
          row.optionsController.text = item['options'] as String;
          _dishRows.add(row);
        }
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
      categoryRows: _categoryRows,
      globalCategoryType: _categoryType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                const BulkAddHeader(),
                const SizedBox(height: 16),
                BulkAddTabsBar(
                  tabIndex: _tabIndex,
                  categoryType: _categoryType,
                  onTabSelected: (i) => setState(() {
                    _tabIndex = i;
                    if ((i == 0 && _dishRows.isEmpty) ||
                        (i == 1 && _retailRows.isEmpty) ||
                        (i == 2 && _ingredientRows.isEmpty) ||
                        (i == 3 && _categoryRows.isEmpty)) {
                      _addRow();
                    }
                  }),
                  onCategoryTypeChanged: (val) => setState(() => _categoryType = val),
                  onAddRow: _addRow,
                  onLoadPreset: _loadPreset,
                ),
                const SizedBox(height: 12),
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
                      globalCategoryType: _categoryType,
                      onCategoryTypeChanged: (val) => setState(() => _categoryType = val),
                      selectedParentId: _selectedParentId,
                      selectedChildId: _selectedChildId,
                      onParentChanged: (val) => setState(() => _selectedParentId = val),
                      onChildChanged: (val) => setState(() => _selectedChildId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: BulkAddListWidget(
                      tabIndex: _tabIndex,
                      dishRows: _dishRows,
                      retailRows: _retailRows,
                      ingredientRows: _ingredientRows,
                      categoryRows: _categoryRows,
                      onAddRow: _addRow,
                      onDuplicateRow: _duplicateRow,
                      onRemoveRow: _removeRow,
                    ),
                  ),
                ),
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
    for (var r in _categoryRows) {
      r.firstFocusNode.dispose();
    }
    super.dispose();
  }
}
