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
        varName = varName.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0];
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
          if (m['name'] != null) {
            final String mName = m['name'].toString().split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0].trim();
            if (mName.isNotEmpty) {
              parts.add(mName);
            }
          }
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? AppColors.darkCardHover : AppColors.lightBg)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name + attributes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.menuItem.cleanName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.menuItem.attributesString != null)
                    Text(
                      item.menuItem.attributesString!,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.selectedOptionsJson != null)
                    Text(
                      _parseSelectedOptions(item.selectedOptionsJson!),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPrimary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Qty controls
            _QtyControl(cartItem: item),

            const SizedBox(width: 6),

            // Line total
            SizedBox(
              width: 54,
              child: Text(
                (item.total as num).toCurrency(context),
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Remove button
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                icon: const Icon(PhosphorIconsRegular.x, size: 14),
                color: AppColors.danger.withValues(alpha: _hovered ? 1.0 : 0.4),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
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
            width: 26,
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
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
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 24,
        height: 28,
        child: Icon(icon, size: 12, color: AppColors.darkSubtext),
      ),
    );
  }
}
