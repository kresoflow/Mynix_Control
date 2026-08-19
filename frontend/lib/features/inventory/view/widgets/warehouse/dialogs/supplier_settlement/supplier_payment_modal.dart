import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupplierPaymentModal extends StatefulWidget {
  final Supplier supplier;
  final String currency;
  final SupplierTransactionType initialType;

  const SupplierPaymentModal({
    super.key,
    required this.supplier,
    required this.currency,
    this.initialType = SupplierTransactionType.payment,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Supplier supplier,
    required String currency,
    SupplierTransactionType initialType = SupplierTransactionType.payment,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SupplierPaymentModal(
        supplier: supplier,
        currency: currency,
        initialType: initialType,
      ),
    );
  }

  @override
  State<SupplierPaymentModal> createState() => _SupplierPaymentModalState();
}

class _SupplierPaymentModalState extends State<SupplierPaymentModal> {
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  late SupplierTransactionType _selectedType;
  String _paymentMethod = 'cash';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    if (widget.supplier.balance < 0 && _selectedType == SupplierTransactionType.payment) {
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
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
      return;
    }

    Navigator.pop(context, {
      'type': _selectedType,
      'amount': amount,
      'payment_method': _paymentMethod,
      'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPayment = _selectedType == SupplierTransactionType.payment;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    isPayment ? 'Внести выплату' : 'Зафиксировать долг',
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
                'Поставщик: ${widget.supplier.name}',
                style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary),
              ),
              const SizedBox(height: 16),

              // Type Selector Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'Выплата долга',
                        SupplierTransactionType.payment,
                        PhosphorIconsRegular.arrowDownLeft,
                      ),
                    ),
                    Expanded(
                      child: _buildTypeButton(
                        'Начислить долг',
                        SupplierTransactionType.manualDebt,
                        PhosphorIconsRegular.arrowUpRight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                labelText: 'Сумма (${widget.currency})',
                hintText: '0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                errorText: _errorText,
              ),
              const SizedBox(height: 14),

              if (isPayment) ...[
                Text('Способ оплаты', style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
                const SizedBox(height: 6),
                _buildMethodSelector(),
                const SizedBox(height: 14),
              ],

              AppTextField(
                labelText: 'Комментарий / Основание',
                hintText: isPayment ? 'Чек #123, оплата за сырье' : 'Начальный долг с прошлого месяца',
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

  Widget _buildTypeButton(String label, SupplierTransactionType type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.brandPrimary : AppColors.darkSubtext),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.darkText : AppColors.darkSubtext,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
