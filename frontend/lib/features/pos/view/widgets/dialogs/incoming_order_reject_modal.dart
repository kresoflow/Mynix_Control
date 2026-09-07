import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';

class IncomingOrderRejectModal extends StatefulWidget {
  final int orderNumber;
  final Future<void> Function(String reason) onConfirm;

  const IncomingOrderRejectModal({
    super.key,
    required this.orderNumber,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required int orderNumber,
    required Future<void> Function(String reason) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => IncomingOrderRejectModal(orderNumber: orderNumber, onConfirm: onConfirm),
    );
  }

  @override
  State<IncomingOrderRejectModal> createState() => _IncomingOrderRejectModalState();
}

class _IncomingOrderRejectModalState extends State<IncomingOrderRejectModal> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReasonChip = 'Стоп-лист (блюдо закончилось)';
  bool _isLoading = false;

  static const _quickReasons = [
    'Стоп-лист (блюдо закончилось)',
    'Отказ гостя',
    'Дубликат заказа',
    'Ошибка официанта / зала',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController.text = _selectedReasonChip;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      final reason = _reasonController.text.trim().isEmpty ? _selectedReasonChip : _reasonController.text.trim();
      await widget.onConfirm(reason);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MynixDialog(
      title: 'Отклонить заказ #${widget.orderNumber}?',
      icon: PhosphorIconsBold.warningCircle,
      isDestructive: true,
      width: 440,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выберите готовую причину или введите свой комментарий:',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 12),
          // Quick Reason Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReasons.map((reason) {
              final isSelected = _selectedReasonChip == reason;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReasonChip = reason;
                    _reasonController.text = reason;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.danger
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.2 : 1,
                    ),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.danger
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Text input
          AppTextField(
            controller: _reasonController,
            hintText: 'Уточните причину отмены...',
            prefixIcon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
            onChanged: (val) {
              if (_quickReasons.contains(val)) {
                setState(() => _selectedReasonChip = val);
              } else if (_selectedReasonChip.isNotEmpty) {
                setState(() => _selectedReasonChip = '');
              }
            },
          ),
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Назад',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        AppDangerButton(
          label: 'Отклонить заказ',
          icon: PhosphorIconsBold.x,
          isLoading: _isLoading,
          onPressed: _handleConfirm,
        ),
      ],
    );
  }
}
