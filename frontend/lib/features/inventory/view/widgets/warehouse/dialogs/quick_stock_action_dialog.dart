import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class QuickStockActionDialog extends StatefulWidget {
  final Ingredient item;
  final String actionType; // 'receipt' or 'write_off'

  const QuickStockActionDialog({
    super.key,
    required this.item,
    required this.actionType,
  });

  static Future<void> show(
    BuildContext context, {
    required Ingredient item,
    required String actionType,
  }) async {
    return showDialog(
      context: context,
      builder: (_) => QuickStockActionDialog(item: item, actionType: actionType),
    );
  }

  @override
  State<QuickStockActionDialog> createState() => _QuickStockActionDialogState();
}

class _QuickStockActionDialogState extends State<QuickStockActionDialog> {
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректное количество')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<InventoryRepository>();
      final isRetail = widget.item.attributes?['is_retail'] == true;

      // Create document
      final docData = {
        'type': widget.actionType,
        'reason': _reasonController.text.isEmpty
            ? (widget.actionType == 'receipt' ? 'Быстрый приход' : 'Быстрое списание')
            : _reasonController.text,
        'items': [
          {
            if (isRetail) 'retail_product_id': widget.item.id else 'ingredient_id': widget.item.id,
            'quantity': qty,
            'price_per_unit': widget.item.costPerUnit,
          }
        ]
      };

      final doc = await repo.createDocument(docData);
      await repo.completeDocument(doc.id);

      if (mounted) {
        context.read<IngredientBloc>().add(LoadIngredients());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.actionType == 'receipt'
                  ? 'Успешно оприходовано!'
                  : 'Успешно списано!',
            ),
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
    final isReceipt = widget.actionType == 'receipt';
    final actionName = isReceipt ? 'Приход' : 'Списание';
    final actionColor = isReceipt ? AppColors.success : AppColors.danger;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isReceipt ? Icons.download : Icons.upload,
            color: actionColor,
          ),
          const SizedBox(width: 8),
          Text('Быстрый $actionName'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Текущий остаток: ${widget.item.currentStock.toStringAsFixed(2)} ${widget.item.unit}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Количество (${widget.item.unit})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calculate),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Причина (опционально)',
                hintText: isReceipt ? 'Поставка от поставщика...' : 'Порча, просрочка...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isReceipt ? 'Оприходовать' : 'Списать'),
        ),
      ],
    );
  }
}