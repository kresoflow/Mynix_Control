import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:retail_os_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:retail_os_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';
import 'package:retail_os_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:retail_os_frontend/core/utils/icon_helper.dart';

class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> {
  int? _selectedCategoryId;
  bool _isManageMode = false;
  Set<int> _selectedIngredients = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                const Text('Управление сырьем', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
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
                          _selectedIngredients = filteredIngredients.map((i) => i.id).toSet();
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
          Expanded(
            child: BlocBuilder<IngredientBloc, IngredientState>(
              builder: (context, state) {
                if (state is IngredientLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is IngredientLoaded) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar for categories
                      Container(
                        width: 250,
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
                        ),
                        child: BlocBuilder<CategoryBloc, CategoryState>(
                          builder: (context, catState) {
                            if (catState is CategoryLoading) return const Center(child: CircularProgressIndicator());
                            if (catState is CategoryLoaded) {
                              final ingredientCategories = catState.categories.where((c) => c.categoryType == 'ingredient').toList();
                              return ListView(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                children: [
                                  ListTile(
                                    title: const Text('Все сырье', style: TextStyle(fontWeight: FontWeight.bold)),
                                    selected: _selectedCategoryId == null,
                                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                                    onTap: () => setState(() => _selectedCategoryId = null),
                                  ),
                                  const Divider(),
                                  ...ingredientCategories.map((cat) => ListTile(
                                    leading: IconHelper.buildIcon(
                                      cat.icon, 
                                      size: 24, 
                                      color: _selectedCategoryId == cat.id ? Theme.of(context).colorScheme.primary : Colors.grey
                                    ),
                                    title: Text(cat.name),
                                    selected: _selectedCategoryId == cat.id,
                                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18, color: Colors.grey),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          showAddCategoryDialog(context, itemToEdit: cat);
                                        } else if (val == 'delete') {
                                          context.read<CategoryBloc>().add(DeleteCategory(cat.id, mode: 'all'));
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                        const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  )),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      // Main Content
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final rawIngredients = state.ingredients.where((i) => !i.isRetail).toList();
                            final filteredIngredients = _selectedCategoryId == null
                                ? rawIngredients
                                : rawIngredients.where((i) => i.categoryId == _selectedCategoryId).toList();
                            final currency = context.watch<SettingsBloc>().state.currency;
                            final catState = context.watch<CategoryBloc>().state;
                                
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
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredIngredients.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = filteredIngredients[index];
                                      final isLowStock = item.isLowStock;
                                      return Material(
                                        color: _selectedIngredients.contains(item.id) 
                                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) 
                                            : Colors.transparent,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          leading: _isManageMode
                                            ? Checkbox(
                                                value: _selectedIngredients.contains(item.id),
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) _selectedIngredients.add(item.id);
                                                    else _selectedIngredients.remove(item.id);
                                                  });
                                                },
                                              )
                                            : () {
                                                final cat = catState is CategoryLoaded ? catState.categories.where((c) => c.id == item.categoryId).firstOrNull : null;
                                                return IconHelper.buildIcon(cat?.icon, color: isLowStock ? Colors.red : Colors.grey);
                                              }(),
                                          title: Text(item.name, style: const TextStyle(fontSize: 16)),
                                          subtitle: Text('Остаток: ${item.currentStock.toInt()} ${item.unit} | Алерт: ${item.minStockAlert.toInt()} ${item.unit}'),
                                          trailing: _isManageMode ? null : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${item.costPerUnit.toInt()} $currency / ${item.unit}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                                                onSelected: (val) {
                                                  if (val == 'edit') {
                                                    showAddIngredientDialog(context, itemToEdit: item);
                                                  } else if (val == 'delete') {
                                                    context.read<IngredientBloc>().add(DeleteIngredient(item.id));
                                                  }
                                                },
                                                itemBuilder: (ctx) => [
                                                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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
        ],
      ),
    );
  }
}
