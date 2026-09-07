import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/customer_picker_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/table_picker_modal.dart';

class PosTableChip extends StatelessWidget {
  final CartState cartState;
  final bool isDark;
  final Color border;

  const PosTableChip({
    super.key,
    required this.cartState,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final table = cartState.tableNumber;
    if (table == null || table.isEmpty) {
      return InkWell(
        onTap: () {
          TablePickerModal.show(
            context,
            currentTable: null,
            onSelect: (t) => context.read<CartBloc>().add(SetTableNumber(t)),
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
              Icon(PhosphorIconsRegular.chair, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 6),
              Text(
                'Столик',
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
          Icon(PhosphorIconsBold.chair, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              TablePickerModal.show(
                context,
                currentTable: table,
                onSelect: (t) => context.read<CartBloc>().add(SetTableNumber(t)),
              );
            },
            child: Text(
              table,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => context.read<CartBloc>().add(const SetTableNumber(null)),
            child: const Icon(PhosphorIconsRegular.xCircle, size: 14, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class PosGuestChip extends StatelessWidget {
  final dynamic customer;
  final bool isDark;
  final Color border;

  const PosGuestChip({
    super.key,
    required this.customer,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.gift, size: 11, color: AppColors.brandPrimary),
                const SizedBox(width: 2),
                Text(
                  bonus.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                ),
              ],
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () => context.read<CartBloc>().add(const SelectCustomer(null)),
            child: const Icon(PhosphorIconsRegular.xCircle, size: 14, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
