// ============================================================================
// Kreso Flow | Superadmin View | Tenant Card Widget
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import '../../models/tenant.dart';
import '../../bloc/superadmin_bloc.dart';
import '../../bloc/tenant_explorer_bloc.dart';
import '../tenant_explorer_screen.dart';
import 'delete_tenant_dialog.dart';
import 'edit_tenant_modal.dart';
import 'tenant_status_badge.dart';

// ─── 1. Tenant Overview Card ────────────────────────────────────────────────

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final String systemToken;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.systemToken,
  });

  void _openInspector(BuildContext context) {
    final repo = context.read<SuperadminBloc>().repository;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => TenantExplorerBloc(
            repository: repo,
            systemToken: systemToken,
            schemaName: tenant.schemaName,
          ),
          child: TenantExplorerScreen(tenantName: tenant.name),
        ),
      ),
    );
  }

  Future<void> _confirmToggleStatus(BuildContext context) async {
    final willFreeze = tenant.isActive;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: willFreeze ? 'Приостановить заведение?' : 'Активировать заведение?',
      message: willFreeze
          ? 'Заведение «${tenant.name}» будет заморожено. Персонал потеряет доступ к кассе и не сможет пробивать заказы.'
          : 'Доступ к POS-терминалам и заказам заведения «${tenant.name}» будет немедленно восстановлен.',
      confirmLabel: willFreeze ? 'Заморозить' : 'Активировать',
      confirmIcon: willFreeze ? PhosphorIconsRegular.pauseCircle : PhosphorIconsRegular.playCircle,
      cancelLabel: 'Отмена',
      isDanger: willFreeze,
      icon: willFreeze ? PhosphorIconsRegular.pauseCircle : PhosphorIconsRegular.playCircle,
    );

    if (confirmed == true && context.mounted) {
      context
          .read<SuperadminBloc>()
          .toggleTenantStatus(tenant.id, !tenant.isActive);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DeleteTenantDialog(
        tenant: tenant,
        onConfirm: () =>
            context.read<SuperadminBloc>().deleteTenant(tenant.id),
      ),
    );
  }

  void _openEditModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditTenantModal(
        tenant: tenant,
        onSave: ({
          required name,
          required address,
          required currency,
          required isActive,
          required useKds,
          required useOrders,
          required enableInventoryDeduction,
          ownerFullName,
          ownerPhone,
          ownerEmail,
          ownerPassword,
          ownerPinCode,
        }) {
          context.read<SuperadminBloc>().updateTenant(
            tenantId: tenant.id,
            name: name,
            address: address,
            currency: currency,
            isActive: isActive,
            useKds: useKds,
            useOrders: useOrders,
            enableInventoryDeduction: enableInventoryDeduction,
            ownerFullName: ownerFullName,
            ownerPhone: ownerPhone,
            ownerEmail: ownerEmail,
            ownerPassword: ownerPassword,
            ownerPinCode: ownerPinCode,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final createdDate = tenant.createdAt.isNotEmpty
        ? tenant.createdAt.split('T').first
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: () => _openInspector(context),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: isDark ? null : AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: AppRadii.radiusXl,
                    ),
                    child: Center(
                      child: Text(
                        '#${tenant.id}',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tenant.name,
                              style: AppTextStyles.h3.copyWith(fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            if (tenant.enableInventoryDeduction) ...[
                              const SizedBox(width: 6),
                              TenantBadge(label: 'Склад', color: AppColors.brandTertiary, isDark: isDark),
                            ],
                            if (tenant.useOrders) ...[
                              const SizedBox(width: 6),
                              TenantBadge(label: 'Заказы', color: AppColors.info, isDark: isDark),
                            ],
                            if (tenant.currency.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              TenantBadge(label: tenant.currency, color: AppColors.brandPrimary, isDark: isDark),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(PhosphorIconsRegular.database, size: 14, color: AppColors.brandPrimary),
                            const SizedBox(width: 4),
                            Text(
                              tenant.schemaName,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(PhosphorIconsRegular.mapPin, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tenant.address.isNotEmpty ? tenant.address : 'Адрес не указан',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (createdDate.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                'Создан: $createdDate',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  AppSecondaryButton(
                    label: 'Инспектор БД',
                    icon: PhosphorIconsRegular.database,
                    size: AppButtonSize.sm,
                    onPressed: () => _openInspector(context),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.info),
                    tooltip: 'Редактировать параметры',
                    onPressed: () => _openEditModal(context),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 4),
                  TenantStatusToggle(
                    isActive: tenant.isActive,
                    onToggle: () => _confirmToggleStatus(context),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                    tooltip: 'Удалить заведение навсегда',
                    onPressed: () => _confirmDelete(context),
                    splashRadius: 20,
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
