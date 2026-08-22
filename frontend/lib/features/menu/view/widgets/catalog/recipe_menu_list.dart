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

class RecipeMenuList extends StatefulWidget {
  final int? selectedMenuItemId;
  final ValueChanged<int> onMenuItemSelected;

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

              // Search filtering
              final filteredItems = rawItems.where((i) {
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
                // If search active, auto-expand
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
                  const SizedBox(height: 10),

                  // ── Categories & Dish List ───────────────────────────
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                            size: 18,
                                            color: isSelected
                                                ? AppColors.brandPrimary
                                                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            item.cleanName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected
                                                  ? (isDark ? AppColors.darkText : AppColors.lightText)
                                                  : (isDark ? AppColors.darkText : AppColors.lightText),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
