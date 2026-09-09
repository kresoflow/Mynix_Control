import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

class MenuItemBasicFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController barcodeController;
  final TextEditingController sortOrderController;

  const MenuItemBasicFields({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.barcodeController,
    required this.sortOrderController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Название блюда',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.inputRadius,
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(PhosphorIconsRegular.bowlFood, color: AppColors.brandPrimary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Обязательное поле' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Builder(
                builder: (context) {
                  final currency = context.watch<SettingsBloc>().state.currency;
                  return TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Базовая цена',
                      suffixText: currency,
                      suffixStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: 'Штрихкод (опционально)',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.inputRadius,
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: sortOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Порядок в меню (1, 2, 3...)',
                  hintText: 'Пусто = авто-очередь',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.inputRadius,
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(PhosphorIconsRegular.sortAscending, color: AppColors.brandPrimary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
