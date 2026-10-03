// ============================================================================
// Kreso Flow | Superadmin View | Toggle Tenant Status Dialog
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import '../../models/tenant.dart';

// ─── 1. Status Toggle Confirmation Dialog ───────────────────────────────────

class ToggleTenantStatusDialog extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onConfirm;

  const ToggleTenantStatusDialog({
    super.key,
    required this.tenant,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final willFreeze = tenant.isActive;

    return AppDialog(
      title: willFreeze ? 'Приостановить заведение?' : 'Активировать заведение?',
      icon: willFreeze ? PhosphorIconsRegular.pauseCircle : PhosphorIconsRegular.playCircle,
      isDestructive: willFreeze,
      content: Text(
        willFreeze
            ? 'Заведение «${tenant.name}» будет заморожено. Персонал потеряет доступ к кассе и не сможет пробивать заказы.'
            : 'Доступ к POS-терминалам и заказам заведения «${tenant.name}» будет немедленно восстановлен.',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        AppSecondaryButton(
          label: 'Отмена',
          size: AppButtonSize.md,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        if (willFreeze)
          AppDangerButton(
            label: 'Заморозить',
            size: AppButtonSize.md,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          )
        else
          AppPrimaryButton(
            label: 'Активировать',
            size: AppButtonSize.md,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
      ],
    );
  }
}
