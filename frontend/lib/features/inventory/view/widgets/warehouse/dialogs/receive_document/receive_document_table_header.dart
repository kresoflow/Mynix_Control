import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class ReceiveDocumentTableHeader extends StatelessWidget {
  final String currency;
  final int tabIndex; // 1 = Витрина, 2 = Сырье

  const ReceiveDocumentTableHeader({
    super.key,
    required this.currency,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRetail = tabIndex == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10141D) : AppColors.lightBg,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Название
          Expanded(
            child: Text(
              isRetail ? 'Товар витрины' : 'Сырьё / Ингредиент',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Вкус и объем (только для витрины)
          if (isRetail) ...[
            SizedBox(
              width: 85,
              child: Text(
                'Вкус',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 55,
              child: Text(
                'Объем',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 3. Ед. изм.
          SizedBox(
            width: 65,
            child: Text(
              'Ед. изм.',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Кол-во
          SizedBox(
            width: isRetail ? 70 : 80,
            child: Text(
              'Кол-во',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Алерт
          SizedBox(
            width: isRetail ? 60 : 80,
            child: Text(
              'Алерт',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Закупка
          SizedBox(
            width: isRetail ? 80 : 100,
            child: Text(
              'Закупка ($currency)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 7. Продажа (только для витрины)
          if (isRetail) ...[
            SizedBox(
              width: 80,
              child: Text(
                'Продажа ($currency)',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 8. Сумма
          SizedBox(
            width: isRetail ? 80 : 100,
            child: Text(
              'Сумма ($currency)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 44), // Место под кнопку удаления
        ],
      ),
    );
  }
}
