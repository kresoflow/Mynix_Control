import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import '../bloc/superadmin_bloc.dart';

class CreateTenantModal extends StatefulWidget {
  const CreateTenantModal({super.key});

  @override
  State<CreateTenantModal> createState() => _CreateTenantModalState();
}

class _CreateTenantModalState extends State<CreateTenantModal> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String schemaName = '';
  String address = '';
  String ownerUsername = '';
  String ownerPassword = '';
  String ownerFullName = '';

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      obscureText: isPassword,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.darkSubtext),
        prefixIcon: Icon(icon, color: AppColors.darkSubtext, size: 20),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkCardHover 
            : AppColors.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
      ),
      onSaved: onSaved,
      validator: (val) => val == null || val.isEmpty ? 'Обязательное поле' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ]
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(PhosphorIcons.storefront(), color: AppColors.brandPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Новый Ресторан', style: AppTextStyles.h2),
                      Text('Добавление бизнеса в систему', 
                           style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.x(), color: AppColors.darkSubtext),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 32),
            _buildTextField(
              label: 'Название ресторана',
              icon: PhosphorIcons.textT(),
              onSaved: (val) => name = val ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Схема БД (напр. tenant_3)',
              icon: PhosphorIcons.database(),
              onSaved: (val) => schemaName = val ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Адрес',
              icon: PhosphorIcons.mapPin(),
              onSaved: (val) => address = val ?? '',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(PhosphorIcons.shieldCheck(), size: 20, color: AppColors.success),
                const SizedBox(width: 8),
                Text('Данные Владельца', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'ФИО Владельца',
              icon: PhosphorIcons.user(),
              onSaved: (val) => ownerFullName = val ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Логин',
                    icon: PhosphorIcons.identificationCard(),
                    onSaved: (val) => ownerUsername = val ?? '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Пароль',
                    icon: PhosphorIcons.lockKey(),
                    isPassword: true,
                    onSaved: (val) => ownerPassword = val ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  context.read<SuperadminBloc>().createTenant(
                    name: name,
                    schemaName: schemaName,
                    address: address,
                    ownerUsername: ownerUsername,
                    ownerPassword: ownerPassword,
                    ownerFullName: ownerFullName,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('СОЗДАТЬ И ЗАПУСТИТЬ', style: AppTextStyles.buttonLarge),
            )
          ],
        ),
      ),
    );
  }
}
