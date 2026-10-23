// ============================================================================
// Kreso Flow | Superadmin View | Edit Tenant Modal Dialog
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import '../../models/tenant.dart';
import 'edit_tenant_general_section.dart';
import 'edit_tenant_modules_section.dart';
import 'edit_tenant_owner_section.dart';

// ─── 1. Types & Callbacks ───────────────────────────────────────────────────

typedef OnSaveTenantCallback = void Function({
  required String name,
  required String address,
  required String currency,
  required bool isActive,
  required bool useKds,
  required bool useOrders,
  required bool enableInventoryDeduction,
  String? ownerFullName,
  String? ownerPhone,
  String? ownerEmail,
  String? ownerPassword,
  String? ownerPinCode,
});

// ─── 2. Edit Tenant Modal Widget ────────────────────────────────────────────

class EditTenantModal extends StatefulWidget {
  final Tenant tenant;
  final OnSaveTenantCallback onSave;

  const EditTenantModal({super.key, required this.tenant, required this.onSave});

  @override
  State<EditTenantModal> createState() => _EditTenantModalState();
}

class _EditTenantModalState extends State<EditTenantModal> {
  final _formKey = GlobalKey<FormState>();
  int _selectedTab = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _currencyController;
  late final TextEditingController _ownerFullNameController;
  late final TextEditingController _ownerPhoneController;
  late final TextEditingController _ownerEmailController;
  late final TextEditingController _ownerPinController;
  late final TextEditingController _ownerPasswordController;

  late bool _isActive;
  late bool _useKds;
  late bool _useOrders;
  late bool _enableInventoryDeduction;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _nameController = TextEditingController(text: t.name);
    _addressController = TextEditingController(text: t.address);
    _currencyController = TextEditingController(text: t.currency);
    _ownerFullNameController = TextEditingController(text: t.ownerFullName ?? '');
    _ownerPhoneController = TextEditingController(text: t.ownerPhone ?? '');
    _ownerEmailController = TextEditingController(text: t.ownerEmail ?? '');
    _ownerPinController = TextEditingController(text: t.ownerPinCode ?? '1234');
    _ownerPasswordController = TextEditingController();

    _isActive = t.isActive;
    _useKds = t.useKds;
    _useOrders = t.useOrders;
    _enableInventoryDeduction = t.enableInventoryDeduction;
  }

  @override
  void dispose() {
    for (final c in [
      _nameController, _addressController, _currencyController,
      _ownerFullNameController, _ownerPhoneController, _ownerEmailController,
      _ownerPinController, _ownerPasswordController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isDirty {
    final t = widget.tenant;
    return _nameController.text.trim() != t.name ||
        _addressController.text.trim() != t.address ||
        _currencyController.text.trim() != t.currency ||
        _isActive != t.isActive || _useKds != t.useKds || _useOrders != t.useOrders ||
        _enableInventoryDeduction != t.enableInventoryDeduction ||
        _ownerFullNameController.text.trim() != (t.ownerFullName ?? '') ||
        _ownerPhoneController.text.trim() != (t.ownerPhone ?? '') ||
        _ownerEmailController.text.trim() != (t.ownerEmail ?? '') ||
        _ownerPinController.text.trim() != (t.ownerPinCode ?? '1234') ||
        _ownerPasswordController.text.isNotEmpty;
  }

  void _onCancel() {
    if (!_isDirty) return Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Отменить изменения?',
        icon: PhosphorIconsRegular.warningCircle,
        isDestructive: true,
        content: Text('Все несохраненные изменения будут потеряны. Вы уверены?', style: AppTextStyles.bodyMedium),
        actions: [
          AppSecondaryButton(
            label: 'Продолжить',
            size: AppButtonSize.md,
            onPressed: () => Navigator.pop(ctx),
          ),
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
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      if (_selectedTab != 0) setState(() => _selectedTab = 0);
      return;
    }
    widget.onSave(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      currency: _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim() : 'сом',
      isActive: _isActive,
      useKds: _useKds,
      useOrders: _useOrders,
      enableInventoryDeduction: _enableInventoryDeduction,
      ownerFullName: _ownerFullNameController.text.trim(),
      ownerPhone: _ownerPhoneController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim(),
      ownerPassword: _ownerPasswordController.text.trim().isNotEmpty ? _ownerPasswordController.text.trim() : null,
      ownerPinCode: _ownerPinController.text.trim().isNotEmpty ? _ownerPinController.text.trim() : null,
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
        width: 580,
        onClose: _onCancel,
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: AppRadii.inputRadius,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabPill(0, '1. Заведение', PhosphorIconsRegular.storefront, isDark),
                    const SizedBox(width: 4),
                    _buildTabPill(1, '2. Модули', PhosphorIconsRegular.gear, isDark),
                    const SizedBox(width: 4),
                    _buildTabPill(2, '3. Владелец', PhosphorIconsRegular.shieldCheck, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      EditTenantGeneralSection(
                        schemaName: widget.tenant.schemaName,
                        nameController: _nameController,
                        addressController: _addressController,
                        currencyController: _currencyController,
                        isActive: _isActive,
                        onActiveChanged: (v) => setState(() => _isActive = v),
                      ),
                      EditTenantModulesSection(
                        useKds: _useKds,
                        useOrders: _useOrders,
                        enableInventoryDeduction: _enableInventoryDeduction,
                        onKdsChanged: (v) => setState(() => _useKds = v),
                        onOrdersChanged: (v) => setState(() => _useOrders = v),
                        onInventoryChanged: (v) => setState(() => _enableInventoryDeduction = v),
                      ),
                      EditTenantOwnerSection(
                        ownerUsername: widget.tenant.ownerUsername,
                        fullNameController: _ownerFullNameController,
                        phoneController: _ownerPhoneController,
                        emailController: _ownerEmailController,
                        pinController: _ownerPinController,
                        passwordController: _ownerPasswordController,
                      ),
                    ],
                  ),
                ),
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

  Widget _buildTabPill(int index, String title, IconData icon, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: AppRadii.inputRadius,
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.22 : 0.14)
                : AppColors.transparent,
            borderRadius: AppRadii.inputRadius,
            border: Border.all(
              color: isSelected ? AppColors.brandPrimary : AppColors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? AppColors.brandPrimary
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.darkText : AppColors.brandPrimary)
                      : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
