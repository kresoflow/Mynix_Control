import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'pos_checkout_chips.dart';

class PosCheckoutPanelPaymentMethods extends StatelessWidget {
  final String paymentMethod;
  final String transferProvider;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String> onTransferProviderChanged;
  final dynamic customer;
  final CartState cartState;
  final bool isDark;
  final Color border;

  static const providers = [
    (id: 'dc', label: 'DC'),
    (id: 'alif', label: 'Алиф'),
    (id: 'spitamen', label: 'Спитамен'),
    (id: 'other', label: 'Другой'),
  ];

  const PosCheckoutPanelPaymentMethods({
    super.key,
    required this.paymentMethod,
    required this.transferProvider,
    required this.onPaymentMethodChanged,
    required this.onTransferProviderChanged,
    required this.customer,
    required this.cartState,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final showGuest = context.watch<PosSettingsCubit>().state.showGuestOption;
    final authState = context.watch<AuthBloc>().state;
    final isWaiter = authState is AuthAuthenticated && authState.role.toLowerCase() == 'waiter';

    // In Waiter mode: Only show Table selection (and Guest if enabled), hide payment tabs
    if (isWaiter) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PosTableChip(cartState: cartState, isDark: isDark, border: border),
            if (showGuest || customer != null) ...[
              const SizedBox(width: 8),
              PosGuestChip(customer: customer, isDark: isDark, border: border),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tier 1: Order Context (Table & Guest) ──────────────────────
        Row(
          children: [
            Expanded(
              child: PosTableChip(cartState: cartState, isDark: isDark, border: border),
            ),
            if (showGuest || customer != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: PosGuestChip(customer: customer, isDark: isDark, border: border),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // ── Tier 2: Payment Methods (Unified AppSegmentedControl) ──────
        AppSegmentedControl<String>(
          selectedValue: paymentMethod,
          onValueChanged: onPaymentMethodChanged,
          size: AppSegmentedSize.md,
          isExpanded: true,
          items: [
            const AppSegmentedItem(value: 'CASH', label: 'Наличные', icon: PhosphorIconsRegular.money),
            const AppSegmentedItem(value: 'TRANSFER', label: 'Перевод', icon: PhosphorIconsRegular.qrCode),
            if (customer != null)
              AppSegmentedItem(
                value: customer.balance > 0 ? 'DEPOSIT' : 'DEBT',
                label: customer.balance > 0 ? 'Депозит' : 'В долг',
                icon: customer.balance > 0 ? PhosphorIconsRegular.wallet : PhosphorIconsRegular.handCoins,
              ),
          ],
        ),

        // ── Tier 3: Bank selector (if Transfer) ────────────────────────
        if (paymentMethod == 'TRANSFER') ...[
          const SizedBox(height: 8),
          AppSegmentedControl<String>(
            selectedValue: transferProvider,
            onValueChanged: onTransferProviderChanged,
            size: AppSegmentedSize.sm,
            isExpanded: true,
            items: providers.map((p) => AppSegmentedItem<String>(value: p.id, label: p.label)).toList(),
          ),
        ],
      ],
    );
  }
}
