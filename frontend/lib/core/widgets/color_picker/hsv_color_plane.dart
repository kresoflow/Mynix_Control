import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

class HsvColorPlane extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final ValueChanged<({double saturation, double value})> onChanged;

  const HsvColorPlane({
    super.key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  void _handlePointer(Offset localPosition, Size size) {
    final s = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    onChanged((saturation: s, value: v));
  }

  @override
  Widget build(BuildContext context) {
    final pureHueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final thumbX = (saturation * width).clamp(8.0, width - 8.0);
        final thumbY = ((1.0 - value) * height).clamp(8.0, height - 8.0);

        return GestureDetector(
          onPanDown: (details) => _handlePointer(details.localPosition, Size(width, height)),
          onPanUpdate: (details) => _handlePointer(details.localPosition, Size(width, height)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base Hue + Saturation (White to Hue) + Value (Transparent to Black)
              ClipRRect(
                borderRadius: AppRadii.buttonRadius,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.pureWhite, pureHueColor],
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.transparent, AppColors.black],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Draggable Pointer Ring
              Positioned(
                left: thumbX - 10,
                top: thumbY - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pureWhite, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
