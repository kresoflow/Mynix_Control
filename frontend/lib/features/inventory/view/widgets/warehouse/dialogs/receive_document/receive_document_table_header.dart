// ==============================================================================
// МОДУЛЬ: Склад / Заголовок таблицы приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Заголовок колонок таблицы приходной накладной.
/// Пропорции и размеры колонок синхронизированы со строками ReceiveDocumentItemRow.
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

    final headerStyle = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Порядковый номер
          SizedBox(
            width: 32,
            child: Text(
              '№',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 8),

          // 2. Название номенклатуры
          Expanded(
            flex: isRetail ? 3 : 5,
            child: Text(
              isRetail ? 'Товар витрины' : 'Сырьё / Ингредиент',
              style: headerStyle,
            ),
          ),

          // 3. Вкус и объем (только для витрины)
          if (isRetail) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text('Вкус', style: headerStyle),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Text('Объем', style: headerStyle),
            ),
          ],
          const SizedBox(width: 8),

          // 4. Единица измерения
          SizedBox(
            width: 85,
            child: Text('Ед. изм.', style: headerStyle),
          ),
          const SizedBox(width: 8),

          // 5. Количество
          SizedBox(
            width: 85,
            child: Text(
              'Кол-во',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 8),

          // 6. Минимальный остаток (алерт)
          SizedBox(
            width: 80,
            child: Text(
              'Алерт',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 8),

          // 7. Цена закупки
          SizedBox(
            width: 105,
            child: Text(
              'Закупка ($currency)',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),

          // 8. Цена продажи (только для витрины)
          if (isRetail) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 105,
              child: Text(
                'Продажа ($currency)',
                textAlign: TextAlign.right,
                style: headerStyle,
              ),
            ),
          ],
          const SizedBox(width: 8),

          // 9. Сумма позиции
          SizedBox(
            width: 95,
            child: Text(
              'Сумма ($currency)',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 8),

          // 10. Место под кнопку действия (удаление)
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
