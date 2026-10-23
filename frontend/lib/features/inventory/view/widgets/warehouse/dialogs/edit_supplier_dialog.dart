import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Диалог редактирования поставщика.
/// Возвращает Map с полями name, contact_info, is_active.
class EditSupplierDialog extends StatefulWidget {
  final Supplier supplier;

  const EditSupplierDialog({super.key, required this.supplier});

  @override
  State<EditSupplierDialog> createState() => _EditSupplierDialogState();
}

class _EditSupplierDialogState extends State<EditSupplierDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.supplier.name);
    _contactCtrl = TextEditingController(text: widget.supplier.contactInfo ?? '');
    _isActive = widget.supplier.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, {
      'name': name,
      'contact_info': _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      'is_active': _isActive,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      title: 'Редактировать поставщика',
      icon: PhosphorIconsRegular.pencilSimple,
      width: 460,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Название поставщика *',
              prefixIcon: Icon(
                PhosphorIconsRegular.storefront,
                color: AppColors.brandPrimary,
                size: 18,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightBg,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact info field
          TextField(
            controller: _contactCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Контакты (телефон, адрес, примечания)',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(
                  PhosphorIconsRegular.phone,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  size: 18,
                ),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightBg,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: AppRadii.radiusLg,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isActive ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.xCircle,
                  color: _isActive ? AppColors.success : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  size: 20,
                ),
                AppSpacing.hSm,
                Text(
                  'Статус активности',
                  style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
                ),
                const Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeThumbColor: AppColors.brandPrimary,
                ),
                AppSpacing.hXxs,
                Text(
                  _isActive ? 'Активен' : 'Неактивен',
                  style: TextStyle(
                    color: _isActive ? AppColors.success : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
        AppPrimaryButton(
          label: 'Сохранить',
          icon: PhosphorIconsRegular.floppyDisk,
          onPressed: _submit,
        ),
      ],
    );
  }
}
