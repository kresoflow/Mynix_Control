import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/ingredient/ingredient_quick_setup_card.dart';
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
                .where((c) => c.categoryType == 'ingredient' && c.isVisible)
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
                        ...rootCategories.map((rootCat) => _CategoryNode(
                              category: rootCat,
                              allCategories: ingredientCategories,
                              level: 0,
                              selectedCategoryId: selectedCategoryId,
                              onCategorySelected: onCategorySelected,
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => IngredientQuickSetupCard.showAsDialog(context),
                            icon: const Icon(PhosphorIconsRegular.cards, size: 16),
                            label: const Text('Шаблоны полок'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
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

  class _CategoryNode extends StatefulWidget {
    final MenuCategory category;
    final List<MenuCategory> allCategories;
    final int level;
    final int? selectedCategoryId;
    final ValueChanged<int?> onCategorySelected;

    const _CategoryNode({
      required this.category,
      required this.allCategories,
      required this.level,
      required this.selectedCategoryId,
      required this.onCategorySelected,
    });

    @override
    State<_CategoryNode> createState() => _CategoryNodeState();
  }

  class _CategoryNodeState extends State<_CategoryNode> with SingleTickerProviderStateMixin {
    bool _isExpanded = false;

    @override
    void initState() {
      super.initState();
      _isExpanded = _hasSelectedDescendant();
    }

    @override
    void didUpdateWidget(covariant _CategoryNode oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
        if (_hasSelectedDescendant() && !_isExpanded) {
          _isExpanded = true;
        }
      }
    }

    bool _hasSelectedDescendant() {
      if (widget.selectedCategoryId == widget.category.id) return true;
      bool checkDescendants(int parentId) {
        final children = widget.allCategories.where((c) => c.parentId == parentId);
        for (var child in children) {
          if (child.id == widget.selectedCategoryId) return true;
          if (checkDescendants(child.id)) return true;
        }
        return false;
      }
      return checkDescendants(widget.category.id);
    }

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final children = widget.allCategories.where((c) => c.parentId == widget.category.id).toList();
      final hasChildren = children.isNotEmpty;
      final isSelected = widget.selectedCategoryId == widget.category.id;

      final Widget trailingMenu = PopupMenuButton<String>(
        icon: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        onSelected: (val) {
          if (val == 'edit') {
            showAddCategoryDialog(context, itemToEdit: widget.category);
          } else if (val == 'delete') {
            context.read<CategoryBloc>().add(DeleteCategory(widget.category.id, mode: 'all'));
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
          const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.danger))),
        ],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onCategorySelected(widget.category.id);
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12.0 + (widget.level * 16.0),
                  right: 8.0,
                  top: 10.0,
                  bottom: 10.0,
                ),
                child: Row(
                  children: [
                    IconHelper.buildIcon(
                      widget.category.getInheritedIcon(widget.allCategories),
                      size: 24,
                      color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.category.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                    ),
                    if (hasChildren) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              PhosphorIconsRegular.caretRight,
                              size: 16,
                              color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            ),
                          ),
                        ),
                      ),
                    ],
                    trailingMenu,
                  ],
                ),
              ),
            ),
          ),
          if (hasChildren)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _isExpanded ? null : 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children.map((childCat) => _CategoryNode(
                    category: childCat,
                    allCategories: widget.allCategories,
                    level: widget.level + 1,
                    selectedCategoryId: widget.selectedCategoryId,
                    onCategorySelected: widget.onCategorySelected,
                  )).toList(),
                ),
              ),
            ),
        ],
      );
    }
  }
