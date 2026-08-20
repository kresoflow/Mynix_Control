import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../bloc/superadmin_bloc.dart';
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

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isRequired = true,
    String? hint,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: AppTextStyles.body.copyWith(
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        hintStyle: AppTextStyles.caption.copyWith(
          color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: AppColors.brandPrimary, size: 18),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator ?? (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return 'Обязательное поле';
        }
        return null;
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontSize: 15,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ],
    );
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
                // Header
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
                        // 1. Блок ресторана
                        _buildSectionHeader('1. Данные Заведения (Бизнес)', PhosphorIconsRegular.buildings, AppColors.brandPrimary),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Название ресторана',
                          hint: 'Например: Krunchy Burger & Co',
                          icon: PhosphorIconsRegular.textT,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildField(
                                label: 'Схема БД (Автогенерация)',
                                hint: 'krunchy_burger',
                                icon: PhosphorIconsRegular.database,
                                controller: _schemaController,
                                onChanged: (_) => _isManualSchema = true,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Укажите схему БД';
                                  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val)) {
                                    return 'Только латинские буквы, цифры и подчеркивание';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                label: 'Валюта заведения',
                                hint: 'сом (с)',
                                icon: PhosphorIconsRegular.currencyCircleDollar,
                                controller: _currencyController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          label: 'Адрес заведения',
                          hint: 'г. Бишкек, пр. Чуй 140',
                          icon: PhosphorIconsRegular.mapPin,
                          controller: _addressController,
                          isRequired: false,
                        ),
                        const SizedBox(height: 20),

                        // 2. Блок Владельца
                        _buildSectionHeader('2. Данные Владельца (Owner)', PhosphorIconsRegular.shieldCheck, AppColors.success),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'ФИО Владельца',
                          hint: 'Алмазов Данияр Русланович',
                          icon: PhosphorIconsRegular.user,
                          controller: _fullNameController,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Телефон владельца',
                                hint: '+996 (555) 01-23-45',
                                icon: PhosphorIconsRegular.phone,
                                controller: _phoneController,
                                isRequired: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildField(
                                label: 'Email владельца',
                                hint: 'owner@krunchyburger.test',
                                icon: PhosphorIconsRegular.envelope,
                                controller: _emailController,
                                isRequired: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                label: 'Логин',
                                hint: 'daniyar_owner',
                                icon: PhosphorIconsRegular.identificationCard,
                                controller: _usernameController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                label: 'Пароль',
                                icon: PhosphorIconsRegular.lockKey,
                                isPassword: true,
                                controller: _passwordController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: _buildField(
                                label: 'PIN кассы',
                                hint: '1234',
                                icon: PhosphorIconsRegular.key,
                                controller: _pinController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. Блок Подключаемых Модулей
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

                // Кнопка создания
                AppPrimaryButton(
                  label: 'Создать и запустить',
                  icon: PhosphorIconsRegular.rocketLaunch,
                  onPressed: () {
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
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
