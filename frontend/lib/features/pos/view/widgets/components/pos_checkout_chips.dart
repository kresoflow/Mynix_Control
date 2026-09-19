import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:kreso_frontend/features/pos/view/widgets/customer_picker_modal.dart';
import 'package:kreso_frontend/features/pos/view/widgets/table_picker_modal.dart';

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
    final primary = AppColors.brandPrimary;
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
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.chair, size: 15, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Столик',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: isDark ? 0.5 : 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsBold.chair, size: 15, color: primary),
          const SizedBox(width: 6),
          Flexible(
            child: InkWell(
              onTap: () {
                TablePickerModal.show(
                  context,
                  currentTable: table,
                  onSelect: (t) => context.read<CartBloc>().add(SetTableNumber(t)),
                );
              },
              child: Text(
                table,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => context.read<CartBloc>().add(const SetTableNumber(null)),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(PhosphorIconsRegular.x, size: 13, color: primary),
            ),
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
    final primary = AppColors.brandPrimary;

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
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.userPlus, size: 15, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Гость',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bonus = (customer.bonusBalance as num?)?.toDouble() ?? 0.0;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: isDark ? 0.5 : 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.userCheck, size: 15, color: primary),
          const SizedBox(width: 6),
          Flexible(
            child: InkWell(
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (bonus > 0) ...[
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.gift, size: 11, color: primary),
                const SizedBox(width: 2),
                Text(
                  bonus.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primary),
                ),
              ],
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: () => context.read<CartBloc>().add(const SelectCustomer(null)),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(PhosphorIconsRegular.x, size: 13, color: primary),
            ),
          ),
        ],
      ),
    );
  }
}
