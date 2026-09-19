import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import '../../domain/superadmin_repository.dart';

class EditTenantModal extends StatefulWidget {
  final Tenant tenant;
  final Function(String name, String address, bool useKds, bool enableInventoryDeduction) onSave;

  const EditTenantModal({
    super.key,
    required this.tenant,
    required this.onSave,
  });

  @override
  State<EditTenantModal> createState() => _EditTenantModalState();
}

class _EditTenantModalState extends State<EditTenantModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late bool _useKds;
  late bool _enableInventoryDeduction;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tenant.name);
    _addressController = TextEditingController(text: widget.tenant.address);
    _useKds = widget.tenant.useKds;
    _enableInventoryDeduction = widget.tenant.enableInventoryDeduction;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _nameController.text.trim() != widget.tenant.name ||
      _addressController.text.trim() != widget.tenant.address ||
      _useKds != widget.tenant.useKds ||
      _enableInventoryDeduction != widget.tenant.enableInventoryDeduction;

  void _onCancel() {
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (ctx) => AppDialog(
          title: 'Отменить изменения?',
          icon: PhosphorIconsRegular.warningCircle,
          isDestructive: true,
          content: Text('Все несохраненные изменения будут потеряны. Вы уверены?', style: AppTextStyles.bodyMedium),
          actions: [
            AppSecondaryButton(label: 'Продолжить', size: AppButtonSize.md, onPressed: () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            AppDangerButton(
              label: 'Сбросить',
              size: AppButtonSize.md,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      _nameController.text.trim(),
      _addressController.text.trim(),
      _useKds,
      _enableInventoryDeduction,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onCancel();
      },
      child: AppDialog(
        title: 'Параметры заведения',
        icon: PhosphorIconsRegular.pencilSimple,
        width: 480,
        onClose: _onCancel,
        content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Schema info banner (read only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: AppRadii.inputRadius,
                border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.database, size: 16, color: AppColors.brandPrimary),
                  const SizedBox(width: 8),
                  Text('Схема PostgreSQL: ', style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary)),
                  Text(
                    widget.tenant.schemaName,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name Field
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Название ресторана *',
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                prefixIcon: const Icon(PhosphorIconsRegular.storefront, size: 18),
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Введите название ресторана';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Address Field
            TextFormField(
              controller: _addressController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Фактический адрес',
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                prefixIcon: const Icon(PhosphorIconsRegular.mapPin, size: 18),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Switches: Features
            Text('Конфигурация модулей', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: 'Кухонный дисплей (KDS)',
              subtitle: 'Отправка заказов поварам на кухонный экран',
              value: _useKds,
              onChanged: (v) => setState(() => _useKds = v),
              icon: PhosphorIconsRegular.cookingPot,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: 'Складское списание',
              subtitle: 'Авто-списание ингредиентов по техкартам при оплате',
              value: _enableInventoryDeduction,
              onChanged: (v) => setState(() => _enableInventoryDeduction = v),
              icon: PhosphorIconsRegular.arrowsLeftRight,
              isDark: isDark,
            ),
          ],
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Отмена',
          size: AppButtonSize.md,
          onPressed: _onCancel,
        ),
        const SizedBox(width: 8),
        AppPrimaryButton(
          label: 'Сохранить',
          icon: PhosphorIconsRegular.floppyDisk,
          size: AppButtonSize.md,
          onPressed: _submit,
        ),
      ],
    ),
  );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.brandPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
