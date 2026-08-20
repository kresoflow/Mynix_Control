import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../bloc/superadmin_bloc.dart';
import '../bloc/tenant_explorer_bloc.dart';
import '../tenant_explorer_screen.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final String systemToken;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.systemToken,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
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
          },
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
                        Text(tenant.name, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.database,
                              size: 14,
                              color: AppColors.brandPrimary,
                            ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tenant.isActive
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tenant.isActive
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tenant.isActive ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tenant.isActive ? 'Активен' : 'Отключен',
                          style: AppTextStyles.caption.copyWith(
                            color: tenant.isActive ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    size: 18,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
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
