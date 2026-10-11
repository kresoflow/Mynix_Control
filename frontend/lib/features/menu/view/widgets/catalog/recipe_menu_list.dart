// ==============================================================================
// МОДУЛЬ: Каталог / Дерево меню и список блюд для техкарт
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe_menu_list.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/recipe/recipe_dish_tile.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum RecipeStatusFilter { all, configured, unconfigured }

class RecipeMenuList extends StatefulWidget {
  final int? selectedMenuItemId;
  final ValueChanged<int?> onMenuItemSelected;

  const RecipeMenuList({
    super.key,
    required this.selectedMenuItemId,
    required this.onMenuItemSelected,
  });

  @override
  State<RecipeMenuList> createState() => _RecipeMenuListState();
}

class _RecipeMenuListState extends State<RecipeMenuList> {
  final Map<String, bool> _expandedCategories = {};
  bool _allExpanded = false;
  String _searchQuery = '';
  RecipeStatusFilter _statusFilter = RecipeStatusFilter.all;

  void _toggleCategory(String category) {
    setState(() => _expandedCategories[category] = !(_expandedCategories[category] ?? false));
  }

  void _toggleExpandAll(List<String> categories) {
    setState(() {
      _allExpanded = !_allExpanded;
      for (final cat in categories) {
        _expandedCategories[cat] = _allExpanded;
      }
    });
  }

  bool _hasRecipe(dynamic item, Map<int, Map<String, dynamic>> summaryMap) {
    if (summaryMap[item.id]?['has_recipe'] == true) return true;
    final vars = item.variations;
    if (vars is List && vars.isNotEmpty) {
      for (final v in vars) {
        final vId = v is Map ? v['id'] : v.id;
        if (summaryMap[vId]?['has_recipe'] == true) return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _resolveSummary(dynamic item, Map<int, Map<String, dynamic>> summaryMap) {
    final s = summaryMap[item.id];
    if (s != null && s['has_recipe'] == true) return s;
    final vars = item.variations;
    if (vars is List && vars.isNotEmpty) {
      for (final v in vars) {
        final vId = v is Map ? v['id'] : v.id;
        final vs = summaryMap[vId];
        if (vs != null && vs['has_recipe'] == true) return vs;
      }
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryMap = context.select<RecipeBloc, Map<int, Map<String, dynamic>>>(
      (b) => b.state.recipesSummary,
    );

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        return BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            if (state is MenuLoading) return const Center(child: CircularProgressIndicator());
            if (state is! MenuLoaded) return const SizedBox.shrink();

            final activeCatMap = catState is CategoryLoaded
                ? {for (var c in catState.categories.where((c) => c.isVisible)) c.id.toString(): c}
                : <String, dynamic>{};

            final rawItems = state.items.where((i) {
              if (i.isRetail || !i.isAvailable) return false;
              final catId = i.categoryId.toString();
              return catId == '0' || catId == 'null' || catId == '' || catId == 'uncategorized' || activeCatMap.containsKey(catId);
            }).toList();

            if (rawItems.isEmpty) return const Center(child: Text('Нет доступных блюд для техкарт'));

            final int totalCount = rawItems.length;
            int configuredCount = 0;
            for (final it in rawItems) {
              if (_hasRecipe(it, summaryMap)) configuredCount++;
            }
            final int unconfiguredCount = totalCount - configuredCount;

            final filteredItems = rawItems.where((i) {
              final has = _hasRecipe(i, summaryMap);
              if (_statusFilter == RecipeStatusFilter.configured && !has) return false;
              if (_statusFilter == RecipeStatusFilter.unconfigured && has) return false;
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase().trim();
              return i.cleanName.toLowerCase().contains(q) || (i.categoryName != null && i.categoryName!.toLowerCase().contains(q));
            }).toList();

            final Map<String, List<dynamic>> groupedItems = {};
            for (var item in filteredItems) {
              final catId = item.categoryId.toString();
              final String catName = activeCatMap.containsKey(catId)
                  ? activeCatMap[catId].name
                  : (item.categoryName?.isNotEmpty == true ? item.categoryName! : 'Без категории');
              groupedItems.putIfAbsent(catName, () => []).add(item);
            }

            final List<dynamic> flatList = [];
            groupedItems.forEach((catName, items) {
              final isExpanded = _searchQuery.isNotEmpty || (_expandedCategories[catName] ?? false);
              flatList.add({'type': 'header', 'categoryName': catName, 'itemsCount': items.length, 'isExpanded': isExpanded});
              if (isExpanded) {
                flatList.addAll(items.map((item) => {'type': 'item', 'item': item}));
              }
            });

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        hintText: 'Поиск блюда...',
                        size: AppSearchFieldSize.sm,
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: _allExpanded ? 'Свернуть все' : 'Развернуть все',
                      child: InkWell(
                        onTap: () => _toggleExpandAll(groupedItems.keys.toList()),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Container(
                          height: 34,
                          width: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Icon(
                            _allExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                            size: 15,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppFilterBar(
                  spacing: 4.0,
                  children: [
                    AppFilterChip(
                      size: AppFilterChipSize.sm,
                      label: 'Все',
                      count: totalCount,
                      isSelected: _statusFilter == RecipeStatusFilter.all,
                      onTap: () => setState(() => _statusFilter = RecipeStatusFilter.all),
                    ),
                    AppFilterChip(
                      size: AppFilterChipSize.sm,
                      label: 'С составом',
                      count: configuredCount,
                      isSelected: _statusFilter == RecipeStatusFilter.configured,
                      activeColor: AppColors.success,
                      onTap: () => setState(() => _statusFilter = RecipeStatusFilter.configured),
                    ),
                    AppFilterChip(
                      size: AppFilterChipSize.sm,
                      label: 'Без состава',
                      count: unconfiguredCount,
                      isSelected: _statusFilter == RecipeStatusFilter.unconfigured,
                      activeColor: AppColors.warning,
                      onTap: () => setState(() => _statusFilter = RecipeStatusFilter.unconfigured),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: AppNavTile(
                              title: 'СВОДКА И ОБЗОР',
                              icon: PhosphorIconsRegular.chartLineUp,
                              isSelected: widget.selectedMenuItemId == null,
                              size: AppNavTileSize.md,
                              onTap: () => widget.onMenuItemSelected(null),
                            ),
                          ),
                          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              itemCount: flatList.length,
                              itemBuilder: (context, index) {
                                final data = flatList[index];
                                if (data['type'] == 'header') {
                                  return AppNavTile(
                                    title: (data['categoryName'] as String).toUpperCase(),
                                    count: data['itemsCount'] as int,
                                    isExpandable: true,
                                    isExpanded: data['isExpanded'] as bool,
                                    size: AppNavTileSize.sm,
                                    onExpandToggle: () => _toggleCategory(data['categoryName'] as String),
                                    onTap: () => _toggleCategory(data['categoryName'] as String),
                                  );
                                }
                                final item = data['item'];
                                return RecipeDishTile(
                                  item: item,
                                  isSelected: widget.selectedMenuItemId == item.id,
                                  summary: _resolveSummary(item, summaryMap),
                                  catState: catState,
                                  onTap: () => widget.onMenuItemSelected(item.id),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
