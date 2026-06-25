import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';

class MenuManagerItemsGrid extends StatelessWidget {
  final int? currentParentId;
  final Function(int) onDelete;

  const MenuManagerItemsGrid({
    super.key,
    required this.currentParentId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (currentParentId == null) {
      return const Center(
        child: Text(
          'Выберите папку, чтобы просмотреть товары',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MenuLoaded) {
          final items = state.items
              .where((item) => item.categoryId == currentParentId.toString())
              .toList();

          if (items.isEmpty) {
            return const Center(
              child: Text('Нет товаров в этой категории. Создайте новый!'),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      PhosphorIconsRegular.hamburger,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.cleanName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.attributesString != null
                        ? '${item.attributesString}\n${item.price} с'
                        : '${item.price} с',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red, size: 20),
                    onPressed: () => onDelete(item.id),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
