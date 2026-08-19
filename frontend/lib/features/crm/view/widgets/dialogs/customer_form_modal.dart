import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
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
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isEdit = widget.initialCustomer != null;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? PhosphorIconsRegular.userGear : PhosphorIconsRegular.userPlus,
                            color: AppColors.brandPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? 'Редактировать гостя' : 'Новый гость / клиент',
                          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(PhosphorIconsRegular.x, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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
                        label: 'Кредитный лимит (с)',
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
                                : 'День рождения (для авто-бонусов)',
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

                // Notes / Address
                _buildField(
                  controller: _notesController,
                  label: 'Заметки / Описание',
                  hint: 'Например: постоянный гость, офис #402',
                  icon: PhosphorIconsRegular.note,
                  maxLines: 2,
                  isDark: isDark,
                  border: border,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: border),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEdit ? 'Сохранить изменения' : 'Создать клиента',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
