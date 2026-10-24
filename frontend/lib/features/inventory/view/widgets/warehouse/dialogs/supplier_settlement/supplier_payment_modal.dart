// ==============================================================================
// Title: Supplier Payment Modal
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_payment_modal.dart
// Description: Модальное окно проведения выплаты или фиксации ручного долга поставщика.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPayment = _selectedType == SupplierTransactionType.payment;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                'Поставщик: ${widget.supplier.name}',
                style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary),
              ),
              const SizedBox(height: 16),

              // Type Selector Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  borderRadius: AppRadii.inputRadius,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'Выплата долга',
                        SupplierTransactionType.payment,
                        PhosphorIconsRegular.arrowDownLeft,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildTypeButton(
                        'Начислить долг',
                        SupplierTransactionType.manualDebt,
                        PhosphorIconsRegular.arrowUpRight,
                        isDark,
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
                Text(
                  'Способ оплаты',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 6),
                _buildMethodSelector(isDark),
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

  Widget _buildTypeButton(String label, SupplierTransactionType type, IconData icon, bool isDark) {
    final isSelected = _selectedType == type;
    final activeBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isSelected
        ? (isDark ? AppColors.darkText : AppColors.lightText)
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.transparent,
          borderRadius: AppRadii.inputRadius,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark) {
    const methods = [
      ('cash', 'Наличные', PhosphorIconsRegular.money),
      ('bank_transfer', 'Перевод / Р/С', PhosphorIconsRegular.bank),
      ('card', 'Карта', PhosphorIconsRegular.creditCard),
    ];
    return Row(
      children: [
        for (int i = 0; i < methods.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _buildMethodChip(methods[i].$1, methods[i].$2, methods[i].$3, isDark),
        ],
      ],
    );
  }

  Widget _buildMethodChip(String id, String label, IconData icon, bool isDark) {
    final isSelected = _paymentMethod == id;
    final bg = isSelected ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg);
    final border = isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final iconColor = isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = id),
        borderRadius: AppRadii.inputRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadii.inputRadius, border: Border.all(color: border, width: 0.8)),
          child: Column(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: iconColor,
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
