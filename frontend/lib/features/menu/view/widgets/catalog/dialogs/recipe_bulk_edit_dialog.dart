import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

class RecipeRowState {
  int? ingredientId;
  TextEditingController quantityController;
  final FocusNode ingredientFocusNode = FocusNode();

  RecipeRowState({this.ingredientId, double quantity = 0})
      : quantityController = TextEditingController(
            text: quantity > 0 ? quantity.toString() : '');

  void dispose() {
    quantityController.dispose();
    ingredientFocusNode.dispose();
  }
}

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
          quantity: (recipe['quantity_required'] as num).toDouble(),
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
    setState(() {
      _rows.add(RecipeRowState());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rows.isNotEmpty) {
        _rows.last.ingredientFocusNode.requestFocus();
      }
    });
  }

  void _duplicateRow(int index) {
    setState(() {
      _rows.insert(index + 1, RecipeRowState(
        ingredientId: _rows[index].ingredientId,
        quantity: double.tryParse(_rows[index].quantityController.text) ?? 0,
      ));
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

  Future<int?> _showIngredientPicker(BuildContext context) {
    final Map<String, List<dynamic>> grouped = {};
    for (var ing in widget.availableIngredients) {
      final catName = ing.categoryName ?? 'Без категории';
      grouped.putIfAbsent(catName, () => []).add(ing);
    }
    
    final sortedKeys = grouped.keys.toList()..sort();

    return showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Выберите сырье', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.of(ctx).pop(),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final catName = sortedKeys[index];
                    final items = grouped[catName]!;
                    return ExpansionTile(
                      title: Text(catName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      initiallyExpanded: false,
                      shape: const Border(),
                      children: items.map((ing) => ListTile(
                        title: Text(ing.name),
                        subtitle: Text('Алерт: ${ing.minStockAlert.toInt()} ${ing.unit} | Остаток: ${ing.currentStock.toInt()} ${ing.unit}'),
                        trailing: Text(ing.unit, style: const TextStyle(color: Colors.grey)),
                        onTap: () {
                          Navigator.of(ctx).pop(ing.id);
                        },
                      )).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    const Text(
                      'Редактор техкарты',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
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
                Row(
                  children: const [
                    Expanded(flex: 3, child: Text('Сырье / Ингредиент', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    SizedBox(width: 16),
                    Expanded(flex: 1, child: Text('Кол-во', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    SizedBox(width: 96), // Space for copy/delete buttons
                  ],
                ),
                const Divider(),
                Expanded(
              child: ListView.separated(
                itemCount: _rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = _rows[index];
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
                            final selected = await _showIngredientPicker(context);
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
                          onFieldSubmitted: (_) => _addRow(),
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
                            icon: const Icon(PhosphorIconsRegular.copy, color: Colors.blue),
                            onPressed: () => _duplicateRow(index),
                            tooltip: 'Дублировать',
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                            onPressed: () => _removeRow(index),
                            tooltip: 'Удалить',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _save,
                child: const Text(
                  'Сохранить всё (Ctrl+S)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }
}
