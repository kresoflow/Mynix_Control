import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'mini_cart_item.dart';

class DialogMiniCartView extends StatelessWidget {
  final List<MiniCartItem> miniCart;
  final double baseItemPrice;
  final bool isMobile;
  final bool isReadOnly;
  final bool hasVariations;
  final VoidCallback onClearCart;
  final ValueChanged<int> onIncrementQuantity;
  final ValueChanged<int> onDecrementQuantity;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onSubmitCart;

  const DialogMiniCartView({
    super.key,
    required this.miniCart,
    required this.baseItemPrice,
    required this.isMobile,
    required this.isReadOnly,
    required this.hasVariations,
    required this.onClearCart,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
    required this.onRemoveItem,
    required this.onSubmitCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalItems = miniCart.fold(0, (sum, item) => sum + item.quantity);
    final totalCartPrice = miniCart.fold(
      0.0,
      (sum, item) => sum + ((baseItemPrice + item.price) * item.quantity),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.shoppingBag,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Мини-корзина',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const Spacer(),
            if (totalItems > 0)
              TextButton.icon(
                onPressed: onClearCart,
                icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                label: Text(
                  'Очистить всё',
                  style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Flexible(
          fit: isMobile ? FlexFit.loose : FlexFit.tight,
          child: miniCart.isEmpty
              ? (isMobile
                  ? const SizedBox.shrink()
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.shoppingCart,
                            size: 48,
                            color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hasVariations
                                ? 'Выберите опции слева и кликните на нужную вариацию'
                                : 'Соберите конфигурацию и нажмите "Добавить в корзину"',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                    ))
              : ListView.separated(
                  itemCount: miniCart.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = miniCart[index];
                    final itemPrice = baseItemPrice + item.price;
                    return Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.brandPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.variationName,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : null,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                                if (item.modifierNames.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.modifierNames.join(', '),
                                    style: AppTextStyles.caption.copyWith(
                                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  itemPrice.toCurrency(context),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.brandPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  PhosphorIconsRegular.minusCircle,
                                  size: isMobile ? 18 : 22,
                                ),
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => onDecrementQuantity(index),
                              ),
                              Container(
                                width: isMobile ? 18 : 24,
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.quantity}',
                                  style: AppTextStyles.body.copyWith(
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  PhosphorIconsRegular.plusCircle,
                                  size: isMobile ? 18 : 22,
                                ),
                                color: AppColors.brandPrimary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => onIncrementQuantity(index),
                              ),
                              SizedBox(width: isMobile ? 4 : 8),
                              IconButton(
                                icon: Icon(
                                  PhosphorIconsRegular.trash,
                                  size: isMobile ? 16 : 20,
                                ),
                                color: AppColors.danger,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => onRemoveItem(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (!isReadOnly) ...[
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: totalItems > 0
                ? 'В чек (${totalCartPrice.toCurrency(context)})'
                : 'Выберите опции',
            onPressed: totalItems > 0 ? onSubmitCart : null,
            icon: PhosphorIconsRegular.checkCircle,
          ),
        ],
      ],
    );
  }
}
