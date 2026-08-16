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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? AppColors.darkCardHover : AppColors.lightBg)
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
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary, fontSize: isMobile ? 10 : null),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Qty controls
            _QtyControl(cartItem: item, isMobile: isMobile),

            SizedBox(width: isMobile ? 8 : 12),

            // Line total
            SizedBox(
              width: isMobile ? 54 : 64,
              child: Text(
                (item.total as num).toCurrency(context),
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),

            // Remove — always visible on mobile, visible on hover on desktop
            if (isMobile)
              IconButton(
                icon: const Icon(PhosphorIconsRegular.x, size: 16),
                color: AppColors.danger,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Удалить',
                onPressed: () =>
                    context.read<CartBloc>().add(RemoveItemFromCart(item.id)),
              )
            else
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
  final bool isMobile;
  const _QtyControl({required this.cartItem, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: isMobile ? 36 : 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: PhosphorIconsRegular.minus,
            isMobile: isMobile,
            onPressed: cartItem.quantity > 1
                ? () => context
                    .read<CartBloc>()
                    .add(UpdateCartItemQuantity(cartItem.id, cartItem.quantity - 1))
                : () => context
                    .read<CartBloc>()
                    .add(RemoveItemFromCart(cartItem.id)),
          ),
          Container(
            width: isMobile ? 32 : 48,
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          _QtyBtn(
            icon: PhosphorIconsRegular.plus,
            isMobile: isMobile,
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
  final bool isMobile;
  const _QtyBtn({required this.icon, required this.onPressed, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      child: SizedBox(
        width: isMobile ? 36 : 48,
        height: isMobile ? 36 : 48,
        child: Icon(icon, size: isMobile ? 16 : 18, color: AppColors.darkSubtext),
      ),
    );
  }
}
