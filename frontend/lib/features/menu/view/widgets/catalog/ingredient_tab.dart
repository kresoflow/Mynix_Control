import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_header_bar.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/ingredient/ingredient_quick_setup_card.dart';

class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> {
  int? _selectedCategoryId;
  bool _isManageMode = false;
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
      builder: (ctx) => AlertDialog(
        title: const Text('Массовое удаление'),
        content: Text('Удалить выбранные элементы (${_selectedIngredients.length} шт.)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
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
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          IngredientHeaderBar(
            isManageMode: _isManageMode,
            selectedIngredients: _selectedIngredients,
            selectedCategoryId: _selectedCategoryId,
            onToggleManageMode: () => setState(() => _isManageMode = true),
            onCancelManageMode: () => setState(() {
              _isManageMode = false;
              _selectedIngredients.clear();
            }),
            onSelectAll: () {
              final state = context.read<IngredientBloc>().state;
              if (state is IngredientLoaded) _selectAll(state);
            },
            onDeleteSelected: _confirmDeleteSelected,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
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
                        final hasIngredientCategories = categoryState.categories
                            .any((c) => c.categoryType == 'ingredient' && c.isVisible);

                        if (!hasIngredientCategories) {
                          return IngredientQuickSetupCard(
                            onSetupComplete: () {},
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IngredientCategorySidebar(
                              selectedCategoryId: _selectedCategoryId,
                              onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                            ),
                            Expanded(
                              child: IngredientTableView(
                                ingredients: state.ingredients.where((i) => _searchQuery.isEmpty || i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList(),
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
