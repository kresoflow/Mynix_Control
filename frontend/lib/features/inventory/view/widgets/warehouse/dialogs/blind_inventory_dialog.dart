import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class BlindInventoryDialog extends StatefulWidget {
  const BlindInventoryDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => const BlindInventoryDialog(),
    );
  }

  @override
  State<BlindInventoryDialog> createState() => _BlindInventoryDialogState();
}

class _BlindInventoryDialogState extends State<BlindInventoryDialog> {
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<Ingredient> ingredients) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<InventoryRepository>();
      
      final List<Map<String, dynamic>> items = [];
      
      for (var item in ingredients) {
        final ctrl = _controllers[item.id];
        if (ctrl != null && ctrl.text.isNotEmpty) {
          final actualQty = double.tryParse(ctrl.text);
          if (actualQty != null) {
            final isRetail = item.attributes?['is_retail'] == true;
            items.add({
              if (isRetail) 'retail_product_id': item.id else 'ingredient_id': item.id,
              'quantity': actualQty,
              'price_per_unit': item.costPerUnit,
            });
          }
        }
      }

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы не ввели ни одного остатка')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final docData = {
        'type': 'inventory',
        'reason': 'Слепая инвентаризация',
        'items': items,
      };

      final doc = await repo.createDocument(docData);
      await repo.completeDocument(doc.id);

      if (mounted) {
        context.read<IngredientBloc>().add(LoadIngredients());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Инвентаризация успешно проведена!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Слепая Инвентаризация',
                        style: AppTextStyles.h2,
                      ),
                      Text(
                        'Введите фактическое количество товара на полках',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<IngredientBloc, IngredientState>(
                builder: (context, state) {
                  if (state is IngredientLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is IngredientLoaded) {
                    return ListView.separated(
                      itemCount: state.ingredients.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = state.ingredients[index];
                        if (!_controllers.containsKey(item.id)) {
                          _controllers[item.id] = TextEditingController();
                        }
                        return ListTile(
                          title: Text(item.name, style: const AppTextStyles.bodyLargeBold),
                          subtitle: Text(item.attributes?['is_retail'] == true ? 'Витрина' : 'Сырье'),
                          trailing: SizedBox(
                            width: 150,
                            child: TextField(
                              controller: _controllers[item.id],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Факт (${item.unit})',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Ошибка загрузки'));
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 16),
                BlocBuilder<IngredientBloc, IngredientState>(
                  builder: (context, state) {
                    return ElevatedButton.icon(
                      icon: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: const Text('Завершить инвентаризацию'),
                      onPressed: _isLoading || state is! IngredientLoaded
                          ? null
                          : () => _submit(state.ingredients),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}