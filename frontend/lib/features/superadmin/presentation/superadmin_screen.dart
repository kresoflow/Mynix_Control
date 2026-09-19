import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'bloc/superadmin_bloc.dart';
import 'widgets/create_tenant_modal.dart';
import 'widgets/tenant_card.dart';
import 'widgets/superadmin_error_view.dart';

class SuperadminScreen extends StatefulWidget {
  final String systemToken;
  const SuperadminScreen({super.key, required this.systemToken});

  @override
  State<SuperadminScreen> createState() => _SuperadminScreenState();
}

class _SuperadminScreenState extends State<SuperadminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _statusFilter = 0; // 0: All, 1: Active, 2: Suspended

  @override
  void initState() {
    super.initState();
    context.read<SuperadminBloc>().setTokenAndLoad(widget.systemToken);
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateTenantModal() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SuperadminBloc>(),
        child: const CreateTenantModal(),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Выйти из консоли?',
        icon: PhosphorIconsRegular.signOut,
        isDestructive: true,
        content: Text('Вы действительно хотите выйти из консоли суперадминистратора? Сессия будет завершена.', style: AppTextStyles.bodyMedium),
        actions: [
          AppSecondaryButton(label: 'Отмена', size: AppButtonSize.md, onPressed: () => Navigator.pop(ctx)),
          const SizedBox(width: 8),
          AppDangerButton(
            label: 'Выйти',
            size: AppButtonSize.md,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
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
            final isToken = state.message.contains('Invalid System Admin Token');
            AppToast.showError(context, 'Ошибка суперадмина', subtitle: isToken ? 'Неверный системный мастер-токен (403)' : state.message);
          }
        },
        builder: (context, state) {
          if (state is SuperadminLoading) return const Center(child: CircularProgressIndicator());

          if (state is SuperadminError) {
            return SuperadminErrorView(
              message: state.message,
              onRetry: () => context.read<SuperadminBloc>().loadTenants(),
              onBack: () => Navigator.pop(context),
            );
          }

          final allTenants = state is SuperadminLoaded ? state.tenants : <Tenant>[];
          final activeCount = allTenants.where((t) => t.isActive).length;
          var tenants = _searchQuery.isEmpty
              ? allTenants
              : allTenants.where(
                  (t) =>
                      t.name.toLowerCase().contains(_searchQuery) ||
                      t.schemaName.toLowerCase().contains(_searchQuery) ||
                      t.address.toLowerCase().contains(_searchQuery),
                ).toList();
          if (_statusFilter == 1) tenants = tenants.where((t) => t.isActive).toList();
          if (_statusFilter == 2) tenants = tenants.where((t) => !t.isActive).toList();

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
                            decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                            child: Icon(PhosphorIconsRegular.crown, color: AppColors.brandPrimary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Superadmin Console', style: AppTextStyles.h2.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
                              Text('Управление мульти-тенант кластером и базами данных', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(PhosphorIconsRegular.arrowsClockwise), tooltip: 'Обновить список', onPressed: () => context.read<SuperadminBloc>().loadTenants()),
                          const SizedBox(width: 8),
                          AppPrimaryButton(label: 'Добавить ресторан', icon: PhosphorIconsRegular.plus, size: AppButtonSize.md, onPressed: _showCreateTenantModal),
                          const SizedBox(width: 8),
                          AppSecondaryButton(label: 'Выход', icon: PhosphorIconsRegular.signOut, size: AppButtonSize.md, onPressed: _confirmExit),
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
                      _buildMetricCard('Всего точек', '${allTenants.length}', PhosphorIconsRegular.storefront, AppColors.brandPrimary, isDark),
                      const SizedBox(width: 16),
                      _buildMetricCard('Активных точек', '$activeCount', PhosphorIconsRegular.checkCircle, AppColors.success, isDark),
                      const SizedBox(width: 16),
                      _buildMetricCard('PostgreSQL Schemas', '${allTenants.length}', PhosphorIconsRegular.database, AppColors.info, isDark),
                    ],
                  ),
                ),
              ),

              // Tenants List Title & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
                  child: Row(
                    children: [
                      Text('Список заведений (Tenants)', style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 230,
                        height: 36,
                        child: TextField(
                          controller: _searchController,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Поиск заведения...',
                            hintStyle: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 14),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildFilterChip('Все', 0, allTenants.length, isDark),
                      const SizedBox(width: 6),
                      _buildFilterChip('Активные', 1, activeCount, isDark),
                      const SizedBox(width: 6),
                      _buildFilterChip('Замороженные', 2, allTenants.length - activeCount, isDark),
                      const Spacer(),
                      Text('Нажмите на заведение для инспекции БД', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
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
                        Icon(PhosphorIconsRegular.buildings, size: 48, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        const SizedBox(height: 12),
                        Text('Заведения не найдены', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('Попробуйте изменить поисковый запрос или фильтр', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TenantCard(tenant: tenants[index], systemToken: widget.systemToken),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                Text(val, style: AppTextStyles.h2.copyWith(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int filterIndex, int count, bool isDark) {
    final isSelected = _statusFilter == filterIndex;
    final color = isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _statusFilter = filterIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.2 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Text('$label ($count)', style: AppTextStyles.caption.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: color)),
      ),
    );
  }
}
