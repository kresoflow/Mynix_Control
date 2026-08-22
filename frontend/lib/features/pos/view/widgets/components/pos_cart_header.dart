import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class PosCartHeader extends StatelessWidget {
  const PosCartHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.receipt,
            size: 20,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(width: 10),
          Text('Текущий заказ', style: AppTextStyles.h3),
          const Spacer(),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.heldCarts.isNotEmpty)
                    _buildDraftsButton(context, state.heldCarts, isDark),
                  if (state.items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${state.items.length} поз.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.pause, size: 20),
                      color: AppColors.brandSecondary,
                      tooltip: 'Отложить заказ',
                      onPressed: () {
                        context.read<CartBloc>().add(const HoldCurrentCart());
                      },
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.trash, size: 20),
                      color: AppColors.darkSubtext,
                      tooltip: 'Очистить заказ',
                      onPressed: () => _confirmClearCart(context, state.items.length),
                    ),
                  ],
                  if (MediaQuery.of(context).size.width < 768) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x, size: 24),
                      color: AppColors.darkSubtext,
                      tooltip: 'Закрыть',
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, int itemCount) {
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Очистить заказ?',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Вы действительно хотите удалить все $itemCount поз. из текущего чека?\nЭто действие нельзя отменить.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(ctx),
          ),
          AppDangerButton(
            label: 'Очистить чек',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              context.read<CartBloc>().add(ClearCart());
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsButton(BuildContext context, Map<String, List> heldCarts, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'Отложенные чеки',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brandSecondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.brandSecondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.folderOpen, size: 18, color: AppColors.brandSecondary),
            const SizedBox(width: 4),
            Text(
              '${heldCarts.length}',
              style: AppTextStyles.caption.copyWith(color: AppColors.brandSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      onSelected: (cartId) {
        context.read<CartBloc>().add(ResumeHeldCart(cartId));
      },
      itemBuilder: (context) {
        return heldCarts.entries.map((entry) {
          final count = entry.value.length;
          final total = entry.value.fold(0.0, (sum, item) => sum + item.total);
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    Text('$count поз.', style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
                  ],
                ),
                Text(total.toCurrency(context), style: AppTextStyles.body.copyWith(color: AppColors.brandPrimary)),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
