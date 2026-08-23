import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class PosCheckoutPanelActionButton extends StatelessWidget {
  final bool isEmpty;
  final bool isSubmitting;
  final String paymentMethod;
  final String transferProvider;
  final double payableTotal;
  final VoidCallback onCheckout;
  final VoidCallback onSendToBooth;
  final bool isDark;

  const PosCheckoutPanelActionButton({
    super.key,
    required this.isEmpty,
    required this.isSubmitting,
    required this.paymentMethod,
    required this.transferProvider,
    required this.payableTotal,
    required this.onCheckout,
    required this.onSendToBooth,
    required this.isDark,
  });

  String _getProviderLabel(String id) {
    switch (id) {
      case 'dc':
        return 'DC';
      case 'alif':
        return 'Alif';
      case 'spitamen':
        return 'Spitamen';
      default:
        return 'Перевод';
    }
  }

  String _getButtonLabel() {
    if (paymentMethod == 'TRANSFER') {
      return 'Оплатить (${_getProviderLabel(transferProvider)})';
    } else if (paymentMethod == 'DEBT') {
      return 'В долг';
    } else if (paymentMethod == 'DEPOSIT') {
      return 'С депозита';
    }
    return 'Оплатить';
  }

  IconData _getButtonIcon() {
    if (paymentMethod == 'TRANSFER') return PhosphorIconsRegular.qrCode;
    if (paymentMethod == 'DEBT') return PhosphorIconsRegular.handCoins;
    if (paymentMethod == 'DEPOSIT') return PhosphorIconsRegular.wallet;
    return PhosphorIconsRegular.creditCard;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Send to Booth / Cashier button (Официант / Зал -> Кассиру в будку)
        Expanded(
          flex: 4,
          child: OutlinedButton.icon(
            onPressed: isEmpty || isSubmitting ? null : onSendToBooth,
            icon: const Icon(PhosphorIconsBold.paperPlaneTilt, size: 16, color: Colors.amber),
            label: const Text(
              'В будку',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isEmpty
                    ? (isDark ? Colors.white12 : Colors.black12)
                    : Colors.amber.withValues(alpha: 0.8),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Direct Pay & Close (Оплатить на месте / Закрыть заказ)
        Expanded(
          flex: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEmpty || isSubmitting ? null : onCheckout,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                height: 52,
                decoration: BoxDecoration(
                  color: isEmpty
                      ? (isDark ? Colors.white10 : Colors.black12)
                      : AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.brandPrimary.withValues(alpha: 0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                ),
                child: Center(
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getButtonIcon(),
                              size: 18,
                              color: isEmpty
                                  ? (isDark ? Colors.white24 : Colors.black26)
                                  : Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _getButtonLabel(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                  color: isEmpty
                                      ? (isDark ? Colors.white24 : Colors.black26)
                                      : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
