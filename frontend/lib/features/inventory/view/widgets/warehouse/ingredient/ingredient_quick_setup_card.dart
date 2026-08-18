import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';

class IngredientQuickSetupCard extends StatelessWidget {
  final VoidCallback onSetupComplete;
  final bool isModal;

  const IngredientQuickSetupCard({
    super.key,
    required this.onSetupComplete,
    this.isModal = false,
  });

  static Future<void> showAsDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: IngredientQuickSetupCard(
          isModal: true,
          onSetupComplete: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  static const _fastFoodPreset = [
    {'name': 'Мясо и полуфабрикаты', 'icon': 'meat'},
    {'name': 'Хлеб и выпечка', 'icon': 'bread'},
    {'name': 'Молочка и сыры', 'icon': 'cheese'},
    {'name': 'Соусы и приправы', 'icon': 'drop'},
    {'name': 'Овощи и зелень', 'icon': 'plant'},
    {'name': 'Заморозка', 'icon': 'snowflake'},
    {'name': 'Масла и жиры', 'icon': 'dropHalf'},
    {'name': 'Упаковка и расходники', 'icon': 'package'},
  ];

  static const _restaurantExtra = [
    {'name': 'Рыба и морепродукты', 'icon': 'fishSimple'},
    {'name': 'Крупы и макароны', 'icon': 'grains'},
    {'name': 'Напитки', 'icon': 'beer'},
    {'name': 'Десертные ингредиенты', 'icon': 'cookie'},
  ];

  void _applyPreset(BuildContext context, List<Map<String, String>> preset) {
    final categories = preset.asMap().entries.map((entry) {
      return <String, dynamic>{
        'name': entry.value['name'],
        'category_type': 'ingredient',
        'parent_id': null,
        'sort_order': entry.key,
        'is_visible': true,
        'icon': 'icon:${entry.value['icon']}',
      };
    }).toList();

    context.read<CategoryBloc>().add(CreateCategoriesBulk(categories: categories));
    onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.clipboardText,
                    size: 44,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Быстрая настройка склада',
                    style: AppTextStyles.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Выберите готовый шаблон полок или создайте свои:',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _PresetCard(
                          emoji: '🍔',
                          title: 'Фастфуд',
                          subtitle: '8 категорий',
                          onTap: () => _applyPreset(context, _fastFoodPreset),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _PresetCard(
                          emoji: '🍝',
                          title: 'Ресторан',
                          subtitle: '12 категорий',
                          onTap: () => _applyPreset(context, [..._fastFoodPreset, ..._restaurantExtra]),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      if (isModal) Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => const BulkAddModal(initialTabIndex: 3),
                      );
                    },
                    icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                    label: const Text('Создать свои вручную'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      textStyle: AppTextStyles.button,
                    ),
                  ),
                ],
              ),
            ),
            if (isModal)
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.x,
                    size: 20,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _PresetCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppColors.brandPrimary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
