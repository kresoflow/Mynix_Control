// ==============================================================================
// Title: SupplierSettlementDrawer (supplier_settlement_drawer.dart)
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_drawer.dart
// Description: Выдвижная боковая панель (Slide-Over Drawer) для проведения выплат.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';
import 'package:kreso_frontend/core/widgets/app_text_field.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';
import 'supplier_payment_method_selector.dart';

// ─── 1. Боковая панель оформления выплаты или корректировки долга ─────────────

/// [UI-KIT] Slide-Over панель внутри диалога взаиморасчетов (предотвращает Double Modal)
class SupplierSettlementDrawer extends StatefulWidget {
  final Supplier supplier;
  final String currency;
  final SupplierTransactionType initialType;
  final SupplierTransaction? transactionToEdit;
  final Function(Map<String, dynamic> data) onSave;
  final VoidCallback onClose;

  const SupplierSettlementDrawer({
    super.key,
    required this.supplier,
    required this.currency,
    this.initialType = SupplierTransactionType.payment,
    this.transactionToEdit,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<SupplierSettlementDrawer> createState() => _SupplierSettlementDrawerState();
}

class _SupplierSettlementDrawerState extends State<SupplierSettlementDrawer> {
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  late SupplierTransactionType _selectedType;
  late String _paymentMethod;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final editTxn = widget.transactionToEdit;
    if (editTxn != null) {
      _selectedType = editTxn.type;
      _paymentMethod = editTxn.paymentMethod;
      _amountController.text = editTxn.amount.toStringAsFixed(2);
      _commentController.text = editTxn.comment ?? '';
    } else {
      _selectedType = widget.initialType;
      _paymentMethod = 'cash';
      if (widget.supplier.balance < 0 && _selectedType == SupplierTransactionType.payment) {
        _amountController.text = widget.supplier.balance.abs().toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final amt = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      setState(() => _errorText = 'Введите корректную сумму > 0');
      return;
    }

    widget.onSave({
      'type': _selectedType,
      'amount': amt,
      'payment_method': _paymentMethod,
      'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.transactionToEdit != null;
    final isPayment = _selectedType == SupplierTransactionType.payment;

    return AppSaveShortcutScope(
      onSave: _submit,
      onCancel: widget.onClose,
      child: Stack(
        children: [
          // Полупрозрачный кликабельный фон для закрытия
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          // Выдвижная правая панель
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 390,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                border: Border(
                  left: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                boxShadow: AppShadows.deep,
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Шапка панели
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit
                            ? 'Редактировать операцию'
                            : (isPayment ? 'Внести выплату' : 'Зафиксировать долг'),
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.x,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          size: 18,
                        ),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Поставщик: ${widget.supplier.name}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Переключатель типа (только при создании)
                  if (!isEdit) ...[
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
                  ],

                  // Поле ввода суммы
                  AppTextField(
                    labelText: 'Сумма (${widget.currency})',
                    hintText: '0.00',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    errorText: _errorText,
                  ),
                  const SizedBox(height: 14),

                  // Способ оплаты (если выплата)
                  if (isPayment) ...[
                    Text(
                      'Способ оплаты',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SupplierPaymentMethodSelector(
                      selectedMethod: _paymentMethod,
                      onMethodChanged: (val) => setState(() => _paymentMethod = val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Основание платежа
                  AppTextField(
                    labelText: 'Комментарий / Основание',
                    hintText: isPayment ? 'Чек #123, оплата за сырье' : 'Начальный долг',
                    controller: _commentController,
                  ),
                  const Spacer(),

                  // Кнопки действий подвала
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Отмена',
                          size: AppButtonSize.md,
                          onPressed: widget.onClose,
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
        ],
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
            Icon(icon, size: 14, color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
