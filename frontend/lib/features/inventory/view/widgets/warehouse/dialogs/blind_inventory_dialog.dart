import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
            final itemTotal = actualQty * item.costPerUnit;
            items.add({
              if (isRetail) 'retail_product_id': item.id else 'ingredient_id': item.id,
              'quantity': actualQty,
              'price_per_unit': item.costPerUnit,
              'total_price': itemTotal,
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
        try {
          context.read<DocumentBloc>().add(const LoadDocuments());
        } catch (_) {}

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Инвентаризация успешно проведена!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}'), backgroundColor: AppColors.danger),
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
    return MynixDialog(
      title: 'Слепая Инвентаризация',
      icon: PhosphorIconsRegular.clipboardText,
      width: 600,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Введите фактическое количество товара на полках', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: BlocBuilder<IngredientBloc, IngredientState>(
              builder: (context, state) {
                if (state is IngredientLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is IngredientLoaded) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.ingredients.length,
                    separatorBuilder: (_, _) => Divider(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder.withValues(alpha: 0.5)),
                    itemBuilder: (context, index) {
                      final item = state.ingredients[index];
                      if (!_controllers.containsKey(item.id)) {
                        _controllers[item.id] = TextEditingController();
                      }
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name, style: AppTextStyles.bodyMedium),
                        subtitle: Text(
                          item.attributes?['is_retail'] == true ? 'Витрина' : 'Сырье',
                          style: AppTextStyles.caption.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
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
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        BlocBuilder<IngredientBloc, IngredientState>(
          builder: (context, state) {
            return AppPrimaryButton(
              label: 'Завершить',
              icon: PhosphorIconsRegular.check,
              isLoading: _isLoading,
              onPressed: _isLoading || state is! IngredientLoaded
                  ? null
                  : () => _submit(state.ingredients),
            );
          },
        ),
      ],
    );
  }
}
