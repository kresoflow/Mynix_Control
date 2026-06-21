import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_event.dart';

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
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MenuLoaded) {
          if (state.items.isEmpty) {
            return const Center(child: Text('Нет блюд в меню'));
          }
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: state.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  final isSelected = selectedMenuItemId == item.id;
                  return Material(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      title: Text(item.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      onTap: () {
                        onMenuItemSelected(item.id);
                        context.read<RecipeBloc>().add(LoadRecipe(item.id));
                      },
                    ),
                  );
                },
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
