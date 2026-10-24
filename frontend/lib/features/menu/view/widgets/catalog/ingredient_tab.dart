// ==============================================================================
// Title: IngredientTab
// Path: frontend/lib/features/menu/view/widgets/catalog/ingredient_tab.dart
// Description: Вкладка каталога сырья и заготовок (таблица / сетка / архив).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_grid_view.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_header_bar.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_kpi_cards.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart';

class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int? _selectedCategoryId;
  bool _isManageMode = false;
  bool _isGridView = false;
  bool _showArchived = false;
  final Set<int> _selectedIngredients = {};
  String _searchQuery = '';

  void _toggleSelectAll(IngredientLoaded state) {
    final raw = state.ingredients
        .where((i) => !i.isRetail && (_showArchived ? i.isArchived : !i.isArchived))
        .toList();
    final filtered = _selectedCategoryId == null
        ? raw
        : raw.where((i) => i.categoryId == _selectedCategoryId).toList();
    final isAll = filtered.isNotEmpty && _selectedIngredients.length == filtered.length;
    setState(() {
      if (isAll) {
        _selectedIngredients.clear();
      } else {
        _selectedIngredients.addAll(filtered.map((i) => i.id));
      }
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
    super.build(context);
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
          // ── Clean Header Row matching Design System ─────────────────
          IngredientHeaderBar(
            isManageMode: _isManageMode,
            isGridView: _isGridView,
            showArchived: _showArchived,
            archivedCount: archivedCount,
            selectedIngredients: _selectedIngredients,
            selectedCategoryId: _selectedCategoryId,
            onSelectAll: () {
              if (ingState is IngredientLoaded) _toggleSelectAll(ingState);
            },
            onConfirmRestore: _confirmRestoreSelected,
            onConfirmDelete: _confirmDeleteSelected,
            onCancelManageMode: () => setState(() {
              _isManageMode = false;
              _selectedIngredients.clear();
            }),
            onToggleGridView: (val) => setState(() => _isGridView = val),
            onToggleShowArchived: () => setState(() {
              _showArchived = !_showArchived;
              _selectedIngredients.clear();
            }),
            onEnterManageMode: () => setState(() => _isManageMode = true),
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
                                      // 3 KPI Cards Row
                                      IngredientKpiCards(ingredients: state.ingredients),
                                      const SizedBox(height: 14),

                                      // Archive Mode Information Banner
                                      if (_showArchived)
                                        IngredientArchiveBanner(
                                          archivedCount: archivedCount,
                                          onClose: () => setState(() {
                                            _showArchived = false;
                                            _selectedIngredients.clear();
                                          }),
                                        ),

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
