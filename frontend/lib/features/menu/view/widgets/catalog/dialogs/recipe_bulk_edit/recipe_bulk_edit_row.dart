import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'recipe_row_state.dart';

class RecipeBulkEditRow extends StatelessWidget {
  final RecipeRowState row;
  final int index;
  final dynamic selectedIngredient;
  final VoidCallback onPickIngredient;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onAddNext;

  const RecipeBulkEditRow({
    super.key,
    required this.row,
    required this.index,
    required this.selectedIngredient,
    required this.onPickIngredient,
    required this.onDuplicate,
    required this.onRemove,
    required this.onAddNext,
  });

  @override
  Widget build(BuildContext context) {
    final unit = selectedIngredient?.unit ?? '';

    return Row(
      children: [
        // Ingredient Selector Button with Keyboard Enter/Space/ArrowDown support
        Expanded(
          flex: 3,
          child: Focus(
            focusNode: row.ingredientFocusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                   event.logicalKey == LogicalKeyboardKey.space ||
                   event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                onPickIngredient();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: InkWell(
              onTap: onPickIngredient,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: row.ingredientFocusNode.hasFocus
                        ? AppColors.brandPrimary
                        : Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (selectedIngredient != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selectedIngredient.displayCode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              selectedIngredient != null
                                  ? selectedIngredient.name
                                  : 'Выберите сырье...',
                              style: TextStyle(
                                color: selectedIngredient != null
                                    ? Theme.of(context).textTheme.bodyLarge?.color
                                    : Colors.grey,
                                fontWeight: selectedIngredient != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.caretDown, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Quantity Field with Tab / Enter to add or move next
        Expanded(
          flex: 1,
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.tab &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                onAddNext();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextFormField(
              controller: row.quantityController,
              focusNode: row.quantityFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: unit,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onFieldSubmitted: (_) => onAddNext(),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Duplicate Button
        IconButton(
          icon: const Icon(PhosphorIconsRegular.copy, color: Colors.grey),
          tooltip: 'Дублировать',
          onPressed: onDuplicate,
        ),

        // Delete Button
        IconButton(
          icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
          tooltip: 'Удалить',
          onPressed: onRemove,
        ),
      ],
    );
  }
}
