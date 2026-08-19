import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _isHovered ? AppColors.brandPrimary.withValues(alpha: 0.5) : border),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Contact
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.tierLevel != 'standard') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (c.tierLevel == 'gold' ? Colors.amber : Colors.blueGrey).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
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
                          fontSize: 12,
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
                  children: [
                    Text(
                      'LTV: ${c.totalSpent.toStringAsFixed(0)} с',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      '${c.ordersCount} заказов • ср. ${c.averageCheck.toStringAsFixed(0)} с',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Bonus Points Pill
              if (c.bonusBalance > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.gift, size: 13, color: AppColors.brandPrimary),
                      const SizedBox(width: 4),
                      Text(
                        c.bonusBalance.toStringAsFixed(0),
                        style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Balance Badge
              _buildBalanceBadge(c.balance),
              const SizedBox(width: 12),

              // Quick Actions
              IconButton(
                icon: Icon(
                  c.balance < 0 ? PhosphorIconsRegular.handCoins : PhosphorIconsRegular.wallet,
                  color: c.balance < 0 ? AppColors.brandPrimary : AppColors.success,
                  size: 20,
                ),
                tooltip: c.balance < 0 ? 'Принять оплату долга' : 'Внести депозит',
                onPressed: widget.onPay,
              ),
              PopupMenuButton<String>(
                icon: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                onSelected: (val) {
                  if (val == 'edit') widget.onEdit();
                  if (val == 'delete') widget.onDelete();
                  if (val == 'history') widget.onTap();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'history', child: Text('История и бонусы')),
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить гостя', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(double balance) {
    Color bg;
    Color fg;
    String text;

    if (balance < -0.01) {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
      text = 'Долг: ${balance.abs().toStringAsFixed(2)} с';
    } else if (balance > 0.01) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      text = 'Депозит: +${balance.toStringAsFixed(2)} с';
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = Colors.grey;
      text = '0.00 с';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
