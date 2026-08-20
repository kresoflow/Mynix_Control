import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dialog_variations_list.dart';
import 'dialog_modifier_groups_list.dart';
import 'dialog_mini_cart_view.dart';
import 'mini_cart_item.dart';

class DialogModifiersBody extends StatelessWidget {
  final MenuItem item;
  final List<dynamic> variations;
  final List<dynamic> modifierGroups;
  final Map<int, Set<int>> selectedModifiers;
  final List<MiniCartItem> miniCart;
  final bool isReadOnly;
  final double additionalModifiersPrice;
  final ValueChanged<int?> onSelectVariation;
  final Function(int groupIndex, int modIndex, bool isSelected) onToggleModifier;
  final VoidCallback onClearCart;
  final ValueChanged<int> onIncrementQuantity;
  final ValueChanged<int> onDecrementQuantity;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onSubmitCart;

  const DialogModifiersBody({
    super.key,
    required this.item,
    required this.variations,
    required this.modifierGroups,
    required this.selectedModifiers,
    required this.miniCart,
    required this.isReadOnly,
    required this.additionalModifiersPrice,
    required this.onSelectVariation,
    required this.onToggleModifier,
    required this.onClearCart,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
    required this.onRemoveItem,
    required this.onSubmitCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final leftContent = SingleChildScrollView(
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DialogVariationsList(
                variations: variations,
                basePrice: item.price,
                additionalModifiersPrice: additionalModifiersPrice,
                onSelectVariation: onSelectVariation,
              ),
              if (variations.isEmpty) ...[
                AppGhostButton(
                  label: 'Добавить в корзину • ${(item.price + additionalModifiersPrice).toCurrency(context)}',
                  onPressed: () => onSelectVariation(null),
                  icon: PhosphorIconsRegular.plusCircle,
                ),
                const SizedBox(height: 24),
              ],
              DialogModifierGroupsList(
                modifierGroups: modifierGroups,
                selectedModifiers: selectedModifiers,
                onToggleModifier: onToggleModifier,
              ),
            ],
          ),
        );

        final rightContent = DialogMiniCartView(
          miniCart: miniCart,
          baseItemPrice: item.price,
          isMobile: isMobile,
          isReadOnly: isReadOnly,
          hasVariations: variations.isNotEmpty,
          onClearCart: onClearCart,
          onIncrementQuantity: onIncrementQuantity,
          onDecrementQuantity: onDecrementQuantity,
          onRemoveItem: onRemoveItem,
          onSubmitCart: onSubmitCart,
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: leftContent),
              Container(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                margin: const EdgeInsets.only(top: 16, bottom: 8),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                child: rightContent,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: leftContent),
            Container(
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(flex: 4, child: rightContent),
          ],
        );
      },
    );
  }
}
