import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'color_picker_utils.dart';
import 'hsv_color_plane.dart';
import 'hue_slider.dart';

class AppColorPickerDialog extends StatefulWidget {
  final Color? initialColor;

  const AppColorPickerDialog({super.key, this.initialColor});

  static Future<String?> show(BuildContext context, {String? initialHex}) async {
    final initColor = ColorPickerUtils.parseHex(initialHex) ?? const Color(0xFFE65100);
    return showDialog<String?>(
      context: context,
      builder: (context) => AppColorPickerDialog(initialColor: initColor),
    );
  }

  @override
  State<AppColorPickerDialog> createState() => _AppColorPickerDialogState();
}

class _AppColorPickerDialogState extends State<AppColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor ?? const Color(0xFFE65100));
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController = TextEditingController(text: ColorPickerUtils.toHex(hsv.toColor()).replaceAll('#', ''));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  void _updateFromHsv({double? hue, double? saturation, double? value}) {
    setState(() {
      if (hue != null) _hue = hue;
      if (saturation != null) _saturation = saturation;
      if (value != null) _value = value;
      _hexController.text = ColorPickerUtils.toHex(_currentColor).replaceAll('#', '');
    });
  }

  void _onHexChanged(String text) {
    final parsed = ColorPickerUtils.parseHex(text);
    if (parsed != null) {
      final hsv = HSVColor.fromColor(parsed);
      setState(() {
        _hue = hsv.hue;
        _saturation = hsv.saturation;
        _value = hsv.value;
      });
    }
  }

  void _selectPreset(Color color) {
    final hsv = HSVColor.fromColor(color);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
      _hexController.text = ColorPickerUtils.toHex(color).replaceAll('#', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = _currentColor;

    return AppDialog(
      title: 'Выбор цвета категории',
      icon: PhosphorIconsRegular.palette,
      width: 440,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 2D HSV Spectrum Canvas (Height: 160)
          SizedBox(
            height: 160,
            child: HsvColorPlane(
              hue: _hue,
              saturation: _saturation,
              value: _value,
              onChanged: (sv) => _updateFromHsv(saturation: sv.saturation, value: sv.value),
            ),
          ),
          const SizedBox(height: 14),

          // 2. 360° Rainbow Hue Slider
          HueSlider(
            hue: _hue,
            onChanged: (newHue) => _updateFromHsv(hue: newHue),
          ),
          const SizedBox(height: 14),

          // 3. Current Color Swatch & HEX Input Field
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _hexController,
                  onChanged: _onHexChanged,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Код цвета (HEX)',
                    prefixText: '#',
                    prefixStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Quick Commercial Swatches
          Text(
            'Готовые палитры',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ColorPickerUtils.commercialPresets.map((preset) {
              final isSelected = ColorPickerUtils.toHex(preset.color) == ColorPickerUtils.toHex(activeColor);
              return InkWell(
                onTap: () => _selectPreset(preset.color),
                borderRadius: BorderRadius.circular(8),
                child: Tooltip(
                  message: preset.title,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: preset.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: preset.color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ''),
              icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 16),
              label: const Text('Сбросить'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, ColorPickerUtils.toHex(activeColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: ThemeData.estimateBrightnessForColor(activeColor) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Выбрать цвет',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
