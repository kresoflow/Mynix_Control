import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../bloc/superadmin_bloc.dart';
import '../bloc/tenant_explorer_bloc.dart';
import '../tenant_explorer_screen.dart';
import 'delete_tenant_dialog.dart';
import 'edit_tenant_modal.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final String systemToken;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.systemToken,
  });

  void _openInspector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => TenantExplorerBloc(
            repository: context.read<SuperadminBloc>().repository,
            systemToken: systemToken,
            schemaName: tenant.schemaName,
          ),
          child: TenantExplorerScreen(tenantName: tenant.name),
        ),
      ),
    );
  }

  void _confirmToggleStatus(BuildContext context) {
    final willFreeze = tenant.isActive;
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
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
          AppSecondaryButton(label: 'Отмена', size: AppButtonSize.md, onPressed: () => Navigator.pop(ctx)),
          const SizedBox(width: 8),
          if (willFreeze)
            AppDangerButton(
              label: 'Заморозить',
              size: AppButtonSize.md,
              onPressed: () {
                Navigator.pop(ctx);
                context.read<SuperadminBloc>().toggleTenantStatus(tenant.id, false);
              },
            )
          else
            AppPrimaryButton(
              label: 'Активировать',
              size: AppButtonSize.md,
              onPressed: () {
                Navigator.pop(ctx);
                context.read<SuperadminBloc>().toggleTenantStatus(tenant.id, true);
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DeleteTenantDialog(
        tenant: tenant,
        onConfirm: () => context.read<SuperadminBloc>().deleteTenant(tenant.id),
      ),
    );
  }

  void _openEditModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditTenantModal(
        tenant: tenant,
        onSave: (name, address, useKds, enableInventoryDeduction) {
          context.read<SuperadminBloc>().updateTenant(
            tenantId: tenant.id,
            name: name,
            address: address,
            useKds: useKds,
            enableInventoryDeduction: enableInventoryDeduction,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final createdDate = tenant.createdAt.isNotEmpty ? tenant.createdAt.split('T').first : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openInspector(context),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '#${tenant.id}',
                        style: AppTextStyles.h3.copyWith(color: AppColors.brandPrimary),
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
                            Text(tenant.name, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                            const SizedBox(width: 10),
                            if (tenant.useKds) _buildBadge('KDS', AppColors.brandSecondary, isDark),
                            if (tenant.enableInventoryDeduction) ...[
                              const SizedBox(width: 6),
                              _buildBadge('Склад', AppColors.brandTertiary, isDark),
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
                            Icon(
                              PhosphorIconsRegular.mapPin,
                              size: 14,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
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

                  // Action: DB Inspector Button
                  AppSecondaryButton(
                    label: 'Инспектор БД',
                    icon: PhosphorIconsRegular.database,
                    size: AppButtonSize.sm,
                    onPressed: () => _openInspector(context),
                  ),
                  const SizedBox(width: 8),

                  // Action: Edit Tenant Button
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.info),
                    tooltip: 'Редактировать параметры',
                    onPressed: () => _openEditModal(context),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 4),

                  // Action: Toggle Status Badge with confirmation
                  Tooltip(
                    message: tenant.isActive ? 'Заморозить работу заведения' : 'Активировать заведение',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _confirmToggleStatus(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (tenant.isActive ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: (tenant.isActive ? AppColors.success : AppColors.danger).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: tenant.isActive ? AppColors.success : AppColors.danger)),
                            const SizedBox(width: 6),
                            Text(
                              tenant.isActive ? 'Активен' : 'Отключен',
                              style: AppTextStyles.caption.copyWith(color: tenant.isActive ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Action: Delete Tenant Button
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

  Widget _buildBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
