import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'catalog_enums.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class CatalogHeader extends StatelessWidget {
  final CategoryManageMode manageMode;
  final CategoryViewMode viewMode;
  final int selectedCount;
  final bool isAllSelected;
  final List<dynamic> navigationHistory;
  final ValueChanged<CategoryManageMode> onManageModeChanged;
  final ValueChanged<CategoryViewMode> onViewModeChanged;
  final VoidCallback onSelectAllToggle;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onNavigateUp;
  final VoidCallback onNavigateToRoot;
  final ValueChanged<int> onNavigateToHistory;
  final VoidCallback onAddPressed;
  final Widget Function(BuildContext, int?)? addMenuBuilder;
  final int? currentCategoryId;
  final bool showArchived;
  final VoidCallback onShowArchivedToggle;
  final String rootTitle;

  const CatalogHeader({
    super.key,
    required this.manageMode,
    required this.viewMode,
    required this.selectedCount,
    required this.isAllSelected,
    required this.navigationHistory,
    required this.onManageModeChanged,
    required this.onViewModeChanged,
    required this.onSelectAllToggle,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onNavigateUp,
    required this.onNavigateToRoot,
    required this.onNavigateToHistory,
    required this.onAddPressed,
    this.addMenuBuilder,
    this.currentCategoryId,
    this.showArchived = false,
    required this.onShowArchivedToggle,
    this.rootTitle = 'Все категории',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: manageMode == CategoryManageMode.delete
            ? colorScheme.errorContainer
            : manageMode == CategoryManageMode.visibility
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: manageMode != CategoryManageMode.none
          ? Row(
              children: [
                if (manageMode == CategoryManageMode.delete) ...[
                  Text('Выбрано: $selectedCount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onErrorContainer)),
                  const Spacer(),
                  TextButton.icon(
                    icon: Icon(isAllSelected ? PhosphorIconsRegular.square : PhosphorIconsRegular.checkSquare),
                    label: Text(isAllSelected ? 'Снять выделение' : 'Выбрать все'),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.onErrorContainer),
                    onPressed: onSelectAllToggle,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(PhosphorIconsRegular.x),
                    label: const Text('Отмена'),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.onErrorContainer),
                    onPressed: onClearSelection,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.trash),
                    label: const Text('Удалить'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                    onPressed: selectedCount == 0 ? null : onDeleteSelected,
                  ),
                ] else if (manageMode == CategoryManageMode.visibility) ...[
                  Icon(PhosphorIconsRegular.eye, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('Настройка видимости на кассе', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onClearSelection,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: const Text('Готово'),
                  ),
                ],
              ],
            )
          : Row(
              children: [
                if (navigationHistory.isNotEmpty) ...[
                  IconButton(icon: const Icon(PhosphorIconsRegular.arrowLeft), onPressed: onNavigateUp, tooltip: 'Назад'),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: onNavigateToRoot,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(rootTitle, style: AppTextStyles.h3),
                          ),
                        ),
                        ...List.generate(navigationHistory.length, (index) {
                          final cat = navigationHistory[index];
                          final isLast = index == navigationHistory.length - 1;
                          return Row(
                            children: [
                              const Icon(PhosphorIconsRegular.caretRight, color: Colors.grey),
                              InkWell(
                                onTap: isLast ? null : () => onNavigateToHistory(index),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                      color: isLast ? colorScheme.primary : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    int? parentId;
                    int? childId;
                    if (navigationHistory.isNotEmpty) {
                      final currentCat = navigationHistory.last;
                      if (currentCat != null) {
                        if (currentCat.parentId == null) {
                          parentId = currentCat.id;
                        } else {
                          parentId = currentCat.parentId;
                          childId = currentCat.id;
                        }
                      }
                    }
                    showDialog(
                      context: context, 
                      builder: (context) => BulkAddModal(
                        initialParentId: parentId,
                        initialChildId: childId,
                      )
                    );
                  },
                  icon: const Icon(PhosphorIconsRegular.listPlus),
                  label: const Text('Массово'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                addMenuBuilder != null ? addMenuBuilder!(context, currentCategoryId) : ElevatedButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(PhosphorIconsRegular.plus),
                  label: const Text('Добавить'),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(PhosphorIconsRegular.faders),
                  tooltip: 'Настройки вида и управления',
                  onSelected: (value) {
                    if (value == 'view_grid') {
                      onViewModeChanged(CategoryViewMode.grid);
                    } else if (value == 'view_list') onViewModeChanged(CategoryViewMode.list);
                    else if (value == 'manage_visibility') onManageModeChanged(CategoryManageMode.visibility);
                    else if (value == 'manage_delete') onManageModeChanged(CategoryManageMode.delete);
                    else if (value == 'toggle_archived') onShowArchivedToggle();
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    if (viewMode == CategoryViewMode.list)
                      const PopupMenuItem<String>(value: 'view_grid', child: ListTile(leading: Icon(PhosphorIconsRegular.gridFour), title: Text('Вид: Сетка'), contentPadding: EdgeInsets.zero)),
                    if (viewMode == CategoryViewMode.grid)
                      const PopupMenuItem<String>(value: 'view_list', child: ListTile(leading: Icon(PhosphorIconsRegular.list), title: Text('Вид: Список'), contentPadding: EdgeInsets.zero)),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(value: 'toggle_archived', child: ListTile(leading: Icon(showArchived ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye), title: Text(showArchived ? 'Скрыть архивные' : 'Показать архивные'), contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem<String>(value: 'manage_visibility', child: ListTile(leading: Icon(PhosphorIconsRegular.sliders), title: Text('Настроить видимость'), contentPadding: EdgeInsets.zero)),
                    PopupMenuItem<String>(value: 'manage_delete', child: ListTile(leading: Icon(PhosphorIconsRegular.trash, color: AppColors.danger), title: Text('Удалить элементы', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
                  ],
                ),
              ],
            ),
    );
  }
}
