import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'pos_checkout_panel_payment_methods.dart';
import 'pos_checkout_panel_action_button.dart';

class PosCheckoutPanel extends StatefulWidget {
  const PosCheckoutPanel({super.key});

  @override
  State<PosCheckoutPanel> createState() => _PosCheckoutPanelState();
}

class _PosCheckoutPanelState extends State<PosCheckoutPanel> {
  String _paymentMethod = 'CASH'; // 'CASH', 'TRANSFER', 'DEBT', 'DEPOSIT'
  String _transferProvider = 'dc'; // 'dc', 'alif', 'spitamen', 'other'

  void _handleCheckout(BuildContext context) {
    final note = _paymentMethod == 'TRANSFER'
        ? 'Перевод: ${_getProviderLabel(_transferProvider)}'
        : null;
    context.read<CartBloc>().add(
          CheckoutCart(paymentMethod: _paymentMethod, note: note),
        );
  }

  String _getProviderLabel(String id) {
    switch (id) {
      case 'dc':
        return 'Dushanbe City';
      case 'alif':
        return 'Alif Mobi';
      case 'spitamen':
        return 'Spitamen Pay';
      default:
        return 'Перевод';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: BlocConsumer<CartBloc, CartState>(
        listenWhen: (previous, current) =>
            (!previous.submitSuccess && current.submitSuccess) ||
            (previous.submitError != current.submitError && current.submitError != null),
        listener: (context, state) {
          if (state.submitSuccess) {
            AppToast.showSuccess(
              context,
              'Заказ успешно оформлен',
              subtitle: 'Чек сохранен в истории',
            );
          } else if (state.submitError != null) {
            AppToast.showError(
              context,
              'Ошибка оформления заказа',
              subtitle: state.submitError!.replaceAll('Exception: ', ''),
            );
          }
        },
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosCheckoutPanelPaymentMethods(
                paymentMethod: _paymentMethod,
                transferProvider: _transferProvider,
                onPaymentMethodChanged: (method) => setState(() => _paymentMethod = method),
                onTransferProviderChanged: (provider) => setState(() => _transferProvider = provider),
                customer: state.selectedCustomer,
                cartState: state,
                isDark: isDark,
                border: border,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'К оплате',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    state.payableTotal.toCurrency(context),
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PosCheckoutPanelActionButton(
                isEmpty: state.items.isEmpty,
                isSubmitting: state.isSubmitting,
                paymentMethod: _paymentMethod,
                transferProvider: _transferProvider,
                payableTotal: state.payableTotal,
                onCheckout: () => _handleCheckout(context),
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}
