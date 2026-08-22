import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupplierPaymentDialog extends StatefulWidget {
  final Supplier supplier;
  final String currency;

  const SupplierPaymentDialog({
    super.key,
    required this.supplier,
    required this.currency,
  });

  @override
  State<SupplierPaymentDialog> createState() => _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState extends State<SupplierPaymentDialog> {
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    if (widget.supplier.balance < 0) {
      _amountController.text = widget.supplier.balance.abs().toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную сумму выплаты'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'amount': amount,
      'payment_method': _paymentMethod,
      'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final debt = widget.supplier.balance < 0 ? widget.supplier.balance.abs() : 0.0;

    return MynixDialog(
      title: 'Выплата поставщику',
      icon: PhosphorIconsRegular.money,
      width: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Карточка поставщика и долга ───────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.supplier.name,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Текущий долг: ${debt.toStringAsFixed(2)} ${widget.currency}',
                        style: TextStyle(
                          fontSize: 12,
                          color: debt > 0 ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (debt > 0)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _amountController.text = debt.toStringAsFixed(2)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Весь долг',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Поле суммы выплаты ────────────────────────────────────
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Сумма выплаты (${widget.currency})',
              prefixIcon: const Icon(PhosphorIconsRegular.currencyCircleDollar, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          // ── Способ оплаты ─────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: InputDecoration(
              labelText: 'Способ оплаты',
              prefixIcon: const Icon(PhosphorIconsRegular.creditCard, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              DropdownMenuItem(
                value: 'cash',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.money, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    const Text('Наличные (Касса)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'card',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.creditCard, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    const Text('Банковская карта'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'bank_transfer',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.bank, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    const Text('Расчетный счет / Перевод'),
                  ],
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _paymentMethod = val);
            },
          ),
          const SizedBox(height: 12),

          // ── Комментарий ───────────────────────────────────────────
          TextField(
            controller: _commentController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              labelText: 'Комментарий (необязательно)',
              prefixIcon: const Icon(PhosphorIconsRegular.textAa, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppPrimaryButton(
          label: 'Внести выплату',
          icon: PhosphorIconsRegular.check,
          width: null,
          onPressed: _submit,
        ),
      ],
    );
  }
}
