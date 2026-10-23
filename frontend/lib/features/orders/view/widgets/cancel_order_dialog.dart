import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/orders/models/pos_order.dart';

class CancelOrderDialog extends StatefulWidget {
  final PosOrder order;

  const CancelOrderDialog({super.key, required this.order});

  static Future<String?> show(BuildContext context, {required PosOrder order}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CancelOrderDialog(order: order),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  static const List<String> _reasons = [
    'Отказ гостя / передумал',
    'Ошибка ввода кассира',
    'Брак блюда / некондиция',
    'Долгое ожидание',
    'Другая причина',
  ];

  String _selectedReason = _reasons.first;
  final TextEditingController _customReasonCtrl = TextEditingController();

  @override
  void dispose() {
    _customReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final isCustom = _selectedReason == 'Другая причина';

    return AppDialog(
      title: 'Отмена чека #${widget.order.orderNumber}',
      icon: PhosphorIconsRegular.warningCircle,
      isDestructive: true,
      width: 460,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: AppRadii.inputRadius,
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsRegular.info, color: AppColors.danger, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Это действие необратимо. Заказ будет аннулирован, а складские остатки скорректированы.',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Укажите причину отмены:',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];
            final isSelected = _selectedReason == reason;
            return InkWell(
              borderRadius: AppRadii.inputRadius,
              onTap: () => setState(() => _selectedReason = reason),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                      size: 18,
                      color: isSelected ? AppColors.danger : subtextColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? AppColors.darkText : AppColors.lightText)
                              : subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (isCustom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customReasonCtrl,
              autofocus: true,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Опишите причину отмены...',
                border: OutlineInputBorder(borderRadius: AppRadii.inputRadius),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Назад',
          onPressed: () => Navigator.pop(context, null),
        ),
        AppDangerButton(
          label: 'Подтвердить отмену',
          icon: PhosphorIconsRegular.xCircle,
          onPressed: () {
            final finalReason = isCustom && _customReasonCtrl.text.trim().isNotEmpty
                ? _customReasonCtrl.text.trim()
                : _selectedReason;
            Navigator.pop(context, finalReason);
          },
        ),
      ],
    );
  }
}
