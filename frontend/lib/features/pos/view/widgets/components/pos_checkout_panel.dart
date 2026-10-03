import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import '../table_picker_modal.dart';
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
          CheckoutCart(
            paymentMethod: _paymentMethod,
            note: note,
            orderSource: 'pos',
            submittingAction: 'checkout',
          ),
        );
  }

  void _handleSendToBooth(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role.toLowerCase() : '';
    final isWaiter = role == 'waiter';
    final targetSource = isWaiter ? 'waiter' : 'dine_in';

    final cartState = context.read<CartBloc>().state;
    if (cartState.tableNumber == null || cartState.tableNumber!.trim().isEmpty) {
      TablePickerModal.show(
        context,
        currentTable: cartState.tableNumber,
        onSelect: (table) {
          if (table != null && table.trim().isNotEmpty) {
            context.read<CartBloc>().add(SetTableNumber(table));
            context.read<CartBloc>().add(
                  CheckoutCart(
                    paymentMethod: 'CASH',
                    tableNumber: table,
                    orderSource: targetSource,
                    submittingAction: 'booth',
                  ),
                );
          }
        },
      );
      return;
    }

    context.read<CartBloc>().add(
          CheckoutCart(
            paymentMethod: 'CASH',
            tableNumber: cartState.tableNumber,
            orderSource: targetSource,
            submittingAction: 'booth',
          ),
        );
  }

  String _getProviderLabel(String id) {
    switch (id) {
      case 'dc':
        return 'DC';
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
            final now = DateTime.now();
            final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc().toIso8601String();
            final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
            context.read<OrdersBloc>().add(LoadOrders(startDate: startOfToday, endDate: endOfToday));
            context.read<ShiftBloc>().add(CheckCurrentShift());

            if (state.lastSubmittedSource == 'waiter') {
              AppToast.showInfo(
                context,
                'Заказ передан в будку',
                subtitle: 'Кассир оповещен и видит счет столика',
              );
            } else if (state.lastSubmittedSource == 'dine_in' || state.lastSubmittedSource == 'hall') {
              AppToast.showSuccess(
                context,
                'Заказ передан на столик',
                subtitle: 'Открыт счет на постоплату в «Столики»',
              );
            } else {
              AppToast.showSuccess(
                context,
                'Заказ успешно оформлен',
                subtitle: 'Чек закрыт и сохранен в истории',
              );
            }
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
              if (state.bonusToSpend > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Сумма: ${state.total.toCurrency(context)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                    Text(
                      'Бонусы: -${state.bonusToSpend.toCurrency(context)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
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
                submittingAction: state.submittingAction,
                paymentMethod: _paymentMethod,
                transferProvider: _transferProvider,
                payableTotal: state.payableTotal,
                tableNumber: state.tableNumber,
                onCheckout: () => _handleCheckout(context),
                onSendToBooth: () => _handleSendToBooth(context),
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}
