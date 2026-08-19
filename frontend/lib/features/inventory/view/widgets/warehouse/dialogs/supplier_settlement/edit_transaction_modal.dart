import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EditTransactionModal extends StatefulWidget {
  final SupplierTransaction transaction;
  final String currency;

  const EditTransactionModal({
    super.key,
    required this.transaction,
    required this.currency,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required SupplierTransaction transaction,
    required String currency,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditTransactionModal(
        transaction: transaction,
        currency: currency,
      ),
    );
  }

  @override
  State<EditTransactionModal> createState() => _EditTransactionModalState();
}

class _EditTransactionModalState extends State<EditTransactionModal> {
  late final TextEditingController _amountController;
  late final TextEditingController _commentController;
  late String _paymentMethod;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amount.toStringAsFixed(2));
    _commentController = TextEditingController(text: widget.transaction.comment ?? '');
    _paymentMethod = widget.transaction.paymentMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
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
    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Редактировать операцию',
                    style: AppTextStyles.h2.copyWith(color: AppColors.darkText),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.x, color: AppColors.darkSubtext, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Тип: ${widget.transaction.type.label}',
                style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary),
              ),
              const SizedBox(height: 16),

              AppTextField(
                labelText: 'Сумма (${widget.currency})',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                errorText: _errorText,
              ),
              const SizedBox(height: 14),

              Text('Способ оплаты', style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
              const SizedBox(height: 6),
              _buildMethodSelector(),
              const SizedBox(height: 14),

              AppTextField(
                labelText: 'Комментарий',
                controller: _commentController,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Отмена',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Сохранить',
                      variant: AppButtonVariant.primary,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        _buildMethodChip('cash', 'Наличные', PhosphorIconsRegular.money),
        const SizedBox(width: 8),
        _buildMethodChip('bank_transfer', 'Перевод / Р/С', PhosphorIconsRegular.bank),
        const SizedBox(width: 8),
        _buildMethodChip('card', 'Карта', PhosphorIconsRegular.creditCard),
      ],
    );
  }

  Widget _buildMethodChip(String id, String label, IconData icon) {
    final isSelected = _paymentMethod == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.15) : AppColors.darkBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.brandPrimary : AppColors.darkSubtext),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: isSelected ? AppColors.brandPrimary : AppColors.darkSubtext,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
