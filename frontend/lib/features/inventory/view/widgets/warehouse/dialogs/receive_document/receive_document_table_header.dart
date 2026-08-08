import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class ReceiveDocumentTableHeader extends StatelessWidget {
  final String currency;

  const ReceiveDocumentTableHeader({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Товар / Сырье', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Вкус', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Объем', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Ед. изм.', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Кол-во', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Алерт', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Закупка', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Продажа', style: AppTextStyles.h3)),
          SizedBox(width: 12),
          Expanded(child: Text('Сумма', style: AppTextStyles.h3)),
          const SizedBox(width: 48), // Action
        ],
      ),
    );
  }
}
