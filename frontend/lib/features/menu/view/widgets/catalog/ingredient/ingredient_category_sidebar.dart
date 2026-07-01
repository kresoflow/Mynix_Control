import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IngredientCategorySidebar extends StatelessWidget {
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;

  const IngredientCategorySidebar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

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
                .where((c) => c.categoryType == 'ingredient')
                .toList();

            // Строим дерево
            final rootCategories = ingredientCategories.where((c) => c.parentId == null).toList();

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
                            color: selectedCategoryId == null 
                                ? AppColors.brandPrimary 
                                : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                        ),
                        selected: selectedCategoryId == null,
                        selectedTileColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                        onTap: () => onCategorySelected(null),
                      ),
                      const Divider(),
                      ...rootCategories.map((rootCat) => _buildCategoryNode(
                            context: context,
                            category: rootCat,
                            allCategories: ingredientCategories,
                            isDark: isDark,
                            level: 0,
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showAddCategoryDialog(context, type: 'ingredient');
                      },
                      icon: const Icon(PhosphorIconsRegular.folderPlus),
                      label: const Text('Создать категорию'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildCategoryNode({
    required BuildContext context,
    required MenuCategory category,
    required List<MenuCategory> allCategories,
    required bool isDark,
    required int level,
  }) {
    final children = allCategories.where((c) => c.parentId == category.id).toList();
    final isSelected = selectedCategoryId == category.id;
    final hasChildren = children.isNotEmpty;

    Widget trailingMenu = PopupMenuButton<String>(
      icon: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
      onSelected: (val) {
        if (val == 'edit') {
          showAddCategoryDialog(context, itemToEdit: category);
        } else if (val == 'delete') {
          context.read<CategoryBloc>().add(DeleteCategory(category.id, mode: 'all'));
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
        const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
      ],
    );

    if (hasChildren) {
      // Изначально развернуто, если выбран дочерний элемент
      final isChildSelected = children.any((c) => c.id == selectedCategoryId);
      
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isChildSelected || isSelected,
          tilePadding: EdgeInsets.only(left: 16.0 + (level * 16.0), right: 8.0),
          leading: IconHelper.buildIcon(
            category.getInheritedIcon(allCategories),
            size: 24,
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          title: GestureDetector(
            onTap: () => onCategorySelected(category.id),
            child: Text(
              category.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ),
          trailing: trailingMenu,
          children: children.map((childCat) => _buildCategoryNode(
                context: context,
                category: childCat,
                allCategories: allCategories,
                isDark: isDark,
                level: level + 1,
              )).toList(),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: level * 16.0),
        child: ListTile(
          leading: IconHelper.buildIcon(
            category.getInheritedIcon(allCategories),
            size: 24,
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
          selected: isSelected,
          selectedTileColor: AppColors.brandPrimary.withValues(alpha: 0.1),
          onTap: () => onCategorySelected(category.id),
          trailing: trailingMenu,
        ),
      );
    }
  }
}
