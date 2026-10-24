import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

class HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const HueSlider({
    super.key,
    required this.hue,
    required this.onChanged,
  });

  static const List<Color> _rainbowColors = [
    Color(0xFFFF0000), // 0°
    Color(0xFFFFFF00), // 60°
    Color(0xFF00FF00), // 120°
    Color(0xFF00FFFF), // 180°
    Color(0xFF0000FF), // 240°
    Color(0xFFFF00FF), // 300°
    Color(0xFFFF0000), // 360°
  ];

  void _handlePointer(Offset localPosition, double width) {
    final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
    final newHue = (ratio * 360.0).clamp(0.0, 360.0);
    onChanged(newHue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbX = ((hue / 360.0) * width).clamp(8.0, width - 8.0);
        final currentHueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

        return GestureDetector(
          onPanDown: (details) => _handlePointer(details.localPosition, width),
          onPanUpdate: (details) => _handlePointer(details.localPosition, width),
          child: SizedBox(
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Rainbow Spectrum Bar
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.radiusSm,
                    gradient: const LinearGradient(
                      colors: _rainbowColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                // Draggable Hue Ring
                Positioned(
                  left: thumbX - 9,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: currentHueColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pureWhite, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
