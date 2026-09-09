import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/app_nav_tile.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
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
                        child: AppTextField(
                          hintText: 'Поиск блюда...',
                          isCompact: true,
                          prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _toggleExpandAll(allCategoryNames),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _allExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                                size: 14,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _allExpanded ? 'Свернуть' : 'Развернуть',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Status Filter Chips (Все / С техкартой / Без) ────
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip(
                          label: 'Все ($totalCount)',
                          isSelected: _statusFilter == RecipeStatusFilter.all,
                          activeColor: AppColors.brandPrimary,
                          onTap: () => setState(() => _statusFilter = RecipeStatusFilter.all),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildFilterChip(
                          label: 'С составом ($configuredCount)',
                          isSelected: _statusFilter == RecipeStatusFilter.configured,
                          activeColor: AppColors.success,
                          onTap: () => setState(() => _statusFilter = RecipeStatusFilter.configured),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildFilterChip(
                          label: 'Без состава ($unconfiguredCount)',
                          isSelected: _statusFilter == RecipeStatusFilter.unconfigured,
                          activeColor: AppColors.warning,
                          onTap: () => setState(() => _statusFilter = RecipeStatusFilter.unconfigured),
                          isDark: isDark,
                        ),
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
                                    final isSelected = widget.selectedMenuItemId == item.id;
                                    final summary = summaryMap[item.id];
                                    final bool hasRecipe = summary?['has_recipe'] == true;
                                    final double cost = (summary?['total_cost'] as num?)?.toDouble() ?? 0.0;
                                    final double marginPercent = item.price > 0 && cost > 0
                                        ? ((item.price - cost) / item.price) * 100
                                        : 0.0;

                                    String? iconStr = item.icon;
                                    if ((iconStr == null || iconStr.isEmpty) && catState is CategoryLoaded) {
                                      final cat = catState.categories.where((c) => c.id.toString() == item.categoryId).firstOrNull;
                                      iconStr = cat?.getInheritedIcon(catState.categories);
                                    }
                                    final bool hasIcon = iconStr != null &&
                                        iconStr.isNotEmpty &&
                                        (IconHelper.getIcon(iconStr) != null || iconStr.startsWith('svg:'));

                                    return AppNavTile(
                                      title: item.cleanName,
                                      subtitle: hasRecipe
                                          ? '${cost.toStringAsFixed(0)} с • ${marginPercent.toStringAsFixed(0)}% маржа'
                                          : 'Без состава',
                                      leading: hasIcon
                                          ? IconHelper.buildIcon(
                                              iconStr,
                                              size: 16,
                                              color: isSelected
                                                  ? AppColors.brandPrimary
                                                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                            )
                                          : null,
                                      depth: 1,
                                      size: AppNavTileSize.md,
                                      isSelected: isSelected,
                                      trailing: Text(
                                        '${item.price.toStringAsFixed(0)} с',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.brandPrimary
                                              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                        ),
                                      ),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }
}
