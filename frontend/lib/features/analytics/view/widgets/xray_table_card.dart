import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';

class XRayTableCard extends StatelessWidget {
  final List<XRayItem> items;

  const XRayTableCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Рентген продаж (Позиции)',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              Icon(PhosphorIconsRegular.chartLine, color: AppColors.brandPrimary),
            ],
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Нет продаж за выбранный период',
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            )
          else if (isDesktop)
            _buildDesktopTable(context, isDark)
          else
            _buildMobileList(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, bool isDark) {
    final currency = context.read<SettingsBloc>().state.currency;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
        child: DataTable(
          headingTextStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('НАЗВАНИЕ И ЦЕНА')),
            DataColumn(label: Text('ОПЦИИ')),
            DataColumn(label: Text('КАТЕГОРИЯ')),
            DataColumn(label: Text('КОЛИЧЕСТВО'), numeric: true),
            DataColumn(label: Text('ВЫРУЧКА'), numeric: true),
          ],
          rows: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final price = item.quantity > 0 ? (item.revenue / item.quantity).toStringAsFixed(0) : '0';

            return DataRow(
              cells: [
                DataCell(Text(
                  '${index + 1}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                )),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    Text(
                      '$price $currency',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                )),
                DataCell(Text(
                  item.options ?? '-',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.category, style: AppTextStyles.caption),
                )),
                DataCell(Text('${item.quantity} шт.', style: AppTextStyles.bodyMedium)),
                DataCell(Text(
                  '${item.revenue.toStringAsFixed(0)} $currency',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, bool isDark) {
    final currency = context.read<SettingsBloc>().state.currency;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      itemBuilder: (context, index) {
        final item = items[index];
        final price = item.quantity > 0 ? (item.revenue / item.quantity).toStringAsFixed(0) : '0';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                    if (item.options != null && item.options!.isNotEmpty && item.options != '-')
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(item.options!, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '$price $currency',
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.revenue.toStringAsFixed(0)} $currency',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity} шт.',
                    style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
