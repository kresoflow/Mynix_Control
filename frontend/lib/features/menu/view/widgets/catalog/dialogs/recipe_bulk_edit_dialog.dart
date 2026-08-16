import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

import 'recipe_bulk_edit/recipe_row_state.dart';
import 'recipe_bulk_edit/ingredient_picker_dialog.dart';
import 'recipe_bulk_edit/recipe_bulk_edit_row.dart';

export 'recipe_bulk_edit/recipe_row_state.dart';

class RecipeBulkEditDialog extends StatefulWidget {
  final int menuItemId;
  final List<dynamic> availableIngredients;
  final List<Map<String, dynamic>> currentRecipes;

  const RecipeBulkEditDialog({
    super.key,
    required this.menuItemId,
    required this.availableIngredients,
    required this.currentRecipes,
  });

  @override
  State<RecipeBulkEditDialog> createState() => _RecipeBulkEditDialogState();
}

class _RecipeBulkEditDialogState extends State<RecipeBulkEditDialog> {
  final List<RecipeRowState> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.currentRecipes.isEmpty) {
      _rows.add(RecipeRowState());
    } else {
      for (var recipe in widget.currentRecipes) {
        _rows.add(RecipeRowState(
          ingredientId: recipe['ingredient_id'],
          quantity: (recipe['quantity_required'] as num?)?.toDouble() ?? 0.0,
        ));
      }
    }
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _rows.add(RecipeRowState()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rows.isNotEmpty) {
        _rows.last.ingredientFocusNode.requestFocus();
      }
    });
  }

  void _duplicateRow(int index) {
    setState(() {
      _rows.insert(
        index + 1,
        RecipeRowState(
          ingredientId: _rows[index].ingredientId,
          quantity: double.tryParse(_rows[index].quantityController.text) ?? 0,
        ),
      );
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _save() {
    final List<Map<String, dynamic>> recipesToSave = [];
    for (var row in _rows) {
      if (row.ingredientId != null) {
        final qty = double.tryParse(row.quantityController.text) ?? 0;
        if (qty > 0) {
          recipesToSave.add({
            'ingredient_id': row.ingredientId,
            'quantity_required': qty,
          });
        }
      }
    }

    context.read<RecipeBloc>().add(
          SaveBulkRecipe(
            menuItemId: widget.menuItemId,
            recipes: recipesToSave,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Редактор техкарты', style: AppTextStyles.h2),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(PhosphorIconsRegular.plus),
                          label: const Text('Добавить строку'),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.x),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('Сырье / Ингредиент', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Text('Кол-во', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    SizedBox(width: 96),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      final selectedIngredient = widget.availableIngredients
                          .where((i) => i.id == row.ingredientId)
                          .firstOrNull;

                      return RecipeBulkEditRow(
                        row: row,
                        index: index,
                        selectedIngredient: selectedIngredient,
                        onPickIngredient: () async {
                          final selectedId = await IngredientPickerDialog.show(
                            context,
                            widget.availableIngredients,
                          );
                          if (selectedId != null) {
                            setState(() => row.ingredientId = selectedId);
                          }
                        },
                        onDuplicate: () => _duplicateRow(index),
                        onRemove: () => _removeRow(index),
                        onAddNext: () {
                          if (index == _rows.length - 1) {
                            _addRow();
                          }
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Всего строк: ${_rows.length}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Отмена'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Сохранить (Ctrl+S)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
