import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SuperadminBloc>(),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const CreateTenantModal(),
        ),
      ),
    );
  }

  Widget _buildTenantCard(Tenant t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    
    return GestureDetector(
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '#${t.id}', 
                  style: AppTextStyles.h2.copyWith(color: AppColors.brandPrimary)
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(PhosphorIcons.database(), size: 14, color: AppColors.darkSubtext),
                      const SizedBox(width: 4),
                      Text(t.schemaName, style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
                      const SizedBox(width: 12),
                      Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.darkSubtext),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(t.address, 
                                    style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis),
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
                color: t.isActive ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.isActive ? AppColors.success.withOpacity(0.3) : AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
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
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.darkBg 
          : AppColors.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill), color: AppColors.brandPrimary),
            const SizedBox(width: 8),
            Text('Панель Управления (Mynix System)', style: AppTextStyles.h2),
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
                  Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), color: AppColors.danger, size: 48),
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
                            Text('Рестораны в сети', style: AppTextStyles.h1),
                            const SizedBox(height: 4),
                            Text('Всего клиентов: ${tenants.length}', 
                                 style: AppTextStyles.body.copyWith(color: AppColors.darkSubtext)),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: Icon(PhosphorIcons.plus()),
                          label: Text('Новый Ресторан', style: AppTextStyles.button),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _showCreateTenantModal,
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (tenants.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.storefront(), size: 64, color: AppColors.darkSubtext.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('Нет зарегистрированных ресторанов', style: AppTextStyles.h3.copyWith(color: AppColors.darkSubtext)),
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
