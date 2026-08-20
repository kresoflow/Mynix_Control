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
  final bool isDark;

  const PosCheckoutPanelActionButton({
    super.key,
    required this.isEmpty,
    required this.isSubmitting,
    required this.paymentMethod,
    required this.transferProvider,
    required this.payableTotal,
    required this.onCheckout,
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
      return 'ОПЛАТИТЬ (${_getProviderLabel(transferProvider)})';
    } else if (paymentMethod == 'DEBT') {
      return 'ОФОРМИТЬ В ДОЛГ';
    } else if (paymentMethod == 'DEPOSIT') {
      return 'СПИСАТЬ С ДЕПОЗИТА';
    }
    return 'ОПЛАТИТЬ ЗАКАЗ';
  }

  IconData _getButtonIcon() {
    if (paymentMethod == 'TRANSFER') return PhosphorIconsRegular.qrCode;
    if (paymentMethod == 'DEBT') return PhosphorIconsRegular.handCoins;
    if (paymentMethod == 'DEPOSIT') return PhosphorIconsRegular.wallet;
    return PhosphorIconsRegular.creditCard;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty || isSubmitting ? null : onCheckout,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 56,
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
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getButtonIcon(),
                        size: 20,
                        color: isEmpty ? (isDark ? Colors.white24 : Colors.black26) : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getButtonLabel(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isEmpty ? (isDark ? Colors.white24 : Colors.black26) : Colors.black,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
