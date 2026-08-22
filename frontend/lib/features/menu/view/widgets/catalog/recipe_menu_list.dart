import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
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
              final rawItems = state.items.where((i) => !i.isRetail).toList();
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
                String catName = item.categoryName ?? 'Без категории';
                if ((item.categoryName == null || item.categoryName!.isEmpty) && catState is CategoryLoaded) {
                  final cat = catState.categories.where((c) => c.id.toString() == item.categoryId).firstOrNull;
                  if (cat != null) {
                    catName = cat.name;
                  }
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
                          label: '🟢 Есть ($configuredCount)',
                          isSelected: _statusFilter == RecipeStatusFilter.configured,
                          activeColor: AppColors.success,
                          onTap: () => setState(() => _statusFilter = RecipeStatusFilter.configured),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildFilterChip(
                          label: '⚠️ Нет ($unconfiguredCount)',
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
                            Material(
                              color: widget.selectedMenuItemId == null
                                  ? AppColors.brandPrimary.withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF161B26) : const Color(0xFFF1F5F9)),
                              child: InkWell(
                                onTap: () => widget.onMenuItemSelected(null),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: widget.selectedMenuItemId == null
                                            ? AppColors.brandPrimary
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      bottom: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.chartLineUp,
                                        size: 16,
                                        color: widget.selectedMenuItemId == null
                                            ? AppColors.brandPrimary
                                            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'СВОДКА И ОБЗОР',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: widget.selectedMenuItemId == null
                                                ? AppColors.brandPrimary
                                                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ── Dishes List ───────────────────────────
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: flatList.length,
                                itemBuilder: (context, index) {
                                  final data = flatList[index];
                                  if (data['type'] == 'header') {
                                    final catName = data['categoryName'] as String;
                                    final isExpanded = data['isExpanded'] as bool;
                                    final count = data['itemsCount'] as int;

                                    return Material(
                                      color: isDark ? const Color(0xFF161B26) : const Color(0xFFF1F5F9),
                                      child: InkWell(
                                        onTap: () => _toggleCategory(catName),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  catName.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '$count',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              AnimatedRotation(
                                                turns: isExpanded ? 0.5 : 0.0,
                                                duration: const Duration(milliseconds: 200),
                                                child: Icon(
                                                  PhosphorIconsRegular.caretDown,
                                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                                  size: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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

                                    return Material(
                                      color: isSelected
                                          ? AppColors.brandPrimary.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          widget.onMenuItemSelected(item.id);
                                          context.read<RecipeBloc>().add(LoadRecipe(item.id));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                                                width: 3,
                                              ),
                                              bottom: BorderSide(
                                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (hasIcon) ...[
                                                IconHelper.buildIcon(
                                                  iconStr,
                                                  size: 16,
                                                  color: isSelected
                                                      ? AppColors.brandPrimary
                                                      : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.cleanName,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                        color: isDark ? AppColors.darkText : AppColors.lightText,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 1),
                                                    if (hasRecipe)
                                                      Text(
                                                        '${cost.toStringAsFixed(0)} с • ${marginPercent.toStringAsFixed(0)}% маржа',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.success,
                                                        ),
                                                      )
                                                    else
                                                      Text(
                                                        '⚪ Нет состава',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${item.price.toStringAsFixed(0)} с',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors.brandPrimary
                                                      : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
