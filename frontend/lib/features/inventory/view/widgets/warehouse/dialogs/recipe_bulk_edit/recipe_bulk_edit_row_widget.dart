import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'recipe_row_state.dart';
import 'recipe_ingredient_picker.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class RecipeBulkEditRowWidget extends StatefulWidget {
  final RecipeRowState row;
  final int index;
  final List<dynamic> availableIngredients;
  final VoidCallback onAddRow;
  final VoidCallback onDuplicateRow;
  final VoidCallback onRemoveRow;

  const RecipeBulkEditRowWidget({
    super.key,
    required this.row,
    required this.index,
    required this.availableIngredients,
    required this.onAddRow,
    required this.onDuplicateRow,
    required this.onRemoveRow,
  });

  @override
  State<RecipeBulkEditRowWidget> createState() => _RecipeBulkEditRowWidgetState();
}

class _RecipeBulkEditRowWidgetState extends State<RecipeBulkEditRowWidget> {
  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final selectedIngredient = widget.availableIngredients.where((i) => i.id == row.ingredientId).firstOrNull;
    final unit = selectedIngredient?.unit ?? '';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            focusNode: row.ingredientFocusNode,
            onTap: () async {
              final selected = await showRecipeIngredientPicker(context, widget.availableIngredients);
              if (selected != null) {
                setState(() {
                  row.ingredientId = selected;
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      row.ingredientId != null 
                        ? (selectedIngredient?.name ?? 'Неизвестно')
                        : 'Выберите сырье...',
                      style: TextStyle(color: row.ingredientId != null ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(PhosphorIconsRegular.caretDown, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: row.quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onAddRow(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: '0.0',
              suffixText: unit.isNotEmpty ? unit : null,
              suffixStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(PhosphorIconsRegular.copy, color: AppColors.info),
              onPressed: widget.onDuplicateRow,
              tooltip: 'Дублировать',
            ),
            IconButton(
              icon: Icon(PhosphorIconsRegular.trash, color: AppColors.danger),
              onPressed: widget.onRemoveRow,
              tooltip: 'Удалить',
            ),
          ],
        ),
      ],
    );
  }
}
