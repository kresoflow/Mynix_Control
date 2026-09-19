import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';

class PosCheckoutPanelActionButton extends StatelessWidget {
  final bool isEmpty;
  final bool isSubmitting;
  final String paymentMethod;
  final String transferProvider;
  final double payableTotal;
  final String? tableNumber;
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
    this.tableNumber,
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

  String _getButtonLabel({bool isTableSelected = false}) {
    if (paymentMethod == 'TRANSFER') {
      return isTableSelected
          ? 'Оплатить (${_getProviderLabel(transferProvider)})'
          : 'Оплатить (${_getProviderLabel(transferProvider)})';
    } else if (paymentMethod == 'DEBT') {
      return 'В долг';
    } else if (paymentMethod == 'DEPOSIT') {
      return 'С депозита';
    }
    return isTableSelected ? 'Оплатить сразу' : 'Оплатить';
  }

  IconData _getButtonIcon() {
    if (paymentMethod == 'TRANSFER') return PhosphorIconsRegular.qrCode;
    if (paymentMethod == 'DEBT') return PhosphorIconsRegular.handCoins;
    if (paymentMethod == 'DEPOSIT') return PhosphorIconsRegular.wallet;
    return PhosphorIconsRegular.creditCard;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role.toLowerCase() : '';
    final isWaiter = role == 'waiter';
    final hasTable = tableNumber != null && tableNumber!.trim().isNotEmpty;

    // 1. Waiter mode: Solid primary full-width "Оформить заказ"
    if (isWaiter) {
      return _buildWaiterPrimaryButton(context);
    }

    // 2. Counter Mode (No table selected): Solid full-width "Оплатить"
    if (!hasTable) {
      return _buildCheckoutButton(context, isFullWidth: true);
    }

    // 3. Table Selected Mode (Cashier / Admin): Dual Action
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildSendToBoothButton(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: _buildCheckoutButton(context, isFullWidth: false, hasTable: true),
        ),
      ],
    );
  }

  Widget _buildWaiterPrimaryButton(BuildContext context) {
    return _buildCtaContainer(
      context: context,
      onTap: onSendToBooth,
      color: AppColors.brandPrimary,
      textColor: Colors.white,
      icon: PhosphorIconsBold.paperPlaneTilt,
      label: 'Оформить заказ',
      isSubmitting: isSubmitting,
      isPrimary: true,
    );
  }

  Widget _buildSendToBoothButton(BuildContext context) {
    final primary = AppColors.brandPrimary;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fg = isDark ? AppColors.darkText : primary;

    return _buildCtaContainer(
      context: context,
      onTap: onSendToBooth,
      color: bg,
      borderColor: border,
      textColor: fg,
      icon: PhosphorIconsBold.chair,
      label: 'В стол (без оплаты)',
      isSubmitting: isSubmitting,
      isPrimary: false,
    );
  }

  Widget _buildCheckoutButton(
    BuildContext context, {
    required bool isFullWidth,
    bool hasTable = false,
  }) {
    return _buildCtaContainer(
      context: context,
      onTap: onCheckout,
      color: AppColors.brandPrimary,
      textColor: Colors.white,
      icon: _getButtonIcon(),
      label: _getButtonLabel(isTableSelected: hasTable),
      isSubmitting: isSubmitting,
      isPrimary: true,
    );
  }

  Widget _buildCtaContainer({
    required BuildContext context,
    required VoidCallback onTap,
    required Color color,
    Color? borderColor,
    required Color textColor,
    required IconData icon,
    required String label,
    required bool isSubmitting,
    required bool isPrimary,
  }) {
    final disabledBg = isPrimary ? (isDark ? Colors.white10 : Colors.black12) : Colors.transparent;
    final disabledBorder = isDark ? Colors.white12 : Colors.black12;
    final disabledFg = isDark ? Colors.white24 : Colors.black26;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty || isSubmitting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isEmpty ? disabledBg : color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEmpty
                  ? disabledBorder
                  : (borderColor ?? Colors.transparent),
              width: 1.2,
            ),
            boxShadow: (isEmpty || !isPrimary) ? null : AppShadows.buttonGlow(AppColors.brandPrimary),
          ),
          child: Center(
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: isEmpty ? disabledFg : textColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: isEmpty ? disabledFg : textColor,
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
    );
  }
}
