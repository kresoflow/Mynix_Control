import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';

class BulkAddCategorySelector extends StatelessWidget {
  final int tabIndex;
  final int? selectedParentId;
  final int? selectedChildId;
  final Function(int?) onParentChanged;
  final Function(int?) onChildChanged;

  const BulkAddCategorySelector({
    super.key,
    required this.tabIndex,
    required this.selectedParentId,
    required this.selectedChildId,
    required this.onParentChanged,
    required this.onChildChanged,
  });

  void _showCreateCategoryDialog(
    BuildContext context,
    String type,
    int? parentId,
    String? parentName,
  ) {
    final nameCtrl = TextEditingController();
    bool asSubcategory = parentId != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Новая категория'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  if (parentId != null) ...[
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text('Создать внутри «$parentName»'),
                      value: asSubcategory,
                      onChanged: (val) {
                        setStateDialog(() {
                          asSubcategory = val ?? false;
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      context.read<CategoryBloc>().add(
                        CreateCategory(
                          name: nameCtrl.text.trim(),
                          categoryType: type,
                          parentId: asSubcategory ? parentId : null,
                        ),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Категория добавляется...'),
                        ),
                      );
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tabIndex != 0 && tabIndex != 1 && tabIndex != 2) return const SizedBox.shrink();

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        if (catState is CategoryLoaded) {
          final allowedType = tabIndex == 0 ? 'dish' : (tabIndex == 1 ? 'retail' : 'ingredient');
          final allFiltered = catState.categories
              .where((c) => c.categoryType == allowedType)
              .toList();
          final parents = allFiltered.where((c) => c.parentId == null).toList();
          final allChildren = allFiltered
              .where((c) => c.parentId != null)
              .toList();

          final children = selectedParentId != null
              ? allFiltered
                    .where((c) => c.parentId == selectedParentId)
                    .toList()
              : allChildren;

          final bool parentExists = parents.any((c) => c.id == selectedParentId);
          final int? safeParentId = parentExists ? selectedParentId : null;
          
          final bool childExists = children.any((c) => c.id == selectedChildId);
          final int? safeChildId = childExists ? selectedChildId : null;

          if (selectedChildId != safeChildId) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onChildChanged(safeChildId));
          }
          if (selectedParentId != safeParentId) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onParentChanged(safeParentId));
          }

          String? parentName = parents
              .where((c) => c.id == safeParentId)
              .firstOrNull
              ?.name;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: safeParentId,
                  decoration: const InputDecoration(
                    labelText: 'Главная категория',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— Все категории —'),
                    ),
                    ...parents.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: onParentChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: safeChildId,
                  decoration: const InputDecoration(
                    labelText: 'Подкатегория',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— Без подкатегории —'),
                    ),
                    ...children.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    onChildChanged(val);
                    if (val != null) {
                      final child = allChildren.firstWhere((c) => c.id == val);
                      if (child.parentId != selectedParentId) {
                        onParentChanged(child.parentId);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: IconButton(
                  icon: const Icon(PhosphorIconsRegular.plusSquare, size: 40, color: Colors.blue),
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    allowedType,
                    safeParentId,
                    parentName,
                  ),
                  tooltip: 'Создать категорию',
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
