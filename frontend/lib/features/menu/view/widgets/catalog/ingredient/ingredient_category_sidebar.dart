import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'ingredient_category_node.dart';

class IngredientCategorySidebar extends StatefulWidget {
  final int? selectedCategoryId;
  final bool isManageMode;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<String>? onSearchChanged;

  const IngredientCategorySidebar({
    super.key,
    required this.selectedCategoryId,
    this.isManageMode = false,
    required this.onCategorySelected,
    this.onSearchChanged,
  });

  @override
  State<IngredientCategorySidebar> createState() => _IngredientCategorySidebarState();
}

class _IngredientCategorySidebarState extends State<IngredientCategorySidebar> {
  bool? _forceExpanded;
  String _searchQuery = '';

  void _confirmDeleteCategory(BuildContext context, MenuCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление категории'),
        content: Text('Удалить полку «${category.name}»? Привязанное сырьё станет «Без категории».'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategory(category.id, mode: 'all'));
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllCategories(BuildContext context, List<MenuCategory> categories) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Массовое удаление полок'),
        content: Text('Удалить все категории сырья (${categories.length} шт.)? Привязанное сырьё станет «Без категории».'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              final ids = categories.map((c) => c.id).toList();
              context.read<CategoryBloc>().add(DeleteCategoriesBulk(ids, mode: 'all'));
              Navigator.pop(ctx);
            },
            child: const Text('Удалить все'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ingState = context.watch<IngredientBloc>().state;
    final ingredients = ingState is IngredientLoaded
        ? ingState.ingredients.where((i) => !i.isRetail).toList()
        : [];

    return SizedBox(
      width: 270,
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, catState) {
          if (catState is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (catState is CategoryLoaded) {
            final ingredientCategories = catState.categories
                .where((c) => c.categoryType == 'ingredient' && c.isVisible)
                .toList();

            final filteredCategories = ingredientCategories.where((c) {
              if (_searchQuery.isEmpty) return true;
              return c.name.toLowerCase().contains(_searchQuery.toLowerCase().trim());
            }).toList();

            final rootCategories = filteredCategories.where((c) => c.parentId == null).toList();

            return Column(
              children: [
                // ── Top Toolbar: Search + Expand All ─────────────────
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        size: AppSearchFieldSize.sm,
                        hintText: 'Поиск...',
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          widget.onSearchChanged?.call(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: (_forceExpanded == true) ? 'Свернуть все' : 'Развернуть все',
                      child: InkWell(
                        onTap: () => setState(() => _forceExpanded = !(_forceExpanded ?? false)),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Icon(
                            (_forceExpanded == true)
                                ? PhosphorIconsRegular.caretUp
                                : PhosphorIconsRegular.caretDown,
                            size: 16,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Categories List Card (Enclosed Rounded Container) ─
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
                          // Top item: All Ingredients
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: AppNavTile(
                              title: 'ВСЕ СЫРЬЕ',
                              count: ingredients.length,
                              isSelected: widget.selectedCategoryId == null,
                              size: AppNavTileSize.md,
                              onTap: () => widget.onCategorySelected(null),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          const SizedBox(height: 4),

                          // Categories List
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              children: [
                                ...rootCategories.map((rootCat) {
                                  final count = ingredients.where((i) => i.categoryId == rootCat.id).length;
                                  return IngredientCategoryNode(
                                    category: rootCat,
                                    allCategories: ingredientCategories,
                                    itemCount: count,
                                    level: 0,
                                    selectedCategoryId: widget.selectedCategoryId,
                                    isManageMode: widget.isManageMode,
                                    forceExpanded: _forceExpanded,
                                    onCategorySelected: widget.onCategorySelected,
                                    onDelete: (cat) => _confirmDeleteCategory(context, cat),
                                  );
                                  }),
                              ],
                            ),
                          ),

                          if (widget.isManageMode && ingredientCategories.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: TextButton.icon(
                                  onPressed: () => _confirmDeleteAllCategories(context, ingredientCategories),
                                  icon: const Icon(PhosphorIconsRegular.trash, size: 14, color: AppColors.danger),
                                  label: Text(
                                    'Удалить все (${ingredientCategories.length})',
                                    style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
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
          return const SizedBox();
        },
      ),
    );
  }
}
