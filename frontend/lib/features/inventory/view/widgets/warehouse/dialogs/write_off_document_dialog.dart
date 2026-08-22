import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'write_off/write_off_add_item_bar.dart';
import 'write_off/write_off_items_table.dart';

class WriteOffDocumentDialog extends StatefulWidget {
  const WriteOffDocumentDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => const WriteOffDocumentDialog(),
    );
  }

  @override
  State<WriteOffDocumentDialog> createState() => _WriteOffDocumentDialogState();
}

class _WriteOffDocumentDialogState extends State<WriteOffDocumentDialog> {
  String _selectedReason = 'Порча / Просрочка';
  final TextEditingController _commentController = TextEditingController();
  final List<WriteOffItemEntry> _entries = [];
  bool _isLoading = false;

  final List<String> _reasons = const [
    'Порча / Просрочка',
    'Брак / Бой',
    'Питание персонала',
    'Угощение гостя',
    'Прочее',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    for (var e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  void _addItem(Ingredient item) {
    if (_entries.any((e) => e.item.id == item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${item.name}» уже добавлена в список')),
      );
      return;
    }
    setState(() {
      _entries.add(WriteOffItemEntry(item: item, quantity: 1.0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final e = _entries.removeAt(index);
      e.controller.dispose();
    });
  }

  double get _totalAmount => _entries.fold(0.0, (sum, e) => sum + e.total);

  Future<void> _submit() async {
    final validEntries = _entries.where((e) => e.quantity > 0).toList();
    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите количество для списания хотя бы одной позиции')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<InventoryRepository>();
      final reasonText = _commentController.text.trim().isNotEmpty
          ? '$_selectedReason: ${_commentController.text.trim()}'
          : _selectedReason;

      final items = validEntries.map((e) {
        final isRetail = e.item.attributes?['is_retail'] == true;
        return {
          if (isRetail) 'retail_product_id': e.item.id else 'ingredient_id': e.item.id,
          'quantity': e.quantity,
          'price_per_unit': e.cost,
          'total_price': e.total,
        };
      }).toList();

      final docData = {
        'type': 'write_off',
        'reason': reasonText,
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
            content: Text('Акт списания успешно проведен!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка списания: ${e.toString()}'), backgroundColor: AppColors.danger),
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
    final currency = context.watch<SettingsBloc>().state.currency;
    final ingState = context.watch<IngredientBloc>().state;
    final availableIngredients = ingState is IngredientLoaded ? ingState.ingredients : <Ingredient>[];

    return MynixDialog(
      title: 'Акт списания сырья со склада',
      icon: PhosphorIconsRegular.trashSimple,
      isDestructive: true,
      width: 650,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reason selector
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Причина списания',
                    isDense: true,
                  ),
                  items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Примечание / Комментарий (опционально)',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add item autocomplete bar
          WriteOffAddItemBar(
            availableIngredients: availableIngredients,
            onIngredientSelected: _addItem,
          ),
          const SizedBox(height: 12),

          // Items table
          WriteOffItemsTable(
            items: _entries,
            currency: currency,
            onRemove: _removeItem,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Total losses banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Общая сумма списания (по себестоимости):',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${_totalAmount.toStringAsFixed(2)} $currency',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        AppDangerButton(
          label: 'Провести списание',
          icon: PhosphorIconsRegular.check,
          isLoading: _isLoading,
          onPressed: _isLoading || _entries.isEmpty ? null : _submit,
        ),
      ],
    );
  }
}
