import 'package:flutter/material.dart';
import 'catalog_enums.dart';
import 'catalog_header_manage_mode.dart';
import 'catalog_breadcrumbs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

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
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onToggleVisibilitySelected;

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
    this.onSearchChanged,
    this.onToggleVisibilitySelected,
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
              onToggleVisibilitySelected: onToggleVisibilitySelected,
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
            if (navigationHistory.isNotEmpty) ...[
              AppGhostButton(
                label: '',
                icon: PhosphorIconsRegular.arrowLeft,
                height: 32,
                width: 32,
                size: AppButtonSize.sm,
                onPressed: onNavigateUp,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: CatalogBreadcrumbs(
                rootTitle: rootTitle,
                navigationHistory: navigationHistory,
                isMobile: true,
                onNavigateToRoot: onNavigateToRoot,
                onNavigateToHistory: onNavigateToHistory,
              ),
            ),
            if (onSearchChanged != null) ...[
              AppSearchField(
                mode: AppSearchMode.collapsible,
                size: AppSearchFieldSize.sm,
                hintText: 'Поиск...',
                onChanged: onSearchChanged,
              ),
              const SizedBox(width: 6),
            ],
            AppSecondaryButton(
              label: '',
              icon: showArchived ? PhosphorIconsRegular.archive : PhosphorIconsRegular.tray,
              tooltip: showArchived ? 'Скрыть архивные' : 'Показать архивные',
              isSelected: showArchived,
              height: 32,
              width: 32,
              size: AppButtonSize.sm,
              onPressed: onShowArchivedToggle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildViewModeToggle(isMobile: true),
            const SizedBox(width: 8),
            AppSecondaryButton(
              label: 'Выбрать',
              icon: PhosphorIconsRegular.checkSquareOffset,
              height: 32,
              size: AppButtonSize.sm,
              onPressed: () => onManageModeChanged(CategoryManageMode.delete),
            ),
            const Spacer(),
            if (addMenuBuilder != null)
              addMenuBuilder!(context, currentCategoryId)
            else
              AppPrimaryButton(
                label: 'Добавить',
                icon: PhosphorIconsRegular.plus,
                height: 32,
                size: AppButtonSize.sm,
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
        if (navigationHistory.isNotEmpty) ...[
          AppGhostButton(
            label: '',
            icon: PhosphorIconsRegular.arrowLeft,
            tooltip: 'Назад',
            height: 38,
            width: 38,
            size: AppButtonSize.md,
            onPressed: onNavigateUp,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: CatalogBreadcrumbs(
            rootTitle: rootTitle,
            navigationHistory: navigationHistory,
            isMobile: false,
            onNavigateToRoot: onNavigateToRoot,
            onNavigateToHistory: onNavigateToHistory,
          ),
        ),
        // ── Group 1: Search & View Controls ──────────────────────────
        if (onSearchChanged != null) ...[
          AppSearchField(
            mode: AppSearchMode.collapsible,
            size: AppSearchFieldSize.md,
            hintText: 'Поиск в каталоге...',
            shortcutHint: 'Ctrl+F',
            onChanged: onSearchChanged,
          ),
          const SizedBox(width: 8),
        ],
        AppSecondaryButton(
          label: '',
          icon: showArchived ? PhosphorIconsRegular.archive : PhosphorIconsRegular.tray,
          tooltip: showArchived ? 'Скрыть архивные' : 'Показать архивные',
          isSelected: showArchived,
          height: 38,
          width: 38,
          size: AppButtonSize.md,
          onPressed: onShowArchivedToggle,
        ),
        const SizedBox(width: 8),
        _buildViewModeToggle(isMobile: false),
        const SizedBox(width: 12),

        // ── Group 2: Operations ──────────────────────────────────────
        AppSecondaryButton(
          label: 'Выбрать',
          icon: PhosphorIconsRegular.checkSquareOffset,
          height: 38,
          size: AppButtonSize.md,
          onPressed: () => onManageModeChanged(CategoryManageMode.delete),
        ),
        const SizedBox(width: 12),

        // ── Group 3: Primary CTA ─────────────────────────────────────
        if (addMenuBuilder != null)
          addMenuBuilder!(context, currentCategoryId)
        else
          AppPrimaryButton(
            label: 'Добавить',
            icon: PhosphorIconsRegular.plus,
            height: 38,
            size: AppButtonSize.md,
            onPressed: onAddPressed,
          ),
      ],
    );
  }

  Widget _buildViewModeToggle({required bool isMobile}) {
    return AppSegmentedControl<CategoryViewMode>(
      size: isMobile ? AppSegmentedSize.sm : AppSegmentedSize.md,
      items: const [
        AppSegmentedItem(
          value: CategoryViewMode.grid,
          icon: PhosphorIconsRegular.squaresFour,
          tooltip: 'Сетка',
        ),
        AppSegmentedItem(
          value: CategoryViewMode.list,
          icon: PhosphorIconsRegular.listDashes,
          tooltip: 'Список',
        ),
      ],
      selectedValue: viewMode,
      onValueChanged: onViewModeChanged,
    );
  }
}
