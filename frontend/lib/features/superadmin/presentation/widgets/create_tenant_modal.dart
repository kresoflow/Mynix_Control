import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../bloc/superadmin_bloc.dart';

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
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController(text: '1234');

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
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_isManualSchema) {
      final slug = _generateSlug(_nameController.text);
      _schemaController.text = slug;
    }
  }

  String _generateSlug(String text) {
    final translitMap = {
      'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
      'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
      'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
      'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sch',
      'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
      ' ': '_', '-': '_', '&': 'and',
    };
    var result = '';
    for (var char in text.toLowerCase().split('')) {
      if (translitMap.containsKey(char)) {
        result += translitMap[char]!;
      } else if (RegExp(r'[a-z0-9_]').hasMatch(char)) {
        result += char;
      }
    }
    return result.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
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
      validator: validator ?? (val) => val == null || val.trim().isEmpty ? 'Обязательное поле' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
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
            child: SingleChildScrollView(
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
                              'Создание заведения и базы данных тенанта',
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
                  const SizedBox(height: 24),

                  // 1. Блок ресторана
                  _buildField(
                    label: 'Название ресторана',
                    hint: 'Например: Krunchy Burger',
                    icon: PhosphorIconsRegular.textT,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
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
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Адрес заведения',
                    hint: 'г. Бишкек, пр. Чуй 140',
                    icon: PhosphorIconsRegular.mapPin,
                    controller: _addressController,
                  ),
                  const SizedBox(height: 20),

                  // 2. Блок Владельца
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.shieldCheck, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Данные Владельца',
                        style: AppTextStyles.h3.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'ФИО Владельца',
                    hint: 'Алмазов Данияр',
                    icon: PhosphorIconsRegular.user,
                    controller: _fullNameController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'Логин',
                          hint: 'daniyar_owner',
                          icon: PhosphorIconsRegular.identificationCard,
                          controller: _usernameController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          label: 'Пароль',
                          icon: PhosphorIconsRegular.lockKey,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
      ),
    );
  }
}
