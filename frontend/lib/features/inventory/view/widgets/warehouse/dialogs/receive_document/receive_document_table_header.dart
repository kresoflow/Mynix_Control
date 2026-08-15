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
          // Название (просторная колонка)
          Expanded(
            flex: isRetail ? 3 : 5,
            child: Text(
              isRetail ? 'Товар витрины' : 'Сырьё / Ингредиент',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Вкус и объем только для Витрины
          if (isRetail) ...[
            Expanded(
              flex: 2,
              child: Text(
                'Вкус',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
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

          // Ед. изм.
          Expanded(
            flex: 1,
            child: Text(
              'Ед. изм.',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Кол-во
          Expanded(
            flex: 1,
            child: Text(
              'Кол-во',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Алерт
          Expanded(
            flex: 1,
            child: Text(
              'Алерт',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Закупка
          Expanded(
            flex: 1,
            child: Text(
              'Закупка ($currency)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Продажа только для витрины
          if (isRetail) ...[
            Expanded(
              flex: 1,
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

          // Сумма
          Expanded(
            flex: 1,
            child: Text(
              'Сумма ($currency)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 44), // Место под кнопку корзины
        ],
      ),
    );
  }
}
