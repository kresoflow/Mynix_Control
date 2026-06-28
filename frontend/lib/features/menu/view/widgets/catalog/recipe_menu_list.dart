import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:retail_os_frontend/core/utils/icon_helper.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecipeMenuList extends StatelessWidget {
  final int? selectedMenuItemId;
  final ValueChanged<int> onMenuItemSelected;

  const RecipeMenuList({
    super.key,
    required this.selectedMenuItemId,
    required this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        return BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            if (state is MenuLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MenuLoaded) {
              final filteredItems = state.items.where((i) => !i.isRetail).toList();
              if (filteredItems.isEmpty) {
                return const Center(child: Text('Нет доступных блюд для техкарт'));
              }

              final Map<String, List<dynamic>> groupedItems = {};
              for (var item in filteredItems) {
                String catName = item.categoryName ?? 'Без категории';
                if ((item.categoryName == null || item.categoryName!.isEmpty) && catState is CategoryLoaded) {
                  final cat = catState.categories.where((c) => c.id.toString() == item.categoryId).firstOrNull;
                  if (cat != null) {
                    catName = cat.name;
                  }
                }
                groupedItems.putIfAbsent(catName, () => []).add(item);
              }

              final List<Widget> listWidgets = [];
              groupedItems.forEach((catName, items) {
                listWidgets.add(
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey('recipe_cat_$catName'),
                      initiallyExpanded: false,
                      title: Text(
                        catName.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      children: items.map<Widget>((item) {
                        final isSelected = selectedMenuItemId == item.id;
                        return Material(
                          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: IconHelper.buildIcon(
                              item.icon,
                              size: 24,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                            title: Text(item.cleanName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            onTap: () {
                              onMenuItemSelected(item.id);
                              context.read<RecipeBloc>().add(LoadRecipe(item.id));
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              });

              return Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: listWidgets,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
