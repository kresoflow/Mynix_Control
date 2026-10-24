// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Валидация дубликатов ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/create_retail_duplicate_helper.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'create_retail_product_dialog.dart';

/// Вспомогательный класс детекции и предотвращения дубликатов ритейла
class CreateRetailDuplicateHelper {
  static void showDuplicateBlockedDialog(
    BuildContext context, {
    required MenuItem existingItem,
    required int? selectedCategoryId,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'Товар уже существует',
        icon: PhosphorIconsRegular.warningCircle,
        width: 440,
        content: Text(
          'В этой категории уже есть активный товар «${existingItem.cleanName}» с таким же вкусом и объемом.\n\nОткрыть существующую карточку для редактирования?',
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
              showAddRetailProductDialog(
                context,
                currentCategoryId: selectedCategoryId,
                itemToEdit: existingItem,
              );
            },
          ),
        ],
      ),
    );
  }

  static DuplicateMatch<MenuItem>? detectDuplicate({
    required List<MenuItem> items,
    required String name,
    required String? flavor,
    required String? barcode,
    required String? rawVolume,
    required List<Map<String, dynamic>> variations,
    required int? categoryId,
    int? excludeItemId,
  }) {
    if (variations.isNotEmpty) {
      final seenVolumes = <String>{};
      final seenBarcodes = <String>{};
      for (final v in variations) {
        final rawVName = v['name']?.toString().trim() ?? '';
        final vBc = v['barcode']?.toString().trim();
        final normV = DuplicateDetector.normalizeVolume(rawVName);

        if (normV.isNotEmpty) {
          if (seenVolumes.contains(normV)) {
            return DuplicateMatch(
              item: MenuItem(id: -1, name: name, price: 0, categoryId: categoryId?.toString() ?? ''),
              matchReason: 'Дубликат объема «$rawVName» внутри серии',
              isSameCategory: true,
            );
          }
          seenVolumes.add(normV);
        }
        if (vBc != null && vBc.isNotEmpty) {
          if (seenBarcodes.contains(vBc)) {
            return DuplicateMatch(
              item: MenuItem(id: -1, name: name, price: 0, categoryId: categoryId?.toString() ?? ''),
              matchReason: 'Дубликат штрихкода «$vBc» внутри серии',
              isSameCategory: true,
            );
          }
          seenBarcodes.add(vBc);
        }

        final match = DuplicateDetector.findMenuItemDuplicate(
          items: items,
          queryName: name,
          isRetail: true,
          queryFlavor: flavor,
          queryVolume: rawVName.isNotEmpty ? rawVName : null,
          queryBarcode: vBc,
          currentCategoryId: categoryId,
          excludeItemId: excludeItemId,
        );
        if (match != null) return match;
      }
      return null;
    }

    return DuplicateDetector.findMenuItemDuplicate(
      items: items,
      queryName: name,
      isRetail: true,
      queryFlavor: flavor,
      queryVolume: rawVolume,
      queryBarcode: barcode,
      currentCategoryId: categoryId,
      excludeItemId: excludeItemId,
    );
  }
}
