import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseSegmentedSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseSegmentedSection({super.key, required this.isDark});

  @override
  State<ShowcaseSegmentedSection> createState() => _ShowcaseSegmentedSectionState();
}

class _ShowcaseSegmentedSectionState extends State<ShowcaseSegmentedSection> {
  String _posTab = 'cashier';
  String _themeMode = 'dark';
  String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('5. Сегментированные переключатели (AppSegmentedControl: SM, MD, LG)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Горизонтальный выбор 1 из N состояний. Активный элемент: 100% Brand Primary + Белый текст + Glow.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),

          // SM Size
          _buildRow(
            sizeLabel: 'SM (32px):',
            contextDesc: 'Для форм, настроек темы и компактных панелей',
            control: AppSegmentedControl<String>(
              selectedValue: _themeMode,
              size: AppSegmentedSize.sm,
              onValueChanged: (val) => setState(() => _themeMode = val),
              items: const [
                AppSegmentedItem(value: 'light', label: 'Светлая', icon: PhosphorIconsRegular.sun),
                AppSegmentedItem(value: 'dark', label: 'Тёмная', icon: PhosphorIconsRegular.moon),
                AppSegmentedItem(value: 'system', label: 'Системная', icon: PhosphorIconsRegular.desktop),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // MD Size
          _buildRow(
            sizeLabel: 'MD (38px):',
            contextDesc: 'Стандарт для шапок модулей и тулбаров (POS [Касса | Заказы | Кухня])',
            control: AppSegmentedControl<String>(
              selectedValue: _posTab,
              size: AppSegmentedSize.md,
              onValueChanged: (val) => setState(() => _posTab = val),
              items: const [
                AppSegmentedItem(value: 'cashier', label: 'Касса', icon: PhosphorIconsRegular.receipt),
                AppSegmentedItem(value: 'orders', label: 'Заказы', icon: PhosphorIconsRegular.listNumbers, count: 5),
                AppSegmentedItem(value: 'kds', label: 'Кухня (KDS)', icon: PhosphorIconsRegular.cookingPot, count: 2),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // LG Size
          _buildRow(
            sizeLabel: 'LG (46px):',
            contextDesc: 'Просторный для сенсорных экранов и способов оплаты на POS',
            control: AppSegmentedControl<String>(
              selectedValue: _paymentMethod,
              size: AppSegmentedSize.lg,
              onValueChanged: (val) => setState(() => _paymentMethod = val),
              items: const [
                AppSegmentedItem(value: 'cash', label: 'Наличные', icon: PhosphorIconsRegular.money),
                AppSegmentedItem(value: 'transfer', label: 'Перевод / QR', icon: PhosphorIconsRegular.qrCode),
                AppSegmentedItem(value: 'card', label: 'Карта (POS)', icon: PhosphorIconsRegular.creditCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String sizeLabel,
    required String contextDesc,
    required Widget control,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(sizeLabel, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(contextDesc, style: AppTextStyles.caption.copyWith(color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ],
        ),
        const SizedBox(height: 8),
        control,
      ],
    );
  }
}
