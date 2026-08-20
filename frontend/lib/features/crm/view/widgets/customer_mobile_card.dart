import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';

class CustomerMobileCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerMobileCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = customer;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (c.phone != null)
                        Text(c.phone!, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ],
                  ),
                ),
                _buildBalanceBadge(c.balance),
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 16, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  onSelected: (val) {
                    if (val == 'pay') onPay();
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'pay', child: Text('Внести оплату/долг')),
                    const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                    const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.danger))),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LTV: ${c.totalSpent.toStringAsFixed(0)} сом (${c.ordersCount} чек.)',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                if (c.bonusBalance > 0)
                  Row(
                    children: [
                      Icon(PhosphorIconsRegular.gift, size: 13, color: AppColors.brandPrimary),
                      const SizedBox(width: 4),
                      Text(
                        '${c.bonusBalance.toStringAsFixed(0)} бонусов',
                        style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  )
                else
                  Text('0 бонусов', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(double balance) {
    Color bg;
    Color fg;
    String text;

    if (balance < -0.01) {
      bg = AppColors.danger.withValues(alpha: 0.12);
      fg = AppColors.danger;
      text = 'Долг: ${balance.abs().toStringAsFixed(0)} с';
    } else if (balance > 0.01) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      text = 'Депозит: +${balance.toStringAsFixed(0)} с';
    } else {
      bg = Colors.grey.withValues(alpha: 0.08);
      fg = Colors.grey;
      text = '0 с';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}
