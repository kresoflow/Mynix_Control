import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'ingredient_category_node.dart';

class IngredientCategorySidebar extends StatefulWidget {
  final int? selectedCategoryId;
  final bool isManageMode;
  final ValueChanged<int?> onCategorySelected;

  const IngredientCategorySidebar({
    super.key,
    required this.selectedCategoryId,
    this.isManageMode = false,
    required this.onCategorySelected,
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
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

    return Container(
      width: 270,
      margin: const EdgeInsets.only(left: 16, top: 12, bottom: 16, right: 12),
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
                // ── Top Toolbar: Search + Expand All (Exact copy of Recipes) ─
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hintText: 'Поиск полки...',
                        isCompact: true,
                        prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _forceExpanded = !(_forceExpanded ?? false)),
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
                              (_forceExpanded == true)
                                  ? PhosphorIconsRegular.caretUp
                                  : PhosphorIconsRegular.caretDown,
                              size: 14,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (_forceExpanded == true) ? 'Свернуть' : 'Развернуть',
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
                          Material(
                            color: widget.selectedCategoryId == null
                                ? AppColors.brandPrimary.withValues(alpha: 0.12)
                                : (isDark ? const Color(0xFF161B26) : const Color(0xFFF1F5F9)),
                            child: InkWell(
                              onTap: () => widget.onCategorySelected(null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: widget.selectedCategoryId == null
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
                                    Expanded(
                                      child: Text(
                                        'ВСЕ СЫРЬЕ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: widget.selectedCategoryId == null
                                              ? AppColors.brandPrimary
                                              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
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
                                        '${ingredients.length}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Categories List
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
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

                          // Bottom Action: Create Category
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 34,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      showAddCategoryDialog(context, type: 'ingredient');
                                    },
                                    icon: const Icon(PhosphorIconsRegular.folderPlus, size: 14),
                                    label: const Text('Создать полку', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.isManageMode && ingredientCategories.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 30,
                                    child: TextButton.icon(
                                      onPressed: () => _confirmDeleteAllCategories(context, ingredientCategories),
                                      icon: const Icon(PhosphorIconsRegular.trash, size: 14, color: AppColors.danger),
                                      label: Text(
                                        'Удалить все (${ingredientCategories.length})',
                                        style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
