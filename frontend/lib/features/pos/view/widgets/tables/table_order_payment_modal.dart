// ==============================================================================
// МОДУЛЬ: POS / Модальное окно расчета столика (TableOrderPaymentModal)
// ДОМЕН: lib/features/pos/view/widgets/tables/table_order_payment_modal.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Модальное окно выбора способа оплаты и закрытия столика:
// 1. Отображает итоговую сумму заказа и номер столика.
// 2. Предоставляет выбор метода оплаты (Наличные, Безналичный перевод / QR).
// 3. Использует официальный эталон AppDialog и компоненты AppButton.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';

// ── 1. Модальное окно выбора способа оплаты и закрытия столика ───────────────

class TableOrderPaymentModal extends StatefulWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(String paymentMethod, String paymentAccount) onConfirm;

  const TableOrderPaymentModal({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> order,
    required Future<void> Function(String paymentMethod, String paymentAccount) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TableOrderPaymentModal(order: order, onConfirm: onConfirm),
    );
  }

  @override
  State<TableOrderPaymentModal> createState() => _TableOrderPaymentModalState();
}

class _TableOrderPaymentModalState extends State<TableOrderPaymentModal> {
  String _selectedMethod = 'cash'; // 'cash', 'transfer'
  String _transferProvider = 'dc'; // 'dc', 'alif', 'spitamen', 'other'
  bool _isLoading = false;

  static const _providers = [
    (id: 'dc', label: 'DC'),
    (id: 'alif', label: 'Алиф'),
    (id: 'spitamen', label: 'Спитамен'),
    (id: 'other', label: 'Другой'),
  ];

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      final account = _selectedMethod == 'transfer' ? _transferProvider : 'cash';
      await widget.onConfirm(_selectedMethod, account);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderNum = widget.order['order_number']?.toString() ?? '${widget.order['id']}';
    final total = (widget.order['total'] as num?)?.toDouble() ?? 0.0;
    final tableNum = widget.order['table_number']?.toString() ?? 'Зал';

    return AppDialog(
      title: 'Оплата заказа #$orderNum',
      icon: PhosphorIconsBold.creditCard,
      width: 440,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Карточка итогов ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Столик / Заказ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tableNum,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'К оплате',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total.toCurrency(context),
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vMd,
          Text(
            'Способ оплаты',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          AppSpacing.vSm,

          // ── Варианты оплаты ───────────────────────────────────────────────
          _buildMethodTile('cash', 'Наличные', PhosphorIconsBold.money, isDark),
          AppSpacing.vSm,
          _buildMethodTile('transfer', 'Безналичный перевод (QR)', PhosphorIconsBold.qrCode, isDark),
          if (_selectedMethod == 'transfer') ...[
            AppSpacing.vSm,
            _buildTransferProviders(isDark),
          ],
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        AppPrimaryButton(
          label: 'Подтвердить оплату',
          isLoading: _isLoading,
          onPressed: _handleConfirm,
        ),
      ],
    );
  }

  Widget _buildMethodTile(String method, String title, IconData icon, bool isDark) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: AppRadii.radiusLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: AppRadii.radiusLg,
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            AppSpacing.hSm,
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            if (isSelected)
              Icon(PhosphorIconsBold.checkCircle, size: 18, color: AppColors.brandPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferProviders(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: _providers.map((p) {
          final isSelected = _transferProvider == p.id;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _transferProvider = p.id),
              borderRadius: AppRadii.radiusSm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : AppColors.transparent,
                  borderRadius: AppRadii.radiusSm,
                ),
                alignment: Alignment.center,
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.pureBlack
                        : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
