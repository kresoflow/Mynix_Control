import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/quick_stock_action_dialog.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class HoverableStockItem extends StatefulWidget {
  final Ingredient item;
  final bool isLowStock;

  const HoverableStockItem({super.key, required this.item, required this.isLowStock});

  @override
  State<HoverableStockItem> createState() => _HoverableStockItemState();
}

class _HoverableStockItemState extends State<HoverableStockItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isLowStock
              ? AppColors.danger.withValues(alpha: _isHovering ? 0.08 : 0.04)
              : (_isHovering ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              widget.item.unit,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          title: Text(
            widget.item.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isLowStock ? AppColors.danger.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Остаток: ${widget.item.currentStock.toInt()} ${widget.item.unit}',
                      style: TextStyle(
                        color: widget.isLowStock ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Мин: ${widget.item.minStockAlert.toInt()} ${widget.item.unit}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.item.costPerUnit.toStringAsFixed(2)} с / ${widget.item.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Σ: ${(widget.item.currentStock * widget.item.costPerUnit).toCurrency(context)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  QuickStockActionDialog.show(
                    context,
                    item: widget.item,
                    actionType: value,
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'receipt',
                    child: ListTile(
                      leading: Icon(PhosphorIconsRegular.download, color: AppColors.success),
                      title: Text('Быстрый приход', style: TextStyle(fontWeight: FontWeight.w500)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'write_off',
                    child: ListTile(
                      leading: Icon(PhosphorIconsRegular.upload, color: AppColors.danger),
                      title: Text('Быстрое списание', style: TextStyle(fontWeight: FontWeight.w500)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
