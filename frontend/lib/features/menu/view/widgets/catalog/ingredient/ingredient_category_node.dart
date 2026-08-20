import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IngredientCategoryNode extends StatefulWidget {
  final MenuCategory category;
  final List<MenuCategory> allCategories;
  final int level;
  final int? selectedCategoryId;
  final bool isManageMode;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<MenuCategory> onDelete;

  const IngredientCategoryNode({
    super.key,
    required this.category,
    required this.allCategories,
    required this.level,
    required this.selectedCategoryId,
    required this.isManageMode,
    required this.onCategorySelected,
    required this.onDelete,
  });

  @override
  State<IngredientCategoryNode> createState() => _IngredientCategoryNodeState();
}

class _IngredientCategoryNodeState extends State<IngredientCategoryNode> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = _hasSelectedDescendant();
  }

  @override
  void didUpdateWidget(covariant IngredientCategoryNode oldWidget) {
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

    final Widget trailingWidget = widget.isManageMode
        ? IconButton(
            icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
            tooltip: 'Удалить категорию',
            onPressed: () => widget.onDelete(widget.category),
          )
        : PopupMenuButton<String>(
            icon: Icon(
              PhosphorIconsRegular.dotsThreeVertical,
              size: 18,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
            onSelected: (val) {
              if (val == 'edit') {
                showAddCategoryDialog(context, itemToEdit: widget.category);
              } else if (val == 'delete') {
                widget.onDelete(widget.category);
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
            onTap: () => widget.onCategorySelected(widget.category.id),
            child: Padding(
              padding: EdgeInsets.only(
                left: 12.0 + (widget.level * 16.0),
                right: 4.0,
                top: 8.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  IconHelper.buildIcon(
                    widget.category.getInheritedIcon(widget.allCategories),
                    size: 22,
                    color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                  const SizedBox(width: 10),
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
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
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
                  trailingWidget,
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
                children: children.map((childCat) => IngredientCategoryNode(
                  category: childCat,
                  allCategories: widget.allCategories,
                  level: widget.level + 1,
                  selectedCategoryId: widget.selectedCategoryId,
                  isManageMode: widget.isManageMode,
                  onCategorySelected: widget.onCategorySelected,
                  onDelete: widget.onDelete,
                )).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
