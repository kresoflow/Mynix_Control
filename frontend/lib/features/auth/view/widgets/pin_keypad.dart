import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class PinKeypad extends StatelessWidget {
  final String pin;
  final ValueChanged<String> onPinChanged;
  final VoidCallback onComplete;
  final bool isDark;

  const PinKeypad({
    super.key,
    required this.pin,
    required this.onPinChanged,
    required this.onComplete,
    required this.isDark,
  });

  void _handleKey(String val) {
    if (pin.length < 4) {
      final newPin = pin + val;
      onPinChanged(newPin);
      if (newPin.length == 4) {
        onComplete();
      }
    }
  }

  void _handleBackspace() {
    if (pin.isNotEmpty) {
      onPinChanged(pin.substring(0, pin.length - 1));
    }
  }

  void _handleClear() {
    onPinChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4 PIN indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.brandPrimary : Colors.transparent,
                border: Border.all(
                  color: isFilled ? AppColors.brandPrimary : (isDark ? Colors.white24 : Colors.black26),
                  width: 2,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        // NumPad Grid
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 12),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton('C', _handleClear),
                  _buildNumberButton('0'),
                  _buildActionIconButton(PhosphorIconsRegular.backspace, _handleBackspace),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: numbers.map((n) => _buildNumberButton(n)).toList(),
    );
  }

  Widget _buildNumberButton(String num) {
    return InkWell(
      onTap: () => _handleKey(num),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Text(
          num,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 24,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
      ),
    );
  }
}
