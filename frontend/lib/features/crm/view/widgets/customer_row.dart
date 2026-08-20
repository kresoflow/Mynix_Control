import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'customer_mobile_card.dart';
import 'customer_balance_badge.dart';

class CustomerRow extends StatefulWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerRow({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<CustomerRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (isMobile) {
      return CustomerMobileCard(
        customer: widget.customer,
        onTap: widget.onTap,
        onPay: widget.onPay,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _isHovered
        ? (isDark ? AppColors.darkCard : AppColors.lightCard)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final c = widget.customer;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isHovered ? AppColors.brandPrimary.withValues(alpha: 0.4) : border),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Contact
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.tierLevel != 'standard') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: (c.tierLevel == 'gold' ? Colors.amber : Colors.blueGrey).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.tierLevel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: c.tierLevel == 'gold' ? Colors.amber : Colors.blueGrey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (c.phone != null)
                      Text(
                        c.phone!,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // LTV & Purchases
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${c.totalSpent.toStringAsFixed(0)} с',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      '${c.ordersCount} заказов • ср. ${c.averageCheck.toStringAsFixed(0)} с',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Bonus Points Pill
              SizedBox(
                width: 90,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: c.bonusBalance > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsRegular.gift, size: 12, color: AppColors.brandPrimary),
                              const SizedBox(width: 4),
                              Text(
                                c.bonusBalance.toStringAsFixed(0),
                                style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : Text('0', style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),

              // Balance Badge
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomerBalanceBadge(balance: c.balance),
                ),
              ),
              const SizedBox(width: 8),

              // Quick Actions
              SizedBox(
                width: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: widget.onPay,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          c.balance < 0 ? PhosphorIconsRegular.handCoins : PhosphorIconsRegular.wallet,
                          color: c.balance < 0 ? AppColors.brandPrimary : AppColors.success,
                          size: 18,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onSelected: (val) {
                        if (val == 'edit') widget.onEdit();
                        if (val == 'delete') widget.onDelete();
                        if (val == 'history') widget.onTap();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'history', child: Text('История и бонусы')),
                        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                        const PopupMenuItem(value: 'delete', child: Text('Удалить гостя', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
