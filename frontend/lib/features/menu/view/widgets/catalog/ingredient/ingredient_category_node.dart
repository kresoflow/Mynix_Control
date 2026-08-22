import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IngredientCategoryNode extends StatefulWidget {
  final MenuCategory category;
  final List<MenuCategory> allCategories;
  final int itemCount;
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
    required this.itemCount,
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
            icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
            tooltip: 'Удалить категорию',
            onPressed: () => widget.onDelete(widget.category),
          )
        : SizedBox(
            width: 20,
            height: 20,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                size: 14,
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
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.12)
              : Colors.transparent,
          child: InkWell(
            onTap: () => widget.onCategorySelected(widget.category.id),
            child: Container(
              padding: EdgeInsets.only(
                left: 12.0 + (widget.level * 12.0),
                right: 8.0,
                top: 8.0,
                bottom: 8.0,
              ),
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
                  if (hasChildren)
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            PhosphorIconsRegular.caretRight,
                            size: 12,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 4),

                  if (widget.category.icon != null && widget.category.icon!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0, left: 2.0),
                      child: IconHelper.buildIcon(
                        widget.category.icon,
                        size: 14,
                        color: isSelected
                            ? AppColors.brandPrimary
                            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                      ),
                    ),

                  Expanded(
                    child: Text(
                      widget.category.name,
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

                  if (widget.itemCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.itemCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
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
                itemCount: widget.itemCount,
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
