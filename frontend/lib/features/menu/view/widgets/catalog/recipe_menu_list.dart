import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/recipe/recipe_dish_tile.dart';
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
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }

  void _toggleExpandAll(List<String> categories) {
    setState(() {
      _allExpanded = !_allExpanded;
      for (final cat in categories) {
        _expandedCategories[cat] = _allExpanded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipeState = context.watch<RecipeBloc>().state;
    final summaryMap = recipeState.recipesSummary;

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        return BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            if (state is MenuLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MenuLoaded) {
              final activeCatMap = catState is CategoryLoaded
                  ? {for (var c in catState.categories.where((c) => c.isVisible)) c.id.toString(): c}
                  : <String, dynamic>{};

              final rawItems = state.items.where((i) {
                if (i.isRetail) return false;
                if (!i.isAvailable) return false;
                final catId = i.categoryId.toString();
                final isRoot = catId == '0' || catId == 'null' || catId == '' || catId == 'uncategorized';
                return isRoot || activeCatMap.containsKey(catId);
              }).toList();

              if (rawItems.isEmpty) {
                return const Center(child: Text('Нет доступных блюд для техкарт'));
              }

              // Counts
              final int totalCount = rawItems.length;
              int configuredCount = 0;
              for (final it in rawItems) {
                if (summaryMap[it.id]?['has_recipe'] == true) {
                  configuredCount++;
                }
              }
              final int unconfiguredCount = totalCount - configuredCount;

              // Filter by status & search
              final filteredItems = rawItems.where((i) {
                final hasRecipe = summaryMap[i.id]?['has_recipe'] == true;
                if (_statusFilter == RecipeStatusFilter.configured && !hasRecipe) return false;
                if (_statusFilter == RecipeStatusFilter.unconfigured && hasRecipe) return false;

                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase().trim();
                return i.cleanName.toLowerCase().contains(q) ||
                       (i.categoryName != null && i.categoryName!.toLowerCase().contains(q));
              }).toList();

              final Map<String, List<dynamic>> groupedItems = {};
              for (var item in filteredItems) {
                final catId = item.categoryId.toString();
                String catName = 'Без категории';
                if (activeCatMap.containsKey(catId)) {
                  catName = activeCatMap[catId].name;
                } else if (item.categoryName != null && item.categoryName!.isNotEmpty) {
                  catName = item.categoryName!;
                }
                groupedItems.putIfAbsent(catName, () => []).add(item);
              }

              final allCategoryNames = groupedItems.keys.toList();

              // Flatten list
              final List<dynamic> flatList = [];
              groupedItems.forEach((catName, items) {
                final isExpanded = _searchQuery.isNotEmpty || (_expandedCategories[catName] ?? false);
                flatList.add({
                  'type': 'header',
                  'categoryName': catName,
                  'itemsCount': items.length,
                  'isExpanded': isExpanded,
                });
                if (isExpanded) {
                  flatList.addAll(items.map((item) => {'type': 'item', 'item': item}));
                }
              });

              return Column(
                children: [
                  // ── Top Toolbar: Search + Expand All Button ─────────
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
                          onTap: () => _toggleExpandAll(allCategoryNames),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          child: Container(
                            height: 34,
                            width: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
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

                  // ── Status Filter Chips (AppFilterChipSize.sm) ──────
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

                  // ── Categories & Dish List Card ─────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          children: [
                            // ── Top Item: Main Overview / Dashboard Button ─
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
                            Divider(
                              height: 1,
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            const SizedBox(height: 4),

                            // ── Dishes List ───────────────────────────
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                itemCount: flatList.length,
                                itemBuilder: (context, index) {
                                  final data = flatList[index];
                                  if (data['type'] == 'header') {
                                    final catName = data['categoryName'] as String;
                                    final isExpanded = data['isExpanded'] as bool;
                                    final count = data['itemsCount'] as int;

                                    return AppNavTile(
                                      title: catName.toUpperCase(),
                                      count: count,
                                      isExpandable: true,
                                      isExpanded: isExpanded,
                                      size: AppNavTileSize.sm,
                                      onExpandToggle: () => _toggleCategory(catName),
                                      onTap: () => _toggleCategory(catName),
                                    );
                                  } else {
                                    final item = data['item'];
                                    return RecipeDishTile(
                                      item: item,
                                      isSelected: widget.selectedMenuItemId == item.id,
                                      summary: summaryMap[item.id],
                                      catState: catState,
                                      onTap: () {
                                        widget.onMenuItemSelected(item.id);
                                        context.read<RecipeBloc>().add(LoadRecipe(item.id));
                                      },
                                    );
                                  }
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
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
