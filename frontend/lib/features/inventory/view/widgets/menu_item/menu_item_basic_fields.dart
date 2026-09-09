import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/menu/services/duplicate_detector.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/create_menu_item_dialog.dart';

class MenuItemBasicFields extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController barcodeController;
  final TextEditingController sortOrderController;
  final int? currentCategoryId;
  final int? excludeItemId;

  const MenuItemBasicFields({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.barcodeController,
    required this.sortOrderController,
    this.currentCategoryId,
    this.excludeItemId,
  });

  @override
  State<MenuItemBasicFields> createState() => _MenuItemBasicFieldsState();
}

class _MenuItemBasicFieldsState extends State<MenuItemBasicFields> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onFieldChanged);
    widget.barcodeController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onFieldChanged);
    widget.barcodeController.removeListener(_onFieldChanged);
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.darkBg : AppColors.lightBg;

    final menuState = context.watch<MenuBloc>().state;
    DuplicateMatch? duplicateMatch;
    if (menuState is MenuLoaded) {
      duplicateMatch = DuplicateDetector.findMenuItemDuplicate(
        items: menuState.items,
        queryName: widget.nameController.text,
        queryBarcode: widget.barcodeController.text,
        currentCategoryId: widget.currentCategoryId,
        excludeItemId: widget.excludeItemId,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: widget.nameController,
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
                    controller: widget.priceController,
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
        if (duplicateMatch != null)
          DuplicateWarningChip(
            message: duplicateMatch.matchReason,
            onOpenExisting: () {
              Navigator.pop(context);
              showAddMenuItemDialog(
                context,
                currentCategoryId: widget.currentCategoryId,
                itemToEdit: duplicateMatch!.item,
              );
            },
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.barcodeController,
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
                controller: widget.sortOrderController,
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
