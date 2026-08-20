import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';

class CustomerFormModal extends StatefulWidget {
  final Customer? initialCustomer;
  final String? initialPhone;
  final Function(Map<String, dynamic> data) onSubmit;

  const CustomerFormModal({
    super.key,
    this.initialCustomer,
    this.initialPhone,
    required this.onSubmit,
  });

  @override
  State<CustomerFormModal> createState() => _CustomerFormModalState();
}

class _CustomerFormModalState extends State<CustomerFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _discountController;
  late final TextEditingController _notesController;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? widget.initialPhone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _creditLimitController = TextEditingController(
      text: (c?.creditLimit != null && c!.creditLimit > 0) ? c.creditLimit.toStringAsFixed(0) : '',
    );
    _discountController = TextEditingController(
      text: (c?.discountPercent != null && c!.discountPercent > 0) ? c.discountPercent.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: c?.notes ?? '');
    _birthDate = c?.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      'credit_limit': double.tryParse(_creditLimitController.text.replaceAll(',', '.')) ?? 0.0,
      'discount_percent': double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0.0,
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      if (_birthDate != null) 'birth_date': _birthDate!.toIso8601String().split('T')[0],
    };

    widget.onSubmit(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isEdit = widget.initialCustomer != null;
    final symbol = CurrencyFormatter.symbol(context);

    return MynixDialog(
      title: isEdit ? 'Редактировать гостя' : 'Новый гость / клиент',
      icon: isEdit ? PhosphorIconsRegular.userGear : PhosphorIconsRegular.userPlus,
      width: 480,
      actions: [
        AppButton.secondary(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: isEdit ? 'Сохранить' : 'Создать',
          onPressed: _submit,
        ),
      ],
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name (Required)
              _buildField(
                controller: _nameController,
                label: 'ФИО / Имя клиента *',
                hint: 'Например: Иван Петров',
                icon: PhosphorIconsRegular.user,
                isDark: isDark,
                border: border,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите имя клиента' : null,
              ),
              const SizedBox(height: 14),

              // Phone
              _buildField(
                controller: _phoneController,
                label: 'Номер телефона',
                hint: '+996 555 123 456',
                icon: PhosphorIconsRegular.phone,
                keyboardType: TextInputType.phone,
                isDark: isDark,
                border: border,
              ),
              const SizedBox(height: 14),

              // Credit Limit & Discount row
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _creditLimitController,
                      label: 'Лимит ($symbol)',
                      hint: '0 — без лимита',
                      icon: PhosphorIconsRegular.shieldCheck,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      border: border,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _discountController,
                      label: 'Скидка (%)',
                      hint: '0',
                      icon: PhosphorIconsRegular.percent,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      border: border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Birthday (Optional for auto-bonuses)
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1930),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.cake, size: 18, color: AppColors.brandPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _birthDate != null
                              ? 'День рождения: ${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}'
                              : 'День рождения (для бонусов)',
                          style: TextStyle(
                            fontSize: 13,
                            color: _birthDate != null ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          ),
                        ),
                      ),
                      if (_birthDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _birthDate = null),
                          child: const Icon(PhosphorIconsRegular.xCircle, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              _buildField(
                controller: _notesController,
                label: 'Заметки',
                hint: 'Например: постоянный гость',
                icon: PhosphorIconsRegular.note,
                maxLines: 2,
                isDark: isDark,
                border: border,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color border,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            prefixIcon: maxLines == 1 ? Icon(icon, size: 18, color: AppColors.brandPrimary) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
