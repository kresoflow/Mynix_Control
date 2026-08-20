import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'bloc/superadmin_bloc.dart';
import 'widgets/create_tenant_modal.dart';
import 'widgets/tenant_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      body: BlocConsumer<SuperadminBloc, SuperadminState>(
        listener: (context, state) {
          if (state is SuperadminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SuperadminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tenants = state is SuperadminLoaded ? state.tenants : <Tenant>[];
          final activeCount = tenants.where((t) => t.isActive).length;

          return CustomScrollView(
            slivers: [
              // Top Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.crown,
                              color: AppColors.brandPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Superadmin Console', style: AppTextStyles.h2),
                              Text(
                                'Управление мульти-тенант кластером и базами данных',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                            tooltip: 'Обновить список',
                            onPressed: () => context.read<SuperadminBloc>().loadTenants(),
                          ),
                          const SizedBox(width: 8),
                          AppPrimaryButton(
                            label: 'Добавить ресторан',
                            icon: PhosphorIconsRegular.plus,
                            onPressed: _showCreateTenantModal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // KPI Metrics Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildMetricCard(
                        'Всего точек',
                        '${tenants.length}',
                        PhosphorIconsRegular.storefront,
                        AppColors.brandPrimary,
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        'Активных точек',
                        '$activeCount',
                        PhosphorIconsRegular.checkCircle,
                        AppColors.success,
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        'PostgreSQL Schemas',
                        '${tenants.length}',
                        PhosphorIconsRegular.database,
                        Colors.blueAccent,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // Tenants List Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
                  child: Row(
                    children: [
                      Text('Список заведений (Tenants)', style: AppTextStyles.h3),
                      const Spacer(),
                      Text(
                        'Нажмите на заведение для инспекции БД',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tenants List or Empty State
              if (tenants.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.buildings,
                          size: 64,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                        const SizedBox(height: 16),
                        Text('Нет зарегистрированных точек', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите «Добавить ресторан», чтобы инициализировать тенант',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TenantCard(
                        tenant: tenants[index],
                        systemToken: widget.systemToken,
                      ),
                      childCount: tenants.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 2),
                Text(val, style: AppTextStyles.h2.copyWith(fontSize: 22)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
