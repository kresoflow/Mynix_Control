import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class PosCartItemTile extends StatefulWidget {
  final dynamic cartItem;
  const PosCartItemTile({super.key, required this.cartItem});

  @override
  State<PosCartItemTile> createState() => _PosCartItemTileState();
}

class _PosCartItemTileState extends State<PosCartItemTile> {
  String _parseSelectedOptions(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr);
      final List<String> parts = [];
      if (map['variation'] != null) {
        String varName = map['variation'].toString();
        varName = varName.replaceAll(widget.cartItem.menuItem.cleanName, '').trim();
        if (widget.cartItem.menuItem.attributesString != null) {
          varName = varName.replaceAll(widget.cartItem.menuItem.attributesString!, '').trim();
        }
        if (varName.isNotEmpty) {
          parts.add(varName);
        }
      }
      if (map['modifiers'] != null) {
        for (var m in map['modifiers']) {
          parts.add(m['name']);
        }
      }
      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.cartItem;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark
                  ? AppColors.darkCardHover
                  : const Color(0xFFF8F9FC))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Name + attributes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.cleanName,
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (item.menuItem.attributesString != null)
                    Text(
                      item.menuItem.attributesString!,
                      style: AppTextStyles.caption,
                    ),
                  if (item.selectedOptionsJson != null)
                    Text(
                      _parseSelectedOptions(item.selectedOptionsJson!),
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Qty controls
            _QtyControl(cartItem: item),

            const SizedBox(width: 12),

            // Line total
            SizedBox(
              width: 64,
              child: Text(
                '${(item.total as num).toCurrency(context)}',
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),

            // Remove — visible on hover
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(PhosphorIconsRegular.x, size: 20),
                color: AppColors.danger,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: 'Удалить',
                onPressed: () =>
                    context.read<CartBloc>().add(RemoveItemFromCart(item.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final dynamic cartItem;
  const _QtyControl({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: PhosphorIconsRegular.minus,
            onPressed: cartItem.quantity > 1
                ? () => context
                    .read<CartBloc>()
                    .add(UpdateCartItemQuantity(cartItem.id, cartItem.quantity - 1))
                : () => context
                    .read<CartBloc>()
                    .add(RemoveItemFromCart(cartItem.id)),
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          _QtyBtn(
            icon: PhosphorIconsRegular.plus,
            onPressed: () => context
                .read<CartBloc>()
                .add(UpdateCartItemQuantity(cartItem.id, cartItem.quantity + 1)),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _QtyBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, size: 18, color: AppColors.darkSubtext),
      ),
    );
  }
}
