// ============================================================================
// Kreso Flow | Superadmin View | Delete Tenant Dialog
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import '../../models/tenant.dart';

// ─── 1. Destructive Delete Confirmation Dialog ──────────────────────────────

class DeleteTenantDialog extends StatefulWidget {
  final Tenant tenant;
  final VoidCallback onConfirm;

  const DeleteTenantDialog({
    super.key,
    required this.tenant,
    required this.onConfirm,
  });

  @override
  State<DeleteTenantDialog> createState() => _DeleteTenantDialogState();
}

class _DeleteTenantDialogState extends State<DeleteTenantDialog> {
  final _inputController = TextEditingController();
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_checkMatch);
  }

  @override
  void dispose() {
    _inputController.removeListener(_checkMatch);
    _inputController.dispose();
    super.dispose();
  }

  void _checkMatch() {
    final match = _inputController.text.trim() == widget.tenant.name.trim();
    if (match != _isMatch) {
      setState(() => _isMatch = match);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      title: 'Удалить заведение навсегда?',
      icon: PhosphorIconsRegular.trash,
      isDestructive: true,
      width: 480,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Вы собираетесь БЕЗВОЗВРАТНО удалить заведение «${widget.tenant.name}» (ID #${widget.tenant.id}).\n\n'
            'Будет полностью уничтожена схема PostgreSQL «${widget.tenant.schemaName}» со всеми чеками, заказами, складом и сотрудниками.',
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.4,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Для подтверждения введите точное название заведения:',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _inputController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              hintText: widget.tenant.name,
              hintStyle: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _isMatch ? AppColors.danger : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        AppSecondaryButton(
          label: 'Отмена',
          size: AppButtonSize.md,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppDangerButton(
          label: 'Удалить навсегда',
          size: AppButtonSize.md,
          onPressed: _isMatch
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
        ),
      ],
    );
  }
}
