import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/customer_picker_modal.dart';

class PosCartCustomerBar extends StatelessWidget {
  final Customer? customer;

  const PosCartCustomerBar({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => CustomerPickerModal(
            selectedCustomer: customer,
            onSelect: (c) => context.read<CartBloc>().add(SelectCustomer(c)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: customer != null
              ? AppColors.brandPrimary.withValues(alpha: 0.1)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: customer != null ? AppColors.brandPrimary : border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              customer != null ? PhosphorIconsRegular.userCheck : PhosphorIconsRegular.userPlus,
              size: 16,
              color: customer != null ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                customer != null
                    ? '${customer!.name}${customer!.phone != null ? ' (${customer!.phone})' : ''}'
                    : 'Прикрепить гостя к чеку',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: customer != null ? FontWeight.w700 : FontWeight.w500,
                  color: customer != null ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ),
            ),
            if (customer != null) ...[
              const SizedBox(width: 4),
              if (customer!.bonusBalance > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.gift, size: 10, color: AppColors.brandPrimary),
                      const SizedBox(width: 2),
                      Text(
                        customer!.bonusBalance.toStringAsFixed(0),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (customer!.balance < 0 ? AppColors.error : (customer!.balance > 0 ? AppColors.success : Colors.grey)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  customer!.balance < 0
                      ? 'Долг: ${customer!.balance.abs().toStringAsFixed(0)} с'
                      : customer!.balance > 0
                          ? '+${customer!.balance.toStringAsFixed(0)} с'
                          : '0 с',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: customer!.balance < 0 ? AppColors.error : (customer!.balance > 0 ? AppColors.success : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.read<CartBloc>().add(const SelectCustomer(null)),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(PhosphorIconsRegular.xCircle, size: 16, color: AppColors.error),
                ),
              ),
            ] else ...[
              Icon(PhosphorIconsRegular.caretRight, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ],
          ],
        ),
      ),
    );
  }
}
