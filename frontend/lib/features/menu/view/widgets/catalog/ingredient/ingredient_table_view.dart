// ==============================================================================
// МОДУЛЬ: Справочник / Представление таблицы сырья (Ingredient Table View)
// ДОМЕН: lib/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_deletion_dialogs.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'ingredient_item_row.dart';

/// [UI-KIT] Стандартизированная таблица номенклатуры сырья (AppDataTableHeader + AppDataTableRow)
class IngredientTableView extends StatefulWidget {
  final List<Ingredient> ingredients;
  final int? selectedCategoryId;
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final Function(int id, bool selected) onToggleSelect;

  const IngredientTableView({
    super.key,
    required this.ingredients,
    required this.selectedCategoryId,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.onToggleSelect,
  });

  @override
  State<IngredientTableView> createState() => _IngredientTableViewState();
}

class _IngredientTableViewState extends State<IngredientTableView> {
  String _sortColumn = 'code';
  bool _sortAscending = true;

  void _toggleSort(String col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending = (col == 'name' || col == 'code');
      }
    });
  }

  Set<int> _getCategoryAndSubcategories(int parentId, List<MenuCategory> allCategories) {
    final result = {parentId};
    final toCheck = [parentId];
    while (toCheck.isNotEmpty) {
      final current = toCheck.removeLast();
      final children = allCategories.where((c) => c.parentId == current).map((c) => c.id).toList();
      result.addAll(children);
      toCheck.addAll(children);
    }
    return result;
  }

  List<AppDataTableColumn> _buildColumns() {
    return [
      AppDataTableColumn(
        label: widget.isManageMode ? 'ВЫБОР' : 'КОД',
        width: 64,
        alignment: Alignment.centerLeft,
        isSortable: !widget.isManageMode,
        sortAscending: _sortColumn == 'code' ? _sortAscending : null,
        onSort: () => _toggleSort('code'),
      ),
      AppDataTableColumn(
        label: 'Наименование',
        flex: 4,
        alignment: Alignment.centerLeft,
        isSortable: true,
        sortAscending: _sortColumn == 'name' ? _sortAscending : null,
        onSort: () => _toggleSort('name'),
      ),
      AppDataTableColumn(
        label: 'Остаток',
        flex: 2,
        alignment: Alignment.centerLeft,
        isSortable: true,
        sortAscending: _sortColumn == 'stock' ? _sortAscending : null,
        onSort: () => _toggleSort('stock'),
      ),
      AppDataTableColumn(
        label: 'Мин. запас',
        flex: 2,
        alignment: Alignment.centerLeft,
        isSortable: true,
        sortAscending: _sortColumn == 'minStock' ? _sortAscending : null,
        onSort: () => _toggleSort('minStock'),
      ),
      AppDataTableColumn(
        label: 'Себестоимость',
        flex: 2,
        alignment: Alignment.centerLeft,
        isSortable: true,
        sortAscending: _sortColumn == 'cost' ? _sortAscending : null,
        onSort: () => _toggleSort('cost'),
      ),
      const AppDataTableColumn(
        label: '',
        width: 48,
        alignment: Alignment.centerRight,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catState = context.watch<CategoryBloc>().state;
    List<MenuCategory> allCategories = [];
    if (catState is CategoryLoaded) {
      allCategories = catState.categories;
    }

    final rawIngredients = widget.ingredients.where((i) => !i.isRetail).toList();
    final filteredIngredients = widget.selectedCategoryId == null
        ? rawIngredients
        : rawIngredients.where((i) {
            if (i.categoryId == null) return false;
            final validIds = _getCategoryAndSubcategories(widget.selectedCategoryId!, allCategories);
            return validIds.contains(i.categoryId);
          }).toList();

    final currency = context.watch<SettingsBloc>().state.currency;

    if (filteredIngredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppEmptyState(
          icon: PhosphorIconsRegular.cookingPot,
          title: 'В этой категории пока нет сырья',
          description: 'Используйте «Добавить» или «Массово» на верхней панели',
          size: AppEmptyStateSize.md,
        ),
      );
    }

    final sorted = List<Ingredient>.from(filteredIngredients);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'code':
          cmp = a.id.compareTo(b.id);
          break;
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'stock':
          cmp = a.currentStock.compareTo(b.currentStock);
          break;
        case 'minStock':
          cmp = a.minStockAlert.compareTo(b.minStockAlert);
          break;
        case 'cost':
          cmp = a.costPerUnit.compareTo(b.costPerUnit);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    final columns = _buildColumns();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AppDataTableHeader(
            columns: columns,
            horizontalPadding: 16,
            height: 40,
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final item = sorted[index];

                String? iconStr;
                if (catState is CategoryLoaded) {
                  final cat = catState.categories.where((c) => c.id == item.categoryId).firstOrNull;
                  iconStr = cat?.getInheritedIcon(catState.categories);
                }

                return IngredientItemRow(
                  item: item,
                  columns: columns,
                  categoryIcon: iconStr,
                  currency: currency,
                  isManageMode: widget.isManageMode,
                  isSelected: widget.selectedIngredients.contains(item.id),
                  onSelect: (val) => widget.onToggleSelect(item.id, val == true),
                  onEdit: () => showAddIngredientDialog(context, itemToEdit: item),
                  onDelete: () => CatalogDeletionDialogs.confirmDeleteIngredient(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
