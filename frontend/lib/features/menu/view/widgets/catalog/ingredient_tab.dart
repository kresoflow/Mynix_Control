import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:retail_os_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';

class IngredientTab extends StatelessWidget {
  const IngredientTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<IngredientBloc, IngredientState>(
        builder: (context, state) {
          if (state is IngredientLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is IngredientLoaded) {
            if (state.ingredients.isEmpty) {
              return const Center(child: Text('ÐÐµÑ‚ Ð¸Ð½Ð³Ñ€ÐµÐ´Ð¸ÐµÐ½Ñ‚Ð¾Ð² Ð½Ð° ÑÐºÐ»Ð°Ð´Ðµ'));
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
                    itemCount: state.ingredients.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = state.ingredients[index];
                      final isLowStock = item.isLowStock;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Icon(
                            Icons.kitchen,
                            color: isLowStock ? Colors.red : Colors.grey,
                          ),
                          title: Text(item.name, style: const TextStyle(fontSize: 16)),
                          subtitle: Text('ÐÐ»ÐµÑ€Ñ‚: ${item.minStockAlert} ${item.unit}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.costPerUnit.toInt()} Ñ / ${item.unit}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    showAddIngredientDialog(context, itemToEdit: item);
                                  } else if (val == 'delete') {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ð£Ð´Ð°Ð»ÐµÐ½Ð¸Ðµ ÑÑ‹Ñ€ÑŒÑ Ð² Ñ€Ð°Ð·Ñ€Ð°Ð±Ð¾Ñ‚ÐºÐµ')));
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Ð ÐµÐ´Ð°ÐºÑ‚Ð¸Ñ€Ð¾Ð²Ð°Ñ‚ÑŒ')),
                                  const PopupMenuItem(value: 'delete', child: Text('Ð£Ð´Ð°Ð»Ð¸Ñ‚ÑŒ', style: TextStyle(color: Colors.red))),
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
          return const Center(child: Text('ÐžÑˆÐ¸Ð±ÐºÐ° Ð·Ð°Ð³Ñ€ÑƒÐ·ÐºÐ¸ ÑÐºÐ»Ð°Ð´Ð°'));
        },
      ),
    );
  }
}



