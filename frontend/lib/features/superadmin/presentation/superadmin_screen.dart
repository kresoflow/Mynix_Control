import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'bloc/superadmin_bloc.dart';
import 'bloc/tenant_explorer_bloc.dart';
import 'tenant_explorer_screen.dart';
import 'widgets/create_tenant_modal.dart';

class SuperadminScreen extends StatefulWidget {
  final String systemToken;

  const SuperadminScreen({super.key, required this.systemToken});

  @override
  State<SuperadminScreen> createState() => _SuperadminScreenState();
}

class _SuperadminScreenState extends State<SuperadminScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SuperadminBloc>().setTokenAndLoad(widget.systemToken);
  }

  void _showCreateTenantModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => BlocProvider.value(
        value: context.read<SuperadminBloc>(),
        child: const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: CreateTenantModal(),
        ),
      ),
    );
  }

  Widget _buildTenantCard(Tenant t) {
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
                    systemToken: widget.systemToken,
                    schemaName: t.schemaName,
                  ),
                  child: TenantExplorerScreen(tenantName: t.name),
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
                        '#${t.id}',
                        style: AppTextStyles.h3.copyWith(color: AppColors.brandPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: AppTextStyles.h3.copyWith(fontSize: 16)),
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
                              t.schemaName,
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
                                t.address.isNotEmpty ? t.address : 'Адрес не указан',
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
                      color: t.isActive
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: t.isActive
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
                            color: t.isActive ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.isActive ? 'Активен' : 'Отключен',
                          style: AppTextStyles.caption.copyWith(
                            color: t.isActive ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(PhosphorIconsRegular.shieldCheck, color: AppColors.brandPrimary),
            const SizedBox(width: 10),
            Text(
              'Панель Управления (Mynix System)',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<SuperadminBloc, SuperadminState>(
        builder: (context, state) {
          if (state is SuperadminLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SuperadminError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsRegular.warningCircle, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(state.message, style: AppTextStyles.body.copyWith(color: AppColors.danger)),
                ],
              ),
            );
          } else if (state is SuperadminLoaded) {
            final tenants = state.tenants;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Рестораны в сети',
                              style: AppTextStyles.h2.copyWith(
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Всего клиентов: ${tenants.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                        AppPrimaryButton(
                          label: 'Новый Ресторан',
                          icon: PhosphorIconsRegular.plus,
                          onPressed: _showCreateTenantModal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (tenants.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIconsRegular.storefront,
                                size: 64,
                                color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет зарегистрированных ресторанов',
                                style: AppTextStyles.h3.copyWith(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: tenants.length,
                          itemBuilder: (context, index) {
                            return _buildTenantCard(tenants[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
