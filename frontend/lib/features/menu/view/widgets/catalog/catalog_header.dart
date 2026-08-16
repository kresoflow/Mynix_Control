import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'catalog_enums.dart';
import 'catalog_header_manage_mode.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_segmented_tab.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

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
  final String rootTitle;
  final bool showArchived;
  final VoidCallback onShowArchivedToggle;

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
    required this.currentCategoryId,
    required this.rootTitle,
    required this.showArchived,
    required this.onShowArchivedToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: manageMode != CategoryManageMode.none
          ? CatalogHeaderManageMode(
              manageMode: manageMode,
              isMobile: isMobile,
              selectedCount: selectedCount,
              isAllSelected: isAllSelected,
              onClearSelection: onClearSelection,
              onSelectAllToggle: onSelectAllToggle,
              onDeleteSelected: onDeleteSelected,
            )
          : (isMobile ? _buildMobileDefaultMode(context, colorScheme) : _buildDesktopDefaultMode(context, colorScheme)),
    );
  }

  Widget _buildMobileDefaultMode(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (navigationHistory.isNotEmpty)
              IconButton(icon: const Icon(PhosphorIconsRegular.arrowLeft), onPressed: onNavigateUp),
            Expanded(child: _buildBreadcrumbs(context, isMobile: true)),
            IconButton(
              icon: Icon(showArchived ? PhosphorIconsRegular.archive : PhosphorIconsRegular.tray),
              color: showArchived ? AppColors.brandPrimary : null,
              tooltip: showArchived ? 'Скрыть архивные' : 'Показать архивные',
              onPressed: onShowArchivedToggle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildViewModeToggle(),
            const SizedBox(width: 8),
            _buildManageMenu(context),
            const Spacer(),
            if (addMenuBuilder != null)
              addMenuBuilder!(context, currentCategoryId)
            else
              AppPrimaryButton(
                label: 'Добавить',
                icon: PhosphorIconsRegular.plus,
                height: 38,
                onPressed: onAddPressed,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopDefaultMode(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        if (navigationHistory.isNotEmpty)
          IconButton(icon: const Icon(PhosphorIconsRegular.arrowLeft), onPressed: onNavigateUp),
        Expanded(child: _buildBreadcrumbs(context, isMobile: false)),
        IconButton(
          icon: Icon(showArchived ? PhosphorIconsRegular.archive : PhosphorIconsRegular.tray),
          color: showArchived ? AppColors.brandPrimary : null,
          tooltip: showArchived ? 'Скрыть архивные' : 'Показать архивные',
          onPressed: onShowArchivedToggle,
        ),
        const SizedBox(width: 8),
        _buildViewModeToggle(),
        const SizedBox(width: 8),
        _buildManageMenu(context),
        const SizedBox(width: 16),
        if (addMenuBuilder != null)
          addMenuBuilder!(context, currentCategoryId)
        else
          AppPrimaryButton(
            label: 'Добавить',
            icon: PhosphorIconsRegular.plus,
            height: 38,
            onPressed: onAddPressed,
          ),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, {required bool isMobile}) {
    final List<Widget> crumbs = [];
    crumbs.add(
      InkWell(
        onTap: onNavigateToRoot,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            rootTitle,
            style: isMobile ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.h2,
          ),
        ),
      ),
    );

    for (int i = 0; i < navigationHistory.length; i++) {
      final isLast = i == navigationHistory.length - 1;
      final category = navigationHistory[i];
      crumbs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(PhosphorIconsRegular.caretRight, size: isMobile ? 14 : 18, color: Theme.of(context).disabledColor),
        ),
      );
      crumbs.add(
        InkWell(
          onTap: isLast ? null : () => onNavigateToHistory(i),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              category.name,
              style: isLast
                  ? (isMobile ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.h2)
                  : (isMobile ? AppTextStyles.caption : AppTextStyles.bodyMedium).copyWith(color: Theme.of(context).disabledColor),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: crumbs),
    );
  }

  Widget _buildViewModeToggle() {
    return AppSegmentedTab<CategoryViewMode>(
      height: 38,
      isCompact: true,
      items: const [
        AppSegmentedTabItem(
          value: CategoryViewMode.grid,
          label: '',
          icon: PhosphorIconsRegular.squaresFour,
        ),
        AppSegmentedTabItem(
          value: CategoryViewMode.list,
          label: '',
          icon: PhosphorIconsRegular.listDashes,
        ),
      ],
      selectedValue: viewMode,
      onValueChanged: onViewModeChanged,
    );
  }

  Widget _buildManageMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
      onSelected: (val) {
        if (val == 'delete') {
          onManageModeChanged(CategoryManageMode.delete);
        } else if (val == 'visibility') {
          onManageModeChanged(CategoryManageMode.visibility);
        } else if (val == 'bulk_add') {
          showDialog(
            context: context,
            builder: (ctx) => BulkAddModal(initialParentId: currentCategoryId),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'bulk_add',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.table, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              const Text('Массовое добавление'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'visibility',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.eye, size: 18),
              SizedBox(width: 8),
              Text('Скрыть/показать категории'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Удалить элементы', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
