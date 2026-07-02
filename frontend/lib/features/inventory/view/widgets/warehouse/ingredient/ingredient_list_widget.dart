import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/create_ingredient_dialog.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';

class IngredientListWidget extends StatelessWidget {
  final List<Ingredient> filteredIngredients;
  final CategoryState catState;
  final int? selectedCategoryId;
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final String currency;
  final ValueChanged<Set<int>> onSelectedIngredientsChanged;

  const IngredientListWidget({
    super.key,
    required this.filteredIngredients,
    required this.catState,
    required this.selectedCategoryId,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.currency,
    required this.onSelectedIngredientsChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredIngredients.isEmpty) {
      return const Center(child: Text('В этой категории пусто'));
    }
    
    final grouped = <String, List<Ingredient>>{};
    if (selectedCategoryId == null) {
      for (var item in filteredIngredients) {
        final cat = catState is CategoryLoaded 
          ? (catState as CategoryLoaded).categories.where((c) => c.id == item.categoryId).firstOrNull?.name ?? 'Без категории'
          : 'Без категории';
        grouped.putIfAbsent(cat, () => []).add(item);
      }
    } else {
      grouped[''] = filteredIngredients;
    }
    
    final sortedKeys = grouped.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView(
            padding: EdgeInsets.zero,
            children: sortedKeys.map((catName) {
              final items = grouped[catName]!;
              final widgets = items.map((item) {
                final isLowStock = item.isLowStock;
                return Column(
                  children: [
                    if (catName.isNotEmpty) const Divider(height: 1),
                    Material(
                      color: selectedIngredients.contains(item.id) 
                          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) 
                          : Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: isManageMode
                          ? Checkbox(
                              value: selectedIngredients.contains(item.id),
                              onChanged: (val) {
                                final newSelected = Set<int>.from(selectedIngredients);
                                if (val == true) {
                                  newSelected.add(item.id);
                                } else {
                                  newSelected.remove(item.id);
                                }
                                onSelectedIngredientsChanged(newSelected);
                              },
                            )
                          : () {
                              final cat = catState is CategoryLoaded ? (catState as CategoryLoaded).categories.where((c) => c.id == item.categoryId).firstOrNull : null;
                              return IconHelper.buildIcon(cat?.icon, color: isLowStock ? Colors.red : Colors.grey);
                            }(),
                        title: Text(item.name, style: const TextStyle(fontSize: 16)),
                        subtitle: Text('Остаток: ${item.currentStock.toInt()} ${item.unit} | Алерт: ${item.minStockAlert.toInt()} ${item.unit}'),
                        trailing: isManageMode ? null : Row(
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
                    ),
                  ],
                );
              }).toList();
              
              if (catName.isEmpty) {
                return Column(children: widgets);
              }

              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey('ing_cat_$catName'),
                  initiallyExpanded: false,
                  title: Text(
                    catName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  children: widgets,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
