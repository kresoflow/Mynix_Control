import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_kpi_cards.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_grid_view.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add_modal.dart';

class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> {
  int? _selectedCategoryId;
  bool _isManageMode = false;
  bool _isGridView = false;
  bool _showArchived = false;
  final Set<int> _selectedIngredients = {};
  String _searchQuery = '';

  void _selectAll(IngredientLoaded state) {
    final raw = state.ingredients
        .where((i) => !i.isRetail && (_showArchived ? i.isArchived : !i.isArchived))
        .toList();
    final filtered = _selectedCategoryId == null
        ? raw
        : raw.where((i) => i.categoryId == _selectedCategoryId).toList();
    setState(() {
      _selectedIngredients.addAll(filtered.map((i) => i.id));
    });
  }

  void _confirmRestoreSelected() {
    for (var itemId in _selectedIngredients) {
      context.read<IngredientBloc>().add(RestoreIngredient(itemId));
    }
    setState(() {
      _selectedIngredients.clear();
      _isManageMode = false;
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final isHard = _showArchived;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: isHard ? 'Удаление навсегда' : 'Массовая архивация',
      message: isHard
          ? 'Удалить навсегда выбранные элементы (${_selectedIngredients.length} шт.)?\nЭто действие необратимо и возможно только если по сырью нет складских проводок.'
          : 'Архивировать выбранные элементы (${_selectedIngredients.length} шт.)?\nОни исчезнут из активных списков, но сохранятся в истории склада.',
      confirmLabel: isHard ? 'Удалить навсегда' : 'Архивировать',
      isDanger: true,
      icon: isHard ? PhosphorIconsRegular.trash : PhosphorIconsRegular.archive,
    );
    if (confirmed == true && mounted) {
      for (var itemId in _selectedIngredients) {
        context.read<IngredientBloc>().add(DeleteIngredient(itemId, mode: isHard ? 'hard' : 'soft'));
      }
      setState(() {
        _selectedIngredients.clear();
        _isManageMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ingState = context.watch<IngredientBloc>().state;
    final archivedCount = ingState is IngredientLoaded
        ? ingState.ingredients.where((i) => !i.isRetail && i.isArchived).length
        : 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Clean Header Row matching RecipeTab ─────────────────────
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 750;
              final actionButtons = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isManageMode) ...[
                      Builder(
                        builder: (context) {
                          final raw = ingState is IngredientLoaded
                              ? ingState.ingredients.where((i) => !i.isRetail && (_showArchived ? i.isArchived : !i.isArchived)).toList()
                              : [];
                          final filtered = _selectedCategoryId == null
                              ? raw
                              : raw.where((i) => i.categoryId == _selectedCategoryId).toList();
                          final isAllSelected = filtered.isNotEmpty && _selectedIngredients.length == filtered.length;
                          final IconData badgeIcon = _selectedIngredients.isEmpty
                              ? PhosphorIconsRegular.square
                              : (isAllSelected ? PhosphorIconsRegular.checkSquare : PhosphorIconsRegular.minusSquare);
                          final Color badgeColor = _selectedIngredients.isNotEmpty
                              ? (_showArchived ? AppColors.brandPrimary : AppColors.danger)
                              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedIngredients.isNotEmpty
                                      ? (_showArchived ? AppColors.brandPrimary : AppColors.danger).withValues(alpha: isDark ? 0.2 : 0.1)
                                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                  borderRadius: AppRadii.inputRadius,
                                  border: Border.all(
                                    color: _selectedIngredients.isNotEmpty
                                        ? (_showArchived ? AppColors.brandPrimary : AppColors.danger).withValues(alpha: 0.4)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      badgeIcon,
                                      size: 16,
                                      color: badgeColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Выбрано: ${_selectedIngredients.length}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _selectedIngredients.isNotEmpty
                                            ? badgeColor
                                            : (isDark ? AppColors.darkText : AppColors.lightText),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppSecondaryButton(
                                label: isAllSelected ? 'Снять выделение' : 'Выбрать все',
                                icon: isAllSelected ? PhosphorIconsRegular.checkSquare : PhosphorIconsRegular.square,
                                isSelected: isAllSelected,
                                height: 38,
                                size: AppButtonSize.md,
                                onPressed: () {
                                  if (isAllSelected) {
                                    setState(() => _selectedIngredients.clear());
                                  } else if (ingState is IngredientLoaded) {
                                    _selectAll(ingState);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      if (_showArchived) ...[
                        AppPrimaryButton(
                          label: 'Восстановить (${_selectedIngredients.length})',
                          icon: PhosphorIconsRegular.arrowCounterClockwise,
                          height: 38,
                          size: AppButtonSize.md,
                          onPressed: _selectedIngredients.isEmpty ? null : _confirmRestoreSelected,
                        ),
                        const SizedBox(width: 8),
                      ],
                      AppDangerButton(
                        label: _showArchived ? 'Удалить навсегда (${_selectedIngredients.length})' : 'Архивировать (${_selectedIngredients.length})',
                        icon: _showArchived ? PhosphorIconsRegular.trash : PhosphorIconsRegular.archive,
                        height: 38,
                        size: AppButtonSize.md,
                        onPressed: _selectedIngredients.isEmpty ? null : _confirmDeleteSelected,
                      ),
                      const SizedBox(width: 8),
                      AppGhostButton(
                        label: 'Отмена',
                        icon: PhosphorIconsRegular.x,
                        height: 38,
                        size: AppButtonSize.md,
                        onPressed: () => setState(() {
                          _isManageMode = false;
                          _selectedIngredients.clear();
                        }),
                      ),
                    ] else ...[
                      // Group 1: View Switcher (Grid / List)
                      AppSegmentedControl<bool>(
                        size: AppSegmentedSize.md,
                        selectedValue: _isGridView,
                        onValueChanged: (val) => setState(() => _isGridView = val),
                        items: const [
                          AppSegmentedItem(
                            value: true,
                            icon: PhosphorIconsRegular.squaresFour,
                            tooltip: 'Сетка',
                          ),
                          AppSegmentedItem(
                            value: false,
                            icon: PhosphorIconsRegular.listDashes,
                            tooltip: 'Список',
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Group 1.5: Archive Toggle with badge
                      Badge(
                        isLabelVisible: archivedCount > 0,
                        label: Text('$archivedCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.brandPrimary,
                        offset: const Offset(4, -4),
                        child: AppSecondaryButton(
                          label: '',
                          icon: PhosphorIconsRegular.archive,
                          tooltip: _showArchived ? 'Скрыть архив' : (archivedCount > 0 ? 'Архив ($archivedCount)' : 'Архив'),
                          isSelected: _showArchived,
                          height: 38,
                          width: 38,
                          size: AppButtonSize.md,
                          onPressed: () => setState(() {
                            _showArchived = !_showArchived;
                            _selectedIngredients.clear();
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Group 2: Operations
                      AppSecondaryButton(
                        label: 'Выбрать',
                        icon: PhosphorIconsRegular.checkSquareOffset,
                        height: 38,
                        size: AppButtonSize.md,
                        onPressed: () => setState(() => _isManageMode = true),
                      ),
                      const SizedBox(width: 10),

                      // Group 3: Main CTA Button
                      AppMenuButton(
                        label: 'Добавить',
                        icon: PhosphorIconsRegular.plus,
                        size: AppButtonSize.md,
                        items: const [
                          AppMenuItem(id: 'ingredient', label: 'Сырье / Ингредиент', icon: PhosphorIconsRegular.leaf),
                          AppMenuItem(id: 'category', label: 'Категория сырья', icon: PhosphorIconsRegular.folderPlus),
                          AppMenuDivider(),
                          AppMenuItem(id: 'bulk_add', label: 'Массовый ввод', icon: PhosphorIconsRegular.table),
                        ],
                        onSelected: (val) {
                          if (val == 'ingredient') {
                            showAddIngredientDialog(context, initialCategoryId: _selectedCategoryId);
                          } else if (val == 'category') {
                            showAddCategoryDialog(context, currentCategoryId: _selectedCategoryId, type: 'ingredient');
                          } else if (val == 'bulk_add') {
                            showDialog(
                              context: context,
                              builder: (_) => BulkAddModal(initialTabIndex: 2, initialParentId: _selectedCategoryId),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сырье и заготовки', style: AppTextStyles.h2),
                    const SizedBox(height: 10),
                    actionButtons,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Сырье и заготовки',
                    style: AppTextStyles.h2,
                  ),
                  actionButtons,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Main Body: Left Sidebar + Right KPI & Content Area ──────
          Expanded(
            child: BlocListener<IngredientBloc, IngredientState>(
              listener: (context, state) {
                if (state is IngredientError) {
                  AppToast.showError(
                    context,
                    'Ошибка сырья',
                    subtitle: state.message.replaceAll('Exception: ', ''),
                  );
                }
              },
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, categoryState) {
                  return BlocBuilder<IngredientBloc, IngredientState>(
                    builder: (context, state) {
                      if (state is IngredientLoading || categoryState is CategoryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is IngredientLoaded && categoryState is CategoryLoaded) {
                        final filteredList = state.ingredients.where((i) {
                          if (i.isRetail) return false;
                          if (!_showArchived && i.isArchived) return false;
                          if (_showArchived && !i.isArchived) return false;
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase().trim();
                          return i.name.toLowerCase().contains(q) ||
                                 '#${i.id}'.contains(q) ||
                                 '${i.id}' == q ||
                                 (i.barcode != null && i.barcode!.toLowerCase().contains(q));
                        }).toList();

                        return LayoutBuilder(
                          builder: (context, bodyConstraints) {
                            final showSidebar = bodyConstraints.maxWidth >= 768;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showSidebar) ...[
                                  IngredientCategorySidebar(
                                    selectedCategoryId: _selectedCategoryId,
                                    isManageMode: _isManageMode,
                                    onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                                    onSearchChanged: (q) => setState(() => _searchQuery = q),
                                  ),
                                  const SizedBox(width: 16),
                                ],

                                // ── Right Workspace (Expanded) ────────────
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  // 3 KPI Cards Row (matching Recipe Tab)
                                  IngredientKpiCards(ingredients: state.ingredients),
                                  const SizedBox(height: 14),

                                  // Archive Mode Information Banner
                                  if (_showArchived) ...[
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                        borderRadius: AppRadii.inputRadius,
                                        border: Border.all(
                                          color: AppColors.brandPrimary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(PhosphorIconsRegular.archive, size: 18, color: AppColors.brandPrimary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Режим архива ($archivedCount поз.). Архивные позиции скрыты из кассы, накладных и расчетов остатков.',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                fontSize: 13,
                                                color: isDark ? AppColors.darkText : AppColors.lightText,
                                              ),
                                            ),
                                          ),
                                          AppGhostButton(
                                            label: 'Закрыть архив',
                                            icon: PhosphorIconsRegular.x,
                                            size: AppButtonSize.sm,
                                            onPressed: () => setState(() {
                                              _showArchived = false;
                                              _selectedIngredients.clear();
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Table or Grid View
                                  Expanded(
                                    child: _isGridView
                                        ? IngredientGridView(
                                            ingredients: filteredList,
                                            selectedCategoryId: _selectedCategoryId,
                                            isManageMode: _isManageMode,
                                            selectedIngredients: _selectedIngredients,
                                            onToggleSelect: (id, sel) {
                                              setState(() {
                                                if (sel) {
                                                  _selectedIngredients.add(id);
                                                } else {
                                                  _selectedIngredients.remove(id);
                                                }
                                              });
                                            },
                                          )
                                        : IngredientTableView(
                                            ingredients: filteredList,
                                            selectedCategoryId: _selectedCategoryId,
                                            isManageMode: _isManageMode,
                                            selectedIngredients: _selectedIngredients,
                                            onToggleSelect: (id, sel) {
                                              setState(() {
                                                if (sel) {
                                                  _selectedIngredients.add(id);
                                                } else {
                                                  _selectedIngredients.remove(id);
                                                }
                                              });
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                      } else if (state is IngredientError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(PhosphorIconsRegular.warningCircle, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text('Не удалось загрузить сырье', style: AppTextStyles.h3),
                              const SizedBox(height: 6),
                              Text(state.message.replaceAll('Exception: ', ''), style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 13)),
                              const SizedBox(height: 16),
                              AppSecondaryButton(
                                label: 'Повторить попытку',
                                icon: PhosphorIconsRegular.arrowsClockwise,
                                onPressed: () {
                                  context.read<IngredientBloc>().add(const LoadIngredients());
                                  context.read<CategoryBloc>().add(LoadCategories());
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return const Center(child: Text('Ошибка загрузки склада'));
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
