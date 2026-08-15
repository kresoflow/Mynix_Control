import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_model.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class BulkReceiptRowWidget extends StatelessWidget {
  final ReceiptRowModel row;
  final int index;
  final bool isLast;
  final List<Ingredient> ingredients;
  final VoidCallback onRemove;
  final VoidCallback onAddRow;
  final Function(int) onFocusNextSearch;

  const BulkReceiptRowWidget({
    super.key,
    required this.row,
    required this.index,
    required this.isLast,
    required this.ingredients,
    required this.onRemove,
    required this.onAddRow,
    required this.onFocusNextSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    InputDecoration cellDecoration({String? hintText, String? suffixText, Widget? prefixIcon}) {
      return InputDecoration(
        hintText: hintText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        hintStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        filled: true,
        fillColor: bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 42,
              child: Autocomplete<Ingredient>(
                displayStringForOption: (Ingredient option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Ingredient>.empty();
                  }
                  return ingredients.where((Ingredient option) {
                    return option.name.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (Ingredient selection) {
                  row.ingredient = selection;
                  if (row.costController.text.isEmpty) {
                    row.costController.text = selection.costPerUnit.toString();
                  }
                  row.qtyFocus.requestFocus();
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  row.searchFocus = fieldFocusNode;
                  if (row.ingredient != null &&
                      fieldTextEditingController.text.isEmpty) {
                    fieldTextEditingController.text = row.ingredient!.name;
                  }
                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    decoration: cellDecoration(
                      hintText: 'Поиск товара...',
                      prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
                    ),
                    onSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: row.qtyController,
                focusNode: row.qtyFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                onSubmitted: (_) {
                  row.costFocus.requestFocus();
                },
                decoration: cellDecoration(
                  suffixText: row.ingredient?.unit ?? '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: row.costController,
                focusNode: row.costFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                onSubmitted: (_) {
                  if (isLast) {
                    onAddRow();
                  } else {
                    onFocusNextSearch(index + 1);
                  }
                },
                decoration: cellDecoration(
                  suffixText: 'c',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(PhosphorIconsRegular.trash, color: AppColors.danger, size: 20),
            hoverColor: AppColors.danger.withValues(alpha: 0.1),
            onPressed: onRemove,
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }
}
