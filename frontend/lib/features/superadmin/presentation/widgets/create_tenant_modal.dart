import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../bloc/superadmin_bloc.dart';
import 'create_tenant_business_section.dart';
import 'create_tenant_owner_section.dart';
import 'create_tenant_modules_section.dart';
import 'tenant_slug_helper.dart';

class CreateTenantModal extends StatefulWidget {
  const CreateTenantModal({super.key});

  @override
  State<CreateTenantModal> createState() => _CreateTenantModalState();
}

class _CreateTenantModalState extends State<CreateTenantModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _schemaController = TextEditingController();
  final _addressController = TextEditingController();
  final _currencyController = TextEditingController(text: 'с');
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController(text: '1234');

  bool _useKds = true;
  bool _enableInventoryDeduction = true;
  bool _isManualSchema = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _schemaController.dispose();
    _addressController.dispose();
    _currencyController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_isManualSchema) {
      _schemaController.text = TenantSlugHelper.generate(_nameController.text);
    }
  }

  bool get _isDirty =>
      _nameController.text.isNotEmpty ||
      _addressController.text.isNotEmpty ||
      _usernameController.text.isNotEmpty ||
      _passwordController.text.isNotEmpty ||
      _fullNameController.text.isNotEmpty;

  void _onCancel() {
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (ctx) => AppDialog(
          title: 'Отменить создание?',
          icon: PhosphorIconsRegular.warningCircle,
          isDestructive: true,
          content: Text(
            'Введенные данные не сохранятся. Вы действительно хотите закрыть окно?',
            style: AppTextStyles.bodyMedium,
          ),
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
    if (_formKey.currentState!.validate()) {
      context.read<SuperadminBloc>().createTenant(
        name: _nameController.text.trim(),
        schemaName: _schemaController.text.trim(),
        address: _addressController.text.trim(),
        ownerUsername: _usernameController.text.trim(),
        ownerPassword: _passwordController.text.trim(),
        ownerFullName: _fullNameController.text.trim(),
        ownerPinCode: _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : '1234',
        ownerPhone: _phoneController.text.trim(),
        ownerEmail: _emailController.text.trim(),
        useKds: _useKds,
        enableInventoryDeduction: _enableInventoryDeduction,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onCancel();
      },
      child: AppDialog(
        title: 'Новый Ресторан',
        icon: PhosphorIconsRegular.storefront,
        width: 620,
        onClose: _onCancel,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CreateTenantBusinessSection(
                    nameController: _nameController,
                    schemaController: _schemaController,
                    currencyController: _currencyController,
                    addressController: _addressController,
                    onSchemaManualChanged: (_) => _isManualSchema = true,
                  ),
                  const SizedBox(height: 20),
                  CreateTenantOwnerSection(
                    fullNameController: _fullNameController,
                    phoneController: _phoneController,
                    emailController: _emailController,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    pinController: _pinController,
                  ),
                  const SizedBox(height: 20),
                  CreateTenantModulesSection(
                    useKds: _useKds,
                    enableInventoryDeduction: _enableInventoryDeduction,
                    onKdsChanged: (val) => setState(() => _useKds = val),
                    onInventoryChanged: (val) => setState(() => _enableInventoryDeduction = val),
                  ),
                ],
              ),
            ),
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
            label: 'Создать и запустить',
            icon: PhosphorIconsRegular.rocketLaunch,
            size: AppButtonSize.md,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
