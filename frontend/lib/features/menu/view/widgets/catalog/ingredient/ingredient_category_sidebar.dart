import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
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

    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, catState) {
          if (catState is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (catState is CategoryLoaded) {
            final ingredientCategories = catState.categories
                .where((c) => c.categoryType == 'ingredient' && c.isVisible)
                .toList();

            final rootCategories = ingredientCategories.where((c) => c.parentId == null).toList();
            final hasSubcategories = ingredientCategories.any((c) => c.parentId != null);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      ListTile(
                        title: Text(
                          'Все сырье',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.selectedCategoryId == null 
                                ? AppColors.brandPrimary 
                                : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                        ),
                        trailing: hasSubcategories
                            ? InkWell(
                                onTap: () => setState(() => _forceExpanded = !(_forceExpanded ?? false)),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    (_forceExpanded == true)
                                        ? PhosphorIconsRegular.caretUp
                                        : PhosphorIconsRegular.caretDown,
                                    size: 16,
                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                  ),
                                ),
                              )
                            : null,
                        selected: widget.selectedCategoryId == null,
                        selectedTileColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                        onTap: () => widget.onCategorySelected(null),
                      ),
                      const Divider(),
                      ...rootCategories.map((rootCat) => IngredientCategoryNode(
                            category: rootCat,
                            allCategories: ingredientCategories,
                            level: 0,
                            selectedCategoryId: widget.selectedCategoryId,
                            isManageMode: widget.isManageMode,
                            forceExpanded: _forceExpanded,
                            onCategorySelected: widget.onCategorySelected,
                            onDelete: (cat) => _confirmDeleteCategory(context, cat),
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showAddCategoryDialog(context, type: 'ingredient');
                          },
                          icon: const Icon(PhosphorIconsRegular.folderPlus),
                          label: const Text('Создать категорию'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (widget.isManageMode && ingredientCategories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _confirmDeleteAllCategories(context, ingredientCategories),
                            icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
                            label: Text(
                              'Удалить все полки (${ingredientCategories.length})',
                              style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ],
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
