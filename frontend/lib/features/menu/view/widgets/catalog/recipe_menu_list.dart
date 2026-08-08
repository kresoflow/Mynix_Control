import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecipeMenuList extends StatefulWidget {
  final int? selectedMenuItemId;
  final ValueChanged<int> onMenuItemSelected;

  const RecipeMenuList({
    super.key,
    required this.selectedMenuItemId,
    required this.onMenuItemSelected,
  });

  @override
  State<RecipeMenuList> createState() => _RecipeMenuListState();
}

class _RecipeMenuListState extends State<RecipeMenuList> {
  final Map<String, bool> _expandedCategories = {};

  void _toggleCategory(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }

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

              // Создаем плоский список
              final List<dynamic> flatList = [];
              groupedItems.forEach((catName, items) {
                final isExpanded = _expandedCategories[catName] ?? false;
                flatList.add({
                  'type': 'header',
                  'categoryName': catName,
                  'isExpanded': isExpanded,
                });
                if (isExpanded) {
                  flatList.addAll(items.map((item) => {'type': 'item', 'item': item}));
                }
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
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: flatList.length,
                          itemBuilder: (context, index) {
                            final data = flatList[index];
                            if (data['type'] == 'header') {
                              final catName = data['categoryName'] as String;
                              final isExpanded = data['isExpanded'] as bool;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleCategory(catName),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            catName.toUpperCase(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                          ),
                                        ),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: const Icon(PhosphorIconsRegular.caretDown, color: Colors.grey, size: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final item = data['item'];
                              final isSelected = widget.selectedMenuItemId == item.id;
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
                                    widget.onMenuItemSelected(item.id);
                                    context.read<RecipeBloc>().add(LoadRecipe(item.id));
                                  },
                                ),
                              );
                            }
                          },
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
