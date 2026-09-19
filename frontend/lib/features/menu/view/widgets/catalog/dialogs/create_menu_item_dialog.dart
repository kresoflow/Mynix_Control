import 'package:flutter/material.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/menu_item_modal.dart';

void showAddMenuItemDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  showDialog(
    context: context,
    builder: (ctx) => MenuItemModal(
      preselectedCategoryId: currentCategoryId,
      existingItem: itemToEdit,
    ),
  );
}
