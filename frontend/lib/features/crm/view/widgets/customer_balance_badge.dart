import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class CustomerBalanceBadge extends StatelessWidget {
  final double balance;

  const CustomerBalanceBadge({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
        maxLines: 1,
      ),
    );
  }
}
