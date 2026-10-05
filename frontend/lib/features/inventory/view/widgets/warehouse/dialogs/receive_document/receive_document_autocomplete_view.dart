// ==============================================================================
// МОДУЛЬ: Склад / Автокомплит номенклатуры приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receipt_row_data.dart';
import 'receive_document_row_callbacks.dart';

/// Поле автокомплита поиска номенклатуры в строке приходной накладной.
class ReceiveDocumentAutocompleteField extends StatelessWidget {
  final ReceiptRowData item;
  final int index;
  final List<ReceiptRowData> items;
  final List<Ingredient> availableIngredients;
  final int tabIndex;
  final bool isDark;
  final ValueChanged<Ingredient> onIngredientSelected;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNameSubmitted;

  const ReceiveDocumentAutocompleteField({
    super.key,
    required this.item,
    required this.index,
    required this.items,
    required this.availableIngredients,
    required this.tabIndex,
    required this.isDark,
    required this.onIngredientSelected,
    required this.onNameChanged,
    required this.onNameSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: tabIndex == 2 ? 5 : 3,
      child: SizedBox(
        height: 40,
        child: Focus(
          onKeyEvent: (_, event) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
            event: event,
            items: items,
            index: index,
            targetNode: (r) => r.nameFocusNode,
          ),
          child: RawAutocomplete<Ingredient>(
            textEditingController: item.nameController,
            focusNode: item.nameFocusNode,
            displayStringForOption: (option) => option.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Ingredient>.empty();
              }
              return availableIngredients.where((option) {
                if (option.isArchived) return false;
                final matchesText = option.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
                if (!matchesText) return false;
                final isOptionRetail = option.attributes?['is_retail'] == true;
                if (tabIndex == 1) return isOptionRetail;
                if (tabIndex == 2) return !isOptionRetail;
                return true;
              });
            },
            onSelected: onIngredientSelected,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: buildBulkInputDecoration(
                  context,
                  'Поиск номенклатуры...',
                  isHintOnly: true,
                  suffixIcon: item.ingredient != null
                      ? const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success, size: 16)
                      : Icon(PhosphorIconsRegular.magnifyingGlass, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 16),
                ),
                onChanged: onNameChanged,
                onFieldSubmitted: (_) => onNameSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return ReceiveDocumentAutocompleteOptionsView(
                options: options,
                onSelected: onSelected,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Выпадающее меню с результатами поиска для автокомплита.
class ReceiveDocumentAutocompleteOptionsView extends StatelessWidget {
  final Iterable<Ingredient> options;
  final AutocompleteOnSelected<Ingredient> onSelected;

  const ReceiveDocumentAutocompleteOptionsView({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, optIndex) {
              final option = options.elementAt(optIndex);
              return ListTile(
                dense: true,
                title: Text(
                  option.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${UnitFormatter.format(option.unit)} • ${option.costPerUnit} TJS',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    fontSize: 11,
                  ),
                ),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }
}
