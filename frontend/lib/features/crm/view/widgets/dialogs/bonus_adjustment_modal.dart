import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_bloc.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_event.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';

class BonusAdjustmentModal extends StatefulWidget {
  final Customer customer;

  const BonusAdjustmentModal({super.key, required this.customer});

  @override
  State<BonusAdjustmentModal> createState() => _BonusAdjustmentModalState();
}

class _BonusAdjustmentModalState extends State<BonusAdjustmentModal> {
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isAccrual = true; // true = add, false = deduct
  String _selectedReason = 'Комплимент от заведения';

  final _reasonsAdd = [
    'Комплимент от заведения',
    'Извинение за задержку',
    'Промо-акция / Подарок',
    'Персональный бонус',
  ];

  final _reasonsSub = [
    'Списание по согласованию',
    'Корректировка баланса',
    'Аннулирование бонусов',
  ];

  @override
  void dispose() {
    _amountController.disposeWidget();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму бонусов')),
      );
      return;
    }

    if (!_isAccrual && amount > widget.customer.bonusBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нельзя списать больше ${widget.customer.bonusBalance.toStringAsFixed(0)} с')),
      );
      return;
    }

    final comment = _commentController.text.trim().isNotEmpty
        ? '$_selectedReason: ${_commentController.text.trim()}'
        : _selectedReason;

    context.read<CrmBloc>().add(
          CreateCustomerBonusTransactionEvent(
            widget.customer.id,
            {
              'type': _isAccrual ? 'manual_add' : 'manual_sub',
              'amount': amount,
              'comment': comment,
            },
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(PhosphorIconsRegular.gift, color: AppColors.brandPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Бонусы клиента', style: AppTextStyles.h3),
                      Text(widget.customer.name, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Bonus Balance Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Текущий бонусный счет:', style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 13)),
                  Text(
                    '${widget.customer.bonusBalance.toStringAsFixed(0)} бонусов',
                    style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Toggle
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Начислить',
                    icon: PhosphorIconsRegular.plusCircle,
                    isSelected: _isAccrual,
                    activeColor: AppColors.success,
                    onTap: () => setState(() {
                      _isAccrual = true;
                      _selectedReason = _reasonsAdd.first;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Списать',
                    icon: PhosphorIconsRegular.minusCircle,
                    isSelected: !_isAccrual,
                    activeColor: AppColors.error,
                    onTap: () => setState(() {
                      _isAccrual = false;
                      _selectedReason = _reasonsSub.first;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Количество бонусов',
                hintText: '0',
                suffixText: 'бонусов',
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            // Reason Dropdown
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                labelText: 'Причина',
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: (_isAccrual ? _reasonsAdd : _reasonsSub).map((r) {
                return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
            const SizedBox(height: 14),

            // Comment Input
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Комментарий (необязательно)',
                hintText: 'Номер чека, примечание...',
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAccrual ? AppColors.success : AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isAccrual ? 'Начислить бонусы' : 'Списать бонусы',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on TextEditingController {
  void disposeWidget() {
    dispose();
  }
}
