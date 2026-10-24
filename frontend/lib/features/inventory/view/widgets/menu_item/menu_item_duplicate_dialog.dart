// ==============================================================================
// МОДУЛЬ: Склад и Меню / Предупреждение о дубликате блюда
// ДОМЕН: lib/features/inventory/view/widgets/menu_item/menu_item_duplicate_dialog.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Poka-Yoke модальное окно при обнаружении дубликата блюда:
// 1. Блокирует создание 100% дубликата в одной категории.
// 2. Предлагает открыть существующую карточку блюда для редактирования.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/create_menu_item_dialog.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';

class MenuItemDuplicateDialog {
  const MenuItemDuplicateDialog._();

  static void show({
    required BuildContext context,
    required MenuItem existingItem,
    required int? currentCategoryId,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'Блюдо уже существует',
        icon: PhosphorIconsRegular.warningCircle,
        width: 440,
        content: Text(
          'В этой категории уже есть активное блюдо «${existingItem.cleanName}».\n\nОткрыть существующую карточку для редактирования?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          const SizedBox(width: 8),
          AppPrimaryButton(
            label: 'Открыть карточку',
            icon: PhosphorIconsRegular.arrowSquareOut,
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              showAddMenuItemDialog(
                context,
                currentCategoryId: currentCategoryId,
                itemToEdit: existingItem,
              );
            },
          ),
        ],
      ),
    );
  }
}
