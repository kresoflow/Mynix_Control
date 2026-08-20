import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Title Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.storefront,
                        color: AppColors.brandPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Новый Ресторан', style: AppTextStyles.h3),
                          Text(
                            'Создание заведения, базы данных тенанта и владельца',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Form Scroll Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
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
                const SizedBox(height: 20),

                // Submit Button
                AppPrimaryButton(
                  label: 'Создать и запустить',
                  icon: PhosphorIconsRegular.rocketLaunch,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
