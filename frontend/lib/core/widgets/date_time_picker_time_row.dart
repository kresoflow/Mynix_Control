import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class DateTimePickerTimeRow extends StatelessWidget {
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final Function(int h, int m) onQuickTimeSelected;

  const DateTimePickerTimeRow({
    super.key,
    required this.hourController,
    required this.minuteController,
    required this.onQuickTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('Время:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),

        _buildDigitalTimeBox(hourController, 23, isDark),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        _buildDigitalTimeBox(minuteController, 59, isDark),

        const Spacer(),
        _buildQuickTimeChip('Сейчас', () => onQuickTimeSelected(DateTime.now().hour, DateTime.now().minute), isDark),
        const SizedBox(width: 4),
        _buildQuickTimeChip('10:00', () => onQuickTimeSelected(10, 0), isDark),
        const SizedBox(width: 4),
        _buildQuickTimeChip('18:00', () => onQuickTimeSelected(18, 0), isDark),
      ],
    );
  }

  Widget _buildDigitalTimeBox(TextEditingController controller, int max, bool isDark) {
    return Container(
      width: 42,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 2,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null && parsed > max) {
              controller.text = max.toString().padLeft(2, '0');
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        ),
      ),
    );
  }
}
