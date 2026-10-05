import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'receive_document_payment_section.dart';

class ReceiveDocumentFooter extends StatelessWidget {
  final double totalSum;
  final ValueListenable<double>? totalSumListenable;
  final String currency;
  final bool isSaving;
  final String paymentStatus;
  final String paymentMethod;
  final TextEditingController paidAmountController;
  final ValueChanged<String> onPaymentStatusChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final int cartItemCount;
  final ValueListenable<int>? cartCountListenable;
  final VoidCallback? onToggleCart;
  final bool isCartOpen;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onSaveComplete;

  const ReceiveDocumentFooter({
    super.key,
    required this.totalSum,
    this.totalSumListenable,
    required this.currency,
    required this.isSaving,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paidAmountController,
    required this.onPaymentStatusChanged,
    required this.onPaymentMethodChanged,
    this.cartItemCount = 0,
    this.cartCountListenable,
    this.onToggleCart,
    this.isCartOpen = false,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onSaveComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget totalTextWidget(double sum) {
      return Text(
        '${sum.toStringAsFixed(2)} $currency',
        style: AppTextStyles.h1.copyWith(
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    Widget cartButtonWidget(int count) {
      return InkWell(
        onTap: onToggleCart,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCartOpen
                ? AppColors.brandPrimary
                : (count > 0
                    ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10)
                    : (isDark ? AppColors.darkCard : AppColors.lightBg)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCartOpen || count > 0
                  ? AppColors.brandPrimary.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.shoppingCart,
                size: 15,
                color: isCartOpen
                    ? AppColors.pureWhite
                    : (count > 0 ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              ),
              const SizedBox(width: 6),
              Text(
                '$count поз.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCartOpen
                      ? AppColors.pureWhite
                      : (count > 0 ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isCartOpen ? PhosphorIconsRegular.caretDown : PhosphorIconsRegular.caretUp,
                size: 12,
                color: isCartOpen
                    ? AppColors.pureWhite
                    : (count > 0 ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Блок условий оплаты (слева)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ReceiveDocumentPaymentSection(
                isDark: isDark,
                paymentStatus: paymentStatus,
                paymentMethod: paymentMethod,
                paidAmountController: paidAmountController,
                onPaymentStatusChanged: onPaymentStatusChanged,
                onPaymentMethodChanged: onPaymentMethodChanged,
              ),
            ),
          ),
          const Spacer(),

          // 2. Кнопка корзины (по центру-справа перед итогом)
          if (onToggleCart != null) ...[
            if (cartCountListenable != null)
              ValueListenableBuilder<int>(
                valueListenable: cartCountListenable!,
                builder: (_, count, __) => cartButtonWidget(count),
              )
            else
              cartButtonWidget(cartItemCount),
            const SizedBox(width: 14),
          ],

          // 3. Итого к оплате (рядом с проведением)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ИТОГО:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              if (totalSumListenable != null)
                ValueListenableBuilder<double>(
                  valueListenable: totalSumListenable!,
                  builder: (_, sum, __) => totalTextWidget(sum),
                )
              else
                totalTextWidget(totalSum),
            ],
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // 4. Кнопки действий
          AppButton.ghost(
            label: 'Отмена',
            height: 38,
            onPressed: onCancel,
          ),
          const SizedBox(width: 8),
          AppButton.secondary(
            label: 'Черновик',
            icon: PhosphorIconsRegular.floppyDisk,
            height: 38,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveDraft,
          ),
          const SizedBox(width: 8),
          AppButton.primary(
            label: 'Провести (Ctrl+S)',
            icon: PhosphorIconsRegular.checkCircle,
            height: 38,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveComplete,
          ),
        ],
      ),
    );
  }
}
