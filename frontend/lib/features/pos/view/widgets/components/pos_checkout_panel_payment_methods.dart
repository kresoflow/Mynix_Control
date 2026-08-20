import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/customer_picker_modal.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGuestChip(context),
            const SizedBox(width: 8),
            _buildMethodTab('CASH', 'Наличные', PhosphorIconsRegular.money),
            const SizedBox(width: 8),
            _buildMethodTab('TRANSFER', 'Перевод', PhosphorIconsRegular.qrCode),
            if (customer != null) ...[
              const SizedBox(width: 8),
              _buildMethodTab(
                customer.balance > 0 ? 'DEPOSIT' : 'DEBT',
                customer.balance > 0 ? 'Депозит' : 'В долг',
                customer.balance > 0 ? PhosphorIconsRegular.wallet : PhosphorIconsRegular.handCoins,
              ),
            ],
          ],
        ),
        if (paymentMethod == 'TRANSFER') ...[
          const SizedBox(height: 8),
          _buildTransferBanksRow(),
        ],
      ],
    );
  }

  Widget _buildGuestChip(BuildContext context) {
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
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (bonus > 0) ...[
            const SizedBox(width: 4),
            Text('🎁${bonus.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () => context.read<CartBloc>().add(const SelectCustomer(null)),
            child: Icon(PhosphorIconsRegular.xCircle, size: 14, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String method, String label, IconData icon) {
    final isSelected = paymentMethod == method;
    final activeColor = AppColors.brandPrimary;
    final inactiveColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      onTap: () => onPaymentMethodChanged(method),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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

  Widget _buildTransferBanksRow() {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: providers.map((p) {
          final isSelected = transferProvider == p.id;
          return Expanded(
            child: InkWell(
              onTap: () => onTransferProviderChanged(p.id),
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
