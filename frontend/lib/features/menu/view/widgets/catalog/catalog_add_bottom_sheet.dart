import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'catalog_dialogs.dart';

class CatalogAddBottomSheet {
  static void show(BuildContext context, {required int? currentCategoryId}) {
    String parentType = 'dish';
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded && currentCategoryId != null) {
      final parentCat = catState.categories.where((c) => c.id == currentCategoryId).firstOrNull;
      if (parentCat != null) parentType = parentCat.categoryType;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PhosphorIconsRegular.squaresFour),
                title: const Text('Создать подкатегорию'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: parentType);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.hamburger),
                title: const Text('Добавить блюдо'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddMenuItemDialog(context, currentCategoryId: currentCategoryId);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.storefront),
                title: const Text('Добавить товар (витрина)'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddRetailProductDialog(context, currentCategoryId: currentCategoryId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
