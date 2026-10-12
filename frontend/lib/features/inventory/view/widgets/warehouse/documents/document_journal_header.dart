// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ==============================================================================
// 2. ШАПКА ЖУРНАЛА СКЛАДСКИХ ДОКУМЕНТОВ
// ==============================================================================
/// [ИНВАРИАНТ] Заголовок колонок таблицы складских документов.
class DocumentJournalHeader extends StatelessWidget {
  const DocumentJournalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCardHover,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text('ID', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('ДАТА', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('ТИП', style: textStyle),
          ),
          Expanded(
            flex: 3,
            child: Text('ПОСТАВЩИК / КОММЕНТАРИЙ', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('СУММА', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('СТАТУС', style: textStyle),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
