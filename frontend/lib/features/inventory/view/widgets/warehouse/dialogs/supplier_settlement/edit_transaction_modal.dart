// ==============================================================================
// Title: Edit Transaction Modal
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/edit_transaction_modal.dart
// Description: Модальное окно редактирования суммы и комментария операции с поставщиком.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';
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
  late TextEditingController _amountController;
  late TextEditingController _commentController;
  late String _paymentMethod;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amount.toStringAsFixed(2));
    _commentController = TextEditingController(text: widget.transaction.comment ?? '');
    _paymentMethod = widget.transaction.paymentMethod ?? 'cash';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                    style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      size: 20,
                    ),
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

              Text(
                'Способ оплаты',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 6),
              _buildMethodSelector(isDark),
              const SizedBox(height: 14),

              AppTextField(
                labelText: 'Комментарий',
                controller: _commentController,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Отмена',
                      size: AppButtonSize.md,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Сохранить',
                      size: AppButtonSize.md,
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

  Widget _buildMethodSelector(bool isDark) {
    return Row(
      children: [
        _buildMethodChip('cash', 'Наличные', PhosphorIconsRegular.money, isDark),
        const SizedBox(width: 8),
        _buildMethodChip('bank_transfer', 'Перевод / Р/С', PhosphorIconsRegular.bank, isDark),
        const SizedBox(width: 8),
        _buildMethodChip('card', 'Карта', PhosphorIconsRegular.creditCard, isDark),
      ],
    );
  }

  Widget _buildMethodChip(String id, String label, IconData icon, bool isDark) {
    final isSelected = _paymentMethod == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = id),
        borderRadius: AppRadii.inputRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimary.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkBg : AppColors.lightBg),
            borderRadius: AppRadii.inputRadius,
            border: Border.all(
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
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
