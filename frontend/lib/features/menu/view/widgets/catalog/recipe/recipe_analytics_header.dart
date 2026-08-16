import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class RecipeAnalyticsHeader extends StatelessWidget {
  final double totalCost;
  final double price;
  final String currency;

  const RecipeAnalyticsHeader({
    super.key,
    required this.totalCost,
    required this.price,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final margin = price - totalCost;
    final marginPercent = price > 0 ? (margin / price) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Себестоимость', '${totalCost.toStringAsFixed(2)} $currency', AppColors.danger),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatColumn('Отпускная цена', '${price.toStringAsFixed(2)} $currency', Theme.of(context).colorScheme.primary),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatColumn(
            'Маржа / Наценка',
            '${margin.toStringAsFixed(2)} $currency (${marginPercent.toStringAsFixed(1)}%)',
            margin >= 0 ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
