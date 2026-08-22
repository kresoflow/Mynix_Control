import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_header_bar.dart';
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
    final ingState = context.watch<IngredientBloc>().state;
    final allIngredients = ingState is IngredientLoaded ? ingState.ingredients : <dynamic>[];

    return Scaffold(
      body: Column(
        children: [
          // ── Clean Header Bar with 3 KPI indicators in center ───────
          IngredientHeaderBar(
            isManageMode: _isManageMode,
            isGridView: _isGridView,
            ingredients: allIngredients.cast(),
            selectedIngredients: _selectedIngredients,
            selectedCategoryId: _selectedCategoryId,
            onToggleManageMode: () => setState(() => _isManageMode = true),
            onCancelManageMode: () => setState(() {
              _isManageMode = false;
              _selectedIngredients.clear();
            }),
            onToggleView: (val) => setState(() => _isGridView = val),
            onSelectAll: () {
              final state = context.read<IngredientBloc>().state;
              if (state is IngredientLoaded) _selectAll(state);
            },
            onDeleteSelected: _confirmDeleteSelected,
          ),

          // ── Main Content Area ──────────────────────────────────────
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
                            // Left Sidebar: Search + Expand + Category Card
                            IngredientCategorySidebar(
                              selectedCategoryId: _selectedCategoryId,
                              isManageMode: _isManageMode,
                              onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                              onSearchChanged: (q) => setState(() => _searchQuery = q),
                            ),

                            // Right View: Grid or Table View
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
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
}
