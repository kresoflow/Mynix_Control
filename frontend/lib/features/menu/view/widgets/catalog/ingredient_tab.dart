import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_item_row.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> {
  int? _selectedCategoryId;
  bool _isManageMode = false;
  final Set<int> _selectedIngredients = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Text('Управление сырьем', style: AppTextStyles.h3),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // to keep buttons on the right side
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isManageMode) ...[
                          TextButton.icon(
                            onPressed: () {
                              final state = context.read<IngredientBloc>().state;
                              if (state is IngredientLoaded) {
                                final rawIngredients = state.ingredients.where((i) => !i.isRetail).toList();
                                final filteredIngredients = _selectedCategoryId == null
                                    ? rawIngredients
                                    : rawIngredients.where((i) => i.categoryId == _selectedCategoryId).toList();
                                setState(() {
                                  _selectedIngredients.addAll(filteredIngredients.map((i) => i.id));
                                });
                              }
                            },
                            icon: const Icon(PhosphorIconsRegular.checkSquareOffset),
                            label: const Text('Выбрать все'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Массовое удаление'),
                                  content: Text('Удалить выбранные элементы (${_selectedIngredients.length} шт.)?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
                            },
                            icon: const Icon(PhosphorIconsRegular.trash),
                            label: Text('Удалить (${_selectedIngredients.length})'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _isManageMode = false;
                              _selectedIngredients.clear();
                            }),
                            child: const Text('Отмена'),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _isManageMode = true),
                            icon: const Icon(PhosphorIconsRegular.pencilSimple),
                            label: const Text('Управление'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const BulkAddModal(initialTabIndex: 2),
                              );
                            },
                            icon: const Icon(PhosphorIconsRegular.listPlus),
                            label: const Text('Массово'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              showAddIngredientDialog(context, initialCategoryId: _selectedCategoryId);
                            },
                            icon: const Icon(PhosphorIconsRegular.plus),
                            label: const Text('Добавить'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: BlocListener<IngredientBloc, IngredientState>(
              listener: (context, state) {
                if (state is IngredientError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message.replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: BlocBuilder<IngredientBloc, IngredientState>(
                builder: (context, state) {
                if (state is IngredientLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is IngredientLoaded) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar Tree
                      IngredientCategorySidebar(
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                      ),
                      
                      // Ingredient List
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final catState = context.watch<CategoryBloc>().state;
                            List<MenuCategory> allCategories = [];
                            if (catState is CategoryLoaded) {
                              allCategories = catState.categories;
                            }

                            Set<int> getCategoryAndSubcategories(int parentId) {
                              final result = {parentId};
                              var toCheck = [parentId];
                              while (toCheck.isNotEmpty) {
                                final current = toCheck.removeLast();
                                final children = allCategories.where((c) => c.parentId == current).map((c) => c.id).toList();
                                result.addAll(children);
                                toCheck.addAll(children);
                              }
                              return result;
                            }

                            final rawIngredients = state.ingredients.where((i) => !i.isRetail).toList();
                            final filteredIngredients = _selectedCategoryId == null
                                ? rawIngredients
                                : rawIngredients.where((i) {
                                    if (i.categoryId == null) return false;
                                    final validIds = getCategoryAndSubcategories(_selectedCategoryId!);
                                    return validIds.contains(i.categoryId);
                                  }).toList();
                                
                            final currency = context.watch<SettingsBloc>().state.currency;
                                
                            if (filteredIngredients.isEmpty) {
                              return const Center(child: Text('В этой категории пусто'));
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredIngredients.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredIngredients[index];
                                      
                                      String? iconStr;
                                      if (catState is CategoryLoaded) {
                                        final cat = catState.categories.where((c) => c.id == item.categoryId).firstOrNull;
                                        iconStr = cat?.getInheritedIcon(catState.categories);
                                      }

                                      return IngredientItemRow(
                                        item: item,
                                        categoryIcon: iconStr,
                                        currency: currency,
                                        isManageMode: _isManageMode,
                                        isSelected: _selectedIngredients.contains(item.id),
                                        onSelect: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIngredients.add(item.id);
                                            } else {
                                              _selectedIngredients.remove(item.id);
                                            }
                                          });
                                        },
                                        onEdit: () => showAddIngredientDialog(context, itemToEdit: item),
                                        onDelete: () => context.read<IngredientBloc>().add(DeleteIngredient(item.id)),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  );
                }
                return const Center(child: Text('Ошибка загрузки склада'));
              },
            ),
          ),
          ),
        ],
      ),
    );
  }
}
