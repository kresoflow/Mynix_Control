import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
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
    final catState = context.read<CategoryBloc>().state;
    final Map<String, int> catMap = {};
    if (catState is CategoryLoaded) {
      for (var c in catState.categories) {
        catMap[c.name.toLowerCase().trim()] = c.id;
      }
    }

    setState(() {
      if (_tabIndex == 3) {
        List<Map<String, String>> preset = [];
        if (_categoryType == 'dish') {
          preset = presetType == 'fastfood'
              ? [
                  {'name': 'Бургеры', 'icon': 'burger'},
                  {'name': 'Закуски и Фри', 'icon': 'frenchFries'},
                  {'name': 'Напитки', 'icon': 'cup'},
                  {'name': 'Десерты', 'icon': 'cookie'},
                  {'name': 'Соусы', 'icon': 'drop'},
                ]
              : [
                  {'name': 'Горячие блюда', 'icon': 'cookingPot'},
                  {'name': 'Паста и пицца', 'icon': 'pizza'},
                  {'name': 'Салаты', 'icon': 'plant'},
                  {'name': 'Супы', 'icon': 'bowl'},
                  {'name': 'Закуски', 'icon': 'frenchFries'},
                  {'name': 'Десерты', 'icon': 'cookie'},
                  {'name': 'Бар и напитки', 'icon': 'beer'},
                ];
        } else if (_categoryType == 'retail') {
          preset = [
            {'name': 'Бутилированные напитки', 'icon': 'cup'},
            {'name': 'Снэки и чипсы', 'icon': 'package'},
            {'name': 'Шоколад и батончики', 'icon': 'cookie'},
            {'name': 'Жвачки и леденцы', 'icon': 'drop'},
          ];
        } else {
          preset = presetType == 'fastfood'
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
        }

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
                {'name': 'Говяжья котлета (п/ф 150г)', 'unit': 'pcs', 'cost': 85.0, 'alert': 20.0, 'category': 'Мясо и полуфабрикаты', 'sku': '10-01'},
                {'name': 'Булочка Бриошь с кунжутом', 'unit': 'pcs', 'cost': 25.0, 'alert': 30.0, 'category': 'Хлеб и выпечка', 'sku': '20-01'},
                {'name': 'Сыр Чеддер (слайсы)', 'unit': 'kg', 'cost': 650.0, 'alert': 2.0, 'category': 'Молочка и сыры', 'sku': '30-01'},
                {'name': 'Соус «Бургер Smoke»', 'unit': 'kg', 'cost': 220.0, 'alert': 3.0, 'category': 'Соусы и приправы', 'sku': '40-01'},
                {'name': 'Огурцы маринованные (слайсы)', 'unit': 'kg', 'cost': 180.0, 'alert': 1.5, 'category': 'Овощи и зелень', 'sku': '50-01'},
                {'name': 'Помидоры свежие', 'unit': 'kg', 'cost': 120.0, 'alert': 5.0, 'category': 'Овощи и зелень', 'sku': '50-02'},
                {'name': 'Картофель фри (заморозка 9мм)', 'unit': 'kg', 'cost': 140.0, 'alert': 15.0, 'category': 'Заморозка', 'sku': '60-01'},
                {'name': 'Масло фритюрное', 'unit': 'l', 'cost': 130.0, 'alert': 10.0, 'category': 'Масла и жиры', 'sku': '70-01'},
                {'name': 'Соль пищевая поваренная', 'unit': 'kg', 'cost': 30.0, 'alert': 1.0, 'category': 'Соусы и приправы', 'sku': '40-02'},
                {'name': 'Упаковка для бургера крафт', 'unit': 'pcs', 'cost': 4.5, 'alert': 100.0, 'category': 'Упаковка и расходники', 'sku': '80-01'},
              ]
            : [
                {'name': 'Стейк Рибай п/ф 300г', 'unit': 'pcs', 'cost': 550.0, 'alert': 10.0, 'category': 'Мясо и полуфабрикаты', 'sku': '10-01'},
                {'name': 'Лосось свежий филе', 'unit': 'kg', 'cost': 1200.0, 'alert': 5.0, 'category': 'Рыба и морепродукты', 'sku': '90-01'},
                {'name': 'Сливки 33%', 'unit': 'l', 'cost': 380.0, 'alert': 8.0, 'category': 'Молочка и сыры', 'sku': '30-01'},
                {'name': 'Сыр Пармезан', 'unit': 'kg', 'cost': 1400.0, 'alert': 3.0, 'category': 'Молочка и сыры', 'sku': '30-02'},
                {'name': 'Паста Феттуччине', 'unit': 'kg', 'cost': 220.0, 'alert': 10.0, 'category': 'Крупы и макароны', 'sku': '11-01'},
                {'name': 'Оливковое масло Extra Virgin', 'unit': 'l', 'cost': 750.0, 'alert': 5.0, 'category': 'Масла и жиры', 'sku': '70-01'},
                {'name': 'Томаты Черри', 'unit': 'kg', 'cost': 250.0, 'alert': 4.0, 'category': 'Овощи и зелень', 'sku': '50-01'},
                {'name': 'Зелень микс (руккола, шпинат)', 'unit': 'kg', 'cost': 450.0, 'alert': 3.0, 'category': 'Овощи и зелень', 'sku': '50-02'},
              ];

        _ingredientRows.clear();
        for (var item in preset) {
          final catName = item['category'] as String?;
          final row = IngredientRowData(
            categoryId: catName != null ? catMap[catName.toLowerCase().trim()] : null,
            categoryName: catName,
            sku: item['sku'] as String?,
          );
          row.nameController.text = item['name'] as String;
          row.selectedUnit = item['unit'] as String;
          row.costController.text = (item['cost'] as num).toString();
          row.alertController.text = (item['alert'] as num).toString();
          _ingredientRows.add(row);
        }
      } else if (_tabIndex == 1) {
        final List<Map<String, dynamic>> preset = [
          {'name': 'Coca-Cola Classic 0.5л (ПЭТ)', 'sell': 75.0, 'purchase': 42.0, 'stock': 24.0, 'alert': 12.0, 'barcode': '5449000000996', 'category': 'Бутилированные напитки'},
          {'name': 'Fanta Orange 0.5л (ПЭТ)', 'sell': 75.0, 'purchase': 42.0, 'stock': 24.0, 'alert': 12.0, 'barcode': '5449000011527', 'category': 'Бутилированные напитки'},
          {'name': 'Sprite 0.5л (ПЭТ)', 'sell': 75.0, 'purchase': 42.0, 'stock': 24.0, 'alert': 12.0, 'barcode': '5449000011558', 'category': 'Бутилированные напитки'},
          {'name': 'Вода Bonaqua 0.5л', 'sell': 50.0, 'purchase': 25.0, 'stock': 30.0, 'alert': 15.0, 'barcode': '5449000131805', 'category': 'Бутилированные напитки'},
          {'name': 'Чипсы Lays с солью 80г', 'sell': 120.0, 'purchase': 75.0, 'stock': 20.0, 'alert': 10.0, 'barcode': '4600648011234', 'category': 'Снэки и чипсы'},
        ];

        _retailRows.clear();
        for (var item in preset) {
          final catName = item['category'] as String?;
          final row = RetailRowData(
            categoryId: catName != null ? catMap[catName.toLowerCase().trim()] : null,
            categoryName: catName,
          );
          row.nameController.text = item['name'] as String;
          row.purchaseController.text = (item['purchase'] as num).toString();
          row.sellController.text = (item['sell'] as num).toString();
          row.stockController.text = (item['stock'] as num).toString();
          row.alertController.text = (item['alert'] as num).toString();
          row.barcodeController.text = (item['barcode'] as String?) ?? '';
          _retailRows.add(row);
        }
      } else if (_tabIndex == 0) {
        final List<Map<String, dynamic>> preset = presetType == 'fastfood'
            ? [
                {'name': 'Кранчи Чизбургер', 'price': 290.0, 'options': 'Стандарт, Двойной сыр', 'prices': '290, 325', 'category': 'Бургеры'},
                {'name': 'Бургер Классический', 'price': 260.0, 'options': '', 'prices': '', 'category': 'Бургеры'},
                {'name': 'Картофель Фри Стандарт', 'price': 130.0, 'options': 'Стандарт, Большой', 'prices': '130, 180', 'category': 'Закуски и Фри'},
                {'name': 'Наггетсы хрустящие', 'price': 180.0, 'options': '6 шт, 9 шт', 'prices': '180, 250', 'category': 'Закуски и Фри'},
                {'name': 'Coca-Cola Разливная 0.5л', 'price': 75.0, 'options': '', 'prices': '', 'category': 'Напитки'},
              ]
            : [
                {'name': 'Паста Карбонара', 'price': 450.0, 'options': '', 'prices': '', 'category': 'Горячие блюда'},
                {'name': 'Стейк Рибай', 'price': 1200.0, 'options': 'Medium, Well Done', 'prices': '1200, 1200', 'category': 'Горячие блюда'},
                {'name': 'Салат Цезарь с курицей', 'price': 390.0, 'options': '', 'prices': '', 'category': 'Салаты'},
                {'name': 'Суп Том Ям с морепродуктами', 'price': 490.0, 'options': '', 'prices': '', 'category': 'Супы'},
              ];

        _dishRows.clear();
        for (var item in preset) {
          final catName = item['category'] as String?;
          final row = DishRowData(
            categoryId: catName != null ? catMap[catName.toLowerCase().trim()] : null,
            categoryName: catName,
          );
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
