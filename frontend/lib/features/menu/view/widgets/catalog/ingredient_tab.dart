import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_kpi_cards.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_grid_view.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';

class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> {
  int? _selectedCategoryId;
  bool _isManageMode = false;
  bool _isGridView = false;
  final Set<int> _selectedIngredients = {};
  String _searchQuery = '';

  void _selectAll(IngredientLoaded state) {
    final raw = state.ingredients.where((i) => !i.isRetail).toList();
    final filtered = _selectedCategoryId == null
        ? raw
        : raw.where((i) => i.categoryId == _selectedCategoryId).toList();
    setState(() {
      _selectedIngredients.addAll(filtered.map((i) => i.id));
    });
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Массовое удаление',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Удалить выбранные элементы (${_selectedIngredients.length} шт.) со склада?\nЕсли позиции используются в техкартах, удаление будет отклонено.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(ctx),
          ),
          AppDangerButton(
            label: 'Удалить',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              for (var itemId in _selectedIngredients) {
                context.read<IngredientBloc>().add(DeleteIngredient(itemId));
              }
              setState(() {
                _selectedIngredients.clear();
                _isManageMode = false;
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ingState = context.watch<IngredientBloc>().state;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Clean Header Row matching RecipeTab ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сырье и заготовки',
                style: AppTextStyles.h2,
              ),
              Row(
                children: [
                  if (_isManageMode) ...[
                    AppGhostButton(
                      label: 'Выбрать все',
                      icon: PhosphorIconsRegular.checkSquareOffset,
                      height: 36,
                      onPressed: () {
                        if (ingState is IngredientLoaded) _selectAll(ingState);
                      },
                    ),
                    const SizedBox(width: 8),
                    AppDangerButton(
                      label: 'Удалить (${_selectedIngredients.length})',
                      icon: PhosphorIconsRegular.trash,
                      height: 36,
                      onPressed: _selectedIngredients.isEmpty ? null : _confirmDeleteSelected,
                    ),
                    const SizedBox(width: 8),
                    AppGhostButton(
                      label: 'Отмена',
                      height: 36,
                      onPressed: () => setState(() {
                        _isManageMode = false;
                        _selectedIngredients.clear();
                      }),
                    ),
                  ] else ...[
                    // View Switcher (Grid / List)
                    Container(
                      height: 36,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildViewBtn(
                            isActive: !_isGridView,
                            icon: PhosphorIconsRegular.list,
                            tooltip: 'Список',
                            onTap: () => setState(() => _isGridView = false),
                            isDark: isDark,
                          ),
                          _buildViewBtn(
                            isActive: _isGridView,
                            icon: PhosphorIconsRegular.squaresFour,
                            tooltip: 'Сетка',
                            onTap: () => setState(() => _isGridView = true),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions Menu (...)
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.dotsThreeVertical,
                          size: 18,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      tooltip: 'Действия',
                      onSelected: (val) {
                        if (val == 'bulk') {
                          showDialog(
                            context: context,
                            builder: (_) => const BulkAddModal(initialTabIndex: 2),
                          );
                        } else if (val == 'manage') {
                          setState(() => _isManageMode = true);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'bulk',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.listPlus, size: 16),
                              SizedBox(width: 10),
                              Text('Массовое добавление'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'manage',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                              SizedBox(width: 10),
                              Text('Режим управления'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Main CTA Button
                    AppPrimaryButton(
                      label: 'Добавить',
                      icon: PhosphorIconsRegular.plus,
                      height: 36,
                      onPressed: () {
                        showAddIngredientDialog(context, initialCategoryId: _selectedCategoryId);
                      },
                    ),
                  ],
                ],
              ),
            ],
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
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase().trim();
                          return i.name.toLowerCase().contains(q) ||
                                 '#${i.id}'.contains(q) ||
                                 '${i.id}' == q ||
                                 (i.barcode != null && i.barcode!.toLowerCase().contains(q));
                        }).toList();

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Left Sidebar (270px) ──────────────────
                            IngredientCategorySidebar(
                              selectedCategoryId: _selectedCategoryId,
                              isManageMode: _isManageMode,
                              onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                              onSearchChanged: (q) => setState(() => _searchQuery = q),
                            ),
                            const SizedBox(width: 16),

                            // ── Right Workspace (Expanded) ────────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 3 KPI Cards Row (matching Recipe Tab)
                                  IngredientKpiCards(ingredients: state.ingredients),
                                  const SizedBox(height: 14),

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

  Widget _buildViewBtn({
    required bool isActive,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }
}
