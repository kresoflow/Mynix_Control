import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
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
    final activeCount = context.watch<PosTabCubit>().state.activeTablesCount;
    final hasActiveTables = activeCount > 0;

    if (table == null || table.isEmpty) {
      return Tooltip(
        message: hasActiveTables
            ? 'Активных счетов в зале: $activeCount. Нажмите для выбора стола.'
            : 'Выбрать столик для заказа',
        child: InkWell(
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
              color: hasActiveTables
                  ? primary.withValues(alpha: isDark ? 0.12 : 0.08)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasActiveTables
                    ? primary.withValues(alpha: isDark ? 0.45 : 0.5)
                    : border,
                width: hasActiveTables ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasActiveTables ? PhosphorIconsBold.chair : PhosphorIconsRegular.chair,
                  size: 15,
                  color: hasActiveTables ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Столик',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hasActiveTables ? FontWeight.w700 : FontWeight.w600,
                      color: hasActiveTables
                          ? (isDark ? AppColors.darkText : primary)
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasActiveTables) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
