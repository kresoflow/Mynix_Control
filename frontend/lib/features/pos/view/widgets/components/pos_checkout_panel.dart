import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/features/pos/view/widgets/customer_picker_modal.dart';

class PosCheckoutPanel extends StatefulWidget {
  const PosCheckoutPanel({super.key});

  @override
  State<PosCheckoutPanel> createState() => _PosCheckoutPanelState();
}

class _PosCheckoutPanelState extends State<PosCheckoutPanel> {
  String _paymentMethod = 'CASH'; // 'CASH', 'TRANSFER', 'DEBT', 'DEPOSIT'
  String _transferProvider = 'alif'; // 'dc', 'alif', 'spitamen', 'other'

  static const _providers = [
    (id: 'dc', label: 'DC'),
    (id: 'alif', label: 'Алиф'),
    (id: 'spitamen', label: 'Спитамен'),
    (id: 'other', label: 'Другой'),
  ];

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

  String _getButtonLabel(double total) {
    if (_paymentMethod == 'TRANSFER') {
      return 'ОПЛАТИТЬ (${_getProviderLabel(_transferProvider)})';
    } else if (_paymentMethod == 'DEBT') {
      return 'ОФОРМИТЬ В ДОЛГ';
    } else if (_paymentMethod == 'DEPOSIT') {
      return 'СПИСАТЬ С ДЕПОЗИТА';
    }
    return 'ОПЛАТИТЬ ЗАКАЗ';
  }

  IconData _getButtonIcon() {
    if (_paymentMethod == 'TRANSFER') return PhosphorIconsRegular.qrCode;
    if (_paymentMethod == 'DEBT') return PhosphorIconsRegular.handCoins;
    if (_paymentMethod == 'DEPOSIT') return PhosphorIconsRegular.wallet;
    return PhosphorIconsRegular.creditCard;
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
          final isEmpty = state.items.isEmpty;
          final customer = state.selectedCustomer;
          final isSubmitting = state.isSubmitting;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Compact Non-Stretched Pills: Guest + Payment Method Tabs ──
              Row(
                children: [
                  // Compact Guest Chip (same compact style)
                  _buildCompactGuestChip(context, customer, state, isDark, border),
                  const SizedBox(width: 8),

                  // Compact Cash Chip (not stretched)
                  _buildPaymentMethodTab(
                    method: 'CASH',
                    label: 'Наличные',
                    icon: PhosphorIconsRegular.money,
                    isSelected: _paymentMethod == 'CASH',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Compact Transfer Chip (not stretched)
                  _buildPaymentMethodTab(
                    method: 'TRANSFER',
                    label: 'Перевод',
                    icon: PhosphorIconsRegular.qrCode,
                    isSelected: _paymentMethod == 'TRANSFER',
                    isDark: isDark,
                  ),

                  // Compact Debt / Deposit Chip (if customer selected)
                  if (customer != null) ...[
                    const SizedBox(width: 8),
                    _buildPaymentMethodTab(
                      method: customer.balance > 0 ? 'DEPOSIT' : 'DEBT',
                      label: customer.balance > 0 ? 'Депозит' : 'В долг',
                      icon: customer.balance > 0 ? PhosphorIconsRegular.wallet : PhosphorIconsRegular.handCoins,
                      isSelected: _paymentMethod == 'DEBT' || _paymentMethod == 'DEPOSIT',
                      isDark: isDark,
                    ),
                  ],
                ],
              ),

              // ── 2. Compact Transfer Banks Row (DC / Алиф / Спитамен) ───────
              if (_paymentMethod == 'TRANSFER') ...[
                const SizedBox(height: 8),
                _buildTransferProvidersRow(isDark, border),
              ],

              const SizedBox(height: 10),

              // ── 3. Total Amount Row ────────────────────────────────────────
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

              // ── 4. Main Prominent Pay Button (Height: 56px, Big Bold CTA) ──
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEmpty || isSubmitting
                      ? null
                      : () {
                          final note = _paymentMethod == 'TRANSFER'
                              ? 'Перевод: ${_getProviderLabel(_transferProvider)}'
                              : null;
                          context.read<CartBloc>().add(
                                CheckoutCart(paymentMethod: _paymentMethod, note: note),
                              );
                        },
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
                                  _getButtonLabel(state.payableTotal),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactGuestChip(
    BuildContext context,
    dynamic customer,
    CartState state,
    bool isDark,
    Color border,
  ) {
    if (customer == null) {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => CustomerPickerModal(
              selectedCustomer: null,
              onSelect: (c) => context.read<CartBloc>().add(SelectCustomer(c)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.userPlus, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 6),
              Text(
                'Гость',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bonus = (customer.bonusBalance as num?)?.toDouble() ?? 0.0;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.userCheck, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => CustomerPickerModal(
                  selectedCustomer: customer,
                  onSelect: (c) => context.read<CartBloc>().add(SelectCustomer(c)),
                ),
              );
            },
            child: Text(
              customer.name.toString(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (bonus > 0) ...[
            const SizedBox(width: 4),
            Text(
              '🎁${bonus.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () => context.read<CartBloc>().add(const SelectCustomer(null)),
            child: Icon(PhosphorIconsRegular.xCircle, size: 14, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTab({
    required String method,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = AppColors.brandPrimary;
    final inactiveColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : inactiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferProvidersRow(bool isDark, Color border) {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: _providers.map((p) {
          final isSelected = _transferProvider == p.id;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _transferProvider = p.id),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText),
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
