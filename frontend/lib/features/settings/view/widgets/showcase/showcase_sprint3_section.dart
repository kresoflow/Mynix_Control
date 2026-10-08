// ==============================================================================
// МОДУЛЬ: Настройки / Витрина UI Kit / Секция компонентов Спринта 3
// ДОМЕН: lib/features/settings/view/widgets/showcase/showcase_sprint3_section.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// Витрина новых компонентов Спринта 3 (Approval Gate 2).
class ShowcaseSprint3Section extends StatefulWidget {
  final bool isDark;

  const ShowcaseSprint3Section({super.key, required this.isDark});

  @override
  State<ShowcaseSprint3Section> createState() => _ShowcaseSprint3SectionState();
}

class _ShowcaseSprint3SectionState extends State<ShowcaseSprint3Section> {
  int _selectedTableRow = 1;

  final _tableColumns = const [
    AppDataTableColumn(label: '№', width: 36, alignment: Alignment.center),
    AppDataTableColumn(label: 'Номенклатура', flex: 3),
    AppDataTableColumn(label: 'Категория', flex: 2),
    AppDataTableColumn(label: 'Остаток', width: 90, alignment: Alignment.centerRight),
    AppDataTableColumn(label: 'Статус', width: 110, alignment: Alignment.center),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Шапка секции ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10. Продвинутые данные и документы (Approval Gate: Спринт 3)',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AppKpiCard, AppDataTable и AppDocumentFooter для согласования стандартов.',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              const AppStatusBadge(
                label: 'На согласовании',
                variant: AppBadgeVariant.warning,
                hasDot: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── БЛОК 1: AppKpiCard ────────────────────────────────────────────
          Text(
            'Карточки метрик и KPI (AppKpiCard):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              final cards = [
                AppKpiCard(
                  title: 'Выручка за сегодня',
                  value: '142 850 с',
                  icon: PhosphorIconsRegular.chartLineUp,
                  color: AppColors.brandPrimary,
                  trend: const AppKpiTrend.up('+14.2%'),
                  subtitle: 'vs вчера',
                  onTap: () => AppToast.showInfo(context, 'Клик по KPI: Выручка'),
                ),
                AppKpiCard(
                  title: 'Долг клиентов',
                  value: '18 400 с',
                  icon: PhosphorIconsRegular.trendDown,
                  color: AppColors.danger,
                  trend: const AppKpiTrend.down('-5.1%'),
                  subtitle: '12 должников',
                  onTap: () => AppToast.showInfo(context, 'Клик по KPI: Долг'),
                ),
                AppKpiCard(
                  title: 'Средний чек',
                  value: '185 с',
                  icon: PhosphorIconsRegular.receipt,
                  color: AppColors.warning,
                  trend: const AppKpiTrend.neutral('0%'),
                  subtitle: '42 заказа',
                  onTap: () => AppToast.showInfo(context, 'Клик по KPI: Чек'),
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
                );
              }
              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── БЛОК 2: AppDataTable ──────────────────────────────────────────
          Text(
            'Стандартизированная таблица (AppDataTableHeader & AppDataTableRow):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Единые отступы, интерактивный hover, поддержка выбора строк и моноширинных чисел.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  AppDataTableHeader(columns: _tableColumns),
                  _buildTableRow(1, 'Кофе зерновой Espresso Roast', 'Сырье бар', '24.5 кг', AppBadgeVariant.success, 'В норме'),
                  _buildTableRow(2, 'Молоко 3.2% Parmalat 1 л', 'Молочка', '2 шт', AppBadgeVariant.warning, 'Мало'),
                  _buildTableRow(3, 'Сироп Карамель Monin 1 л', 'Сиропы', '-1 шт', AppBadgeVariant.danger, 'Дефицит'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── БЛОК 3: AppDocumentFooter ─────────────────────────────────────
          Text(
            'Панель итогов и действий документа (AppDocumentFooter):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Сквозной нижний бар для Прихода, Списания, Инвентаризации и Взаиморасчетов.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppDocumentFooter(
                totalAmount: 48520.0,
                itemCount: 14,
                cartCount: 12,
                currency: 'с',
                onCartTap: () => AppToast.showInfo(context, 'Открыть шторку-корзину'),
                onCancel: () => AppToast.showInfo(context, 'Отмена документа'),
                onSecondaryPressed: () => AppToast.showInfo(context, 'Сохранено в черновик'),
                onPrimaryPressed: () => AppToast.showInfo(context, 'Документ успешно проведен!'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, String name, String category, String stock, AppBadgeVariant variant, String statusLabel) {
    final isSelected = _selectedTableRow == index;

    return AppDataTableRow(
      columns: _tableColumns,
      isSelected: isSelected,
      onTap: () => setState(() => _selectedTableRow = index),
      children: [
        Text('$index', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(category, style: const TextStyle(fontSize: 12)),
        Text(stock, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Center(child: AppStatusBadge(label: statusLabel, variant: variant, height: 20)),
      ],
    );
  }
}
