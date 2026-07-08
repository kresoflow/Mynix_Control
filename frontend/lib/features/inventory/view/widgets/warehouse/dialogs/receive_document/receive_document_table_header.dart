import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class ReceiveDocumentTableHeader extends StatelessWidget {
  final String currency;

  const ReceiveDocumentTableHeader({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('Товар / Сырье', style: AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 16),
          const Expanded(child: Text('Вкус', style: AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 16),
          const Expanded(child: Text('Объем', style: AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 16),
          const Expanded(child: Text('Ед. изм.', style: AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 16),
          const Expanded(child: Text('Количество', style: AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 16),
          Expanded(child: Text('Цена ($currency)', style: const AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 16),
          Expanded(child: Text('Сумма ($currency)', style: const AppTextStyles.bodyLargeBold)),
          const SizedBox(width: 48), // Action
        ],
      ),
    );
  }
}
