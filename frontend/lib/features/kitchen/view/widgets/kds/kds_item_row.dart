import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class KdsItemRow extends StatelessWidget {
  final dynamic item;
  final bool isDark;

  const KdsItemRow({
    super.key,
    required this.item,
    required this.isDark,
  });

  List<Widget> _buildOptions() {
    if (item['selected_options'] == null) {
      return [];
    }
    try {
      final options = item['selected_options'] as Map;
      final List<String> parts = [];
      if (options['variation'] != null) parts.add(options['variation'].toString());
      if (options['modifiers'] != null) {
        for (var m in (options['modifiers'] as List)) {
          parts.add(m['name'].toString());
        }
      }
      if (parts.isEmpty) return [];
      return [
        const SizedBox(height: 4),
        Text(
          parts.join(', '),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w600,
          ),
        )
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${item['quantity']}x',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['menu_item_name'] ?? 'Item',
                style: AppTextStyles.h2.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  height: 1.3,
                ),
              ),
              ..._buildOptions(),
            ],
          ),
        ),
      ],
    );
  }
}
