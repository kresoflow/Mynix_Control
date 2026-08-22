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
  final bool? forceExpanded;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<MenuCategory> onDelete;

  const IngredientCategoryNode({
    super.key,
    required this.category,
    required this.allCategories,
    required this.level,
    required this.selectedCategoryId,
    required this.isManageMode,
    this.forceExpanded,
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
    _isExpanded = widget.forceExpanded ?? _hasSelectedDescendant();
  }

  @override
  void didUpdateWidget(covariant IngredientCategoryNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceExpanded != null && widget.forceExpanded != oldWidget.forceExpanded) {
      _isExpanded = widget.forceExpanded!;
    } else if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
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
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.15)
              : Colors.transparent,
          child: InkWell(
            onTap: () => widget.onCategorySelected(widget.category.id),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.0 + (widget.level * 16.0),
                right: 8.0,
                top: 4.0,
                bottom: 4.0,
              ),
              child: Row(
                children: [
                  if (hasChildren)
                    IconButton(
                      icon: Icon(
                        _isExpanded ? PhosphorIconsRegular.caretDown : PhosphorIconsRegular.caretRight,
                        size: 14,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    )
                  else
                    const SizedBox(width: 14),
                  const SizedBox(width: 8),

                  if (widget.category.icon != null && widget.category.icon!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconHelper.buildIcon(
                        widget.category.icon,
                        size: 16,
                        color: isSelected
                            ? AppColors.brandPrimary
                            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                      ),
                    ),

                  Expanded(
                    child: Text(
                      widget.category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.brandPrimary
                            : (isDark ? AppColors.darkText : AppColors.lightText),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  trailingWidget,
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && _isExpanded)
          ...children.map((child) => IngredientCategoryNode(
                category: child,
                allCategories: widget.allCategories,
                level: widget.level + 1,
                selectedCategoryId: widget.selectedCategoryId,
                isManageMode: widget.isManageMode,
                forceExpanded: widget.forceExpanded,
                onCategorySelected: widget.onCategorySelected,
                onDelete: widget.onDelete,
              )),
      ],
    );
  }
}
