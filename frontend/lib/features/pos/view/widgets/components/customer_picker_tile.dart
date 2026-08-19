import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';

class CustomerPickerTile extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomerPickerTile({
    super.key,
    required this.customer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                  if (customer.phone != null)
                    Text(customer.phone!, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)),
                ],
              ),
            ),
            _buildBalanceBadge(customer.balance),
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
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
      text = 'Долг: ${balance.abs().toStringAsFixed(0)} с';
    } else if (balance > 0.01) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      text = 'Депозит: +${balance.toStringAsFixed(0)} с';
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = Colors.grey;
      text = '0 с';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
