import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Диалог редактирования поставщика.
/// Возвращает Map<String, dynamic> с полями name, contact_info, is_active.
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsRegular.pencilSimple, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Редактировать поставщика',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(PhosphorIconsRegular.x,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Название поставщика *',
                prefixIcon: Icon(PhosphorIconsRegular.storefront,
                    color: AppColors.brandPrimary, size: 18),
                filled: true,
                fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            // Contact field
            TextField(
              controller: _contactCtrl,
              decoration: InputDecoration(
                labelText: 'Контактные данные',
                prefixIcon: Icon(PhosphorIconsRegular.phone,
                    color: AppColors.brandPrimary, size: 18),
                filled: true,
                fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.toggleLeft,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 18),
                  const SizedBox(width: 10),
                  Text('Статус поставщика',
                      style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText)),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeColor: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isActive ? 'Активен' : 'Неактивен',
                    style: TextStyle(
                      color: _isActive ? AppColors.success : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(PhosphorIconsRegular.floppyDisk, size: 16),
                    label: const Text('Сохранить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
