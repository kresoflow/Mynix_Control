import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';


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
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.'));
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
          },
        ],
      };

      final doc = await repo.createDocument(docData);
      await repo.completeDocument(doc.id);

      if (mounted) {
        context.read<IngredientBloc>().add(const LoadIngredients());
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReceipt = widget.actionType == 'receipt';
    final actionName = isReceipt ? 'Приход' : 'Списание';
    final actionColor = isReceipt ? AppColors.success : AppColors.danger;

    return AppDialog(
      title: 'Быстрый $actionName',
      subtitle: widget.item.name,
      icon: isReceipt ? PhosphorIconsRegular.arrowCircleDown : PhosphorIconsRegular.arrowCircleUp,
      iconColor: actionColor,
      isDestructive: !isReceipt,
      width: 440,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Текущий остаток: ${UnitFormatter.formatAmount(widget.item.currentStock, widget.item.unit)}',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          AppSpacing.vMd,
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Количество (${UnitFormatter.format(widget.item.unit)})',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(PhosphorIconsRegular.calculator, size: 20),
            ),
          ),
          AppSpacing.vMd,
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
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        AppPrimaryButton(
          label: isReceipt ? 'Оприходовать' : 'Списать',
          customColor: actionColor,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _submit,
        ),
      ],
    );
  }
}