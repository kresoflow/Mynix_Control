import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  static const List<_HubModule> _modules = [
    _HubModule(
      title: 'Кухня (KDS)',
      subtitle: 'Экран заказов повара и сборки',
      icon: PhosphorIconsRegular.cookingPot,
      route: '/kitchen',
      color: Color(0xFFF97316),
    ),
    _HubModule(
      title: 'Каталог меню',
      subtitle: 'Блюда, модификаторы и цены',
      icon: PhosphorIconsRegular.bookOpen,
      route: '/catalog',
      color: Color(0xFF10B981),
    ),
    _HubModule(
      title: 'Склад & Приходы',
      subtitle: 'Остатки, накладные, списания',
      icon: PhosphorIconsRegular.package,
      route: '/warehouse',
      color: Color(0xFF6366F1),
    ),
    _HubModule(
      title: 'CRM & Гости',
      subtitle: 'База клиентов, скидки и балансы',
      icon: PhosphorIconsRegular.usersThree,
      route: '/crm',
      color: Color(0xFFEC4899),
    ),
    _HubModule(
      title: 'Аналитика',
      subtitle: 'Выручка, графики и средний чек',
      icon: PhosphorIconsRegular.chartLineUp,
      route: '/analytics',
      color: Color(0xFF06B6D4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'База и модули',
                      style: AppTextStyles.h1.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Быстрый доступ к управлению заведением',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final module = _modules[index];
                    return _buildModuleCard(context, module, isDark);
                  },
                  childCount: _modules.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, _HubModule module, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(module.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: module.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module.subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
    );
  }
}

class _HubModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  const _HubModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });
}
