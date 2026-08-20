import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';

class CustomerPaymentModal extends StatefulWidget {
  final Customer customer;
  final Function(Map<String, dynamic> data) onSubmit;

  const CustomerPaymentModal({
    super.key,
    required this.customer,
    required this.onSubmit,
  });

  @override
  State<CustomerPaymentModal> createState() => _CustomerPaymentModalState();
}

class _CustomerPaymentModalState extends State<CustomerPaymentModal> {
  late final TextEditingController _amountController;
  final _commentController = TextEditingController();
  String _paymentMethod = 'cash'; // 'cash' or 'transfer'
  bool _isDeposit = false;

  @override
  void initState() {
    super.initState();
    _isDeposit = widget.customer.balance >= 0;
    final defaultAmount = widget.customer.balance < 0 ? widget.customer.balance.abs() : 0.0;
    _amountController = TextEditingController(
      text: defaultAmount > 0 ? defaultAmount.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    final txnType = _isDeposit
        ? CustomerTransactionType.deposit.toApiString()
        : CustomerTransactionType.payment.toApiString();

    widget.onSubmit({
      'type': txnType,
      'amount': amount,
      'payment_method': _paymentMethod,
      'comment': _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : (_isDeposit ? 'Внесение депозита' : 'Погашение долга'),
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final symbol = CurrencyFormatter.symbol(context);

    return MynixDialog(
      title: _isDeposit ? 'Внесение депозита' : 'Погашение долга',
      icon: _isDeposit ? PhosphorIconsRegular.wallet : PhosphorIconsRegular.money,
      width: 440,
      actions: [
        AppButton.secondary(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: 'Провести',
          onPressed: _submit,
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Operation Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeTab(
                    label: 'Погашение долга',
                    isSelected: !_isDeposit,
                    onTap: () => setState(() => _isDeposit = false),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildTypeTab(
                    label: 'Депозит (Аванс)',
                    isSelected: _isDeposit,
                    onTap: () => setState(() => _isDeposit = true),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount input
          Text('Сумма ($symbol)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
              prefixIcon: Icon(PhosphorIconsRegular.currencyDollar, color: AppColors.brandPrimary),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Method (Cash vs Transfer)
          Text('Способ оплаты', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildMethodButton(
                  label: 'Наличные',
                  icon: PhosphorIconsRegular.money,
                  method: 'cash',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMethodButton(
                  label: 'Перевод / Банк',
                  icon: PhosphorIconsRegular.creditCard,
                  method: 'transfer',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comment input
          Text('Комментарий (необязательно)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Например: перевод через банк',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab({required String label, required bool isSelected, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppColors.darkSurface : AppColors.lightSurface) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodButton({required String label, required IconData icon, required String method, required bool isDark}) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.12) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
