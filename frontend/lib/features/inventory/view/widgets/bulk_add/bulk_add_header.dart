import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class BulkAddHeader extends StatelessWidget {
  const BulkAddHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(PhosphorIconsRegular.listBullets, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'Массовое добавление',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.x,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }
}
