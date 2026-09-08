import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';

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
          ? 'Сразу (${_getProviderLabel(transferProvider)})'
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

    // 2. Default Rush/Counter Mode (No table selected): Solid full-width "Оплатить"
    if (!hasTable) {
      return _buildCheckoutButton(context, isFullWidth: true);
    }

    // 3. Table Selected Mode (Cashier / Admin / Owner): Adaptive Dual Action
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty || isSubmitting ? null : onSendToBooth,
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
                        PhosphorIconsBold.paperPlaneTilt,
                        size: 18,
                        color: isEmpty
                            ? (isDark ? Colors.white24 : Colors.black26)
                            : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Оформить заказ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: isEmpty
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendToBoothButton(BuildContext context) {
    final hasTable = tableNumber != null && tableNumber!.trim().isNotEmpty;
    final buttonLabel = hasTable ? 'В зал ($tableNumber)' : 'В зал';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty || isSubmitting ? null : onSendToBooth,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isEmpty
                ? Colors.transparent
                : Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEmpty
                  ? (isDark ? Colors.white12 : Colors.black12)
                  : Colors.amber.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasTable ? PhosphorIconsBold.chair : PhosphorIconsBold.paperPlaneTilt,
                  size: 16,
                  color: isEmpty
                      ? (isDark ? Colors.white24 : Colors.black26)
                      : Colors.amber,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      color: isEmpty
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : Colors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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

  Widget _buildCheckoutButton(
    BuildContext context, {
    required bool isFullWidth,
    bool hasTable = false,
  }) {
    return Material(
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
                          _getButtonLabel(isTableSelected: hasTable),
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
    );
  }
}

