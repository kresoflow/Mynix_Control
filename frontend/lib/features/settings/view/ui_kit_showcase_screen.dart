import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UiKitShowcaseScreen extends StatefulWidget {
  const UiKitShowcaseScreen({super.key});

  @override
  State<UiKitShowcaseScreen> createState() => _UiKitShowcaseScreenState();
}

class _UiKitShowcaseScreenState extends State<UiKitShowcaseScreen> {
  String _selectedMenuItem = 'None';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AppPageHeader(
              title: 'Mynix UI Kit & Design System Gallery',
              subtitle: 'Живая витрина стандартизированных компонентов, размеров и токенов',
              kpiChips: const [
                AppKpiChip(icon: PhosphorIconsRegular.cube, label: '5 Размеров кнопок'),
                AppKpiChip(icon: PhosphorIconsRegular.palette, label: 'Design Tokens 100%'),
                AppKpiChip(icon: PhosphorIconsRegular.checkCircle, label: 'Zero Hardcode', isHighlighted: true),
              ],
              actions: [
                AppMenuButton(
                  label: 'Действия UI Kit',
                  icon: PhosphorIconsRegular.dotsThreeOutline,
                  size: AppButtonSize.md,
                  items: const [
                    AppMenuItem(id: 'refresh', label: 'Перезагрузить токены', icon: PhosphorIconsRegular.arrowsClockwise),
                    AppMenuItem(id: 'copy_spec', label: 'Скопировать DESIGN.md', icon: PhosphorIconsRegular.copy),
                    AppMenuDivider(),
                    AppMenuItem(id: 'reset', label: 'Сброс', icon: PhosphorIconsRegular.trash, isDestructive: true),
                  ],
                  onSelected: (val) => setState(() => _selectedMenuItem = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Section 1: Button Size Matrix ───────────────────────────
            _buildSectionCard(
              title: '1. Шкала размеров кнопок (AppButtonSize: XS, SM, MD, LG, XL)',
              description: 'Строгие высоты (28, 32, 36, 44, 52px). Никаких промежуточных значений.',
              isDark: isDark,
              child: Column(
                children: [
                  // Size Headers
                  _buildSizeRow(
                    label: 'Primary:',
                    builder: (size) => AppPrimaryButton(
                      label: size.name.toUpperCase(),
                      icon: PhosphorIconsRegular.plus,
                      size: size,
                      onPressed: () => AppToast.showInfo(context, 'Нажата кнопка ${size.name.toUpperCase()}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeRow(
                    label: 'Secondary:',
                    builder: (size) => AppSecondaryButton(
                      label: size.name.toUpperCase(),
                      icon: PhosphorIconsRegular.gear,
                      size: size,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeRow(
                    label: 'Ghost:',
                    builder: (size) => AppGhostButton(
                      label: size.name.toUpperCase(),
                      icon: PhosphorIconsRegular.x,
                      size: size,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeRow(
                    label: 'Danger:',
                    builder: (size) => AppDangerButton(
                      label: size.name.toUpperCase(),
                      icon: PhosphorIconsRegular.trash,
                      size: size,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeRow(
                    label: 'Loading:',
                    builder: (size) => AppPrimaryButton(
                      label: size.name.toUpperCase(),
                      size: size,
                      isLoading: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeRow(
                    label: 'Disabled:',
                    builder: (size) => AppPrimaryButton(
                      label: size.name.toUpperCase(),
                      size: size,
                      onPressed: null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 2: AppMenuButton ────────────────────────────────
            _buildSectionCard(
              title: '2. Выпадающие кнопки действий (AppMenuButton)',
              description: 'Единая кнопка со встроенным попапом действий (замена громоздким PopupMenuButton).',
              isDark: isDark,
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppMenuButton(
                    label: 'Добавить в меню',
                    icon: PhosphorIconsRegular.plus,
                    size: AppButtonSize.md,
                    items: const [
                      AppMenuItem(id: 'dish', label: 'Блюдо', icon: PhosphorIconsRegular.hamburger, shortcut: 'Ctrl+B'),
                      AppMenuItem(id: 'category', label: 'Категория блюд', icon: PhosphorIconsRegular.folderPlus),
                      AppMenuDivider(),
                      AppMenuItem(id: 'bulk', label: 'Пакетный ввод', icon: PhosphorIconsRegular.table),
                    ],
                    onSelected: (val) => setState(() => _selectedMenuItem = 'Menu: $val'),
                  ),
                  AppMenuButton(
                    label: 'Складские действия',
                    icon: PhosphorIconsRegular.archive,
                    size: AppButtonSize.md,
                    variant: AppButtonVariant.secondary,
                    items: const [
                      AppMenuItem(id: 'receive', label: 'Оформить приход', icon: PhosphorIconsRegular.truck),
                      AppMenuItem(id: 'writeoff', label: 'Списание сырья', icon: PhosphorIconsRegular.trashSimple),
                      AppMenuItem(id: 'inventory', label: 'Инвентаризация', icon: PhosphorIconsRegular.clipboardText),
                    ],
                    onSelected: (val) => setState(() => _selectedMenuItem = 'Warehouse: $val'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Выбрано: $_selectedMenuItem',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 3: Status Badges & KPI Chips ────────────────────
            _buildSectionCard(
              title: '3. Бейджи статусов и индикаторы (AppStatusBadge & AppKpiChip)',
              description: 'Семантическая индикация состояний с мягкой прозрачностью и контрастным текстом.',
              isDark: isDark,
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: const [
                  AppStatusBadge(label: 'Оплачен', variant: AppBadgeVariant.success, icon: PhosphorIconsRegular.checkCircle),
                  AppStatusBadge(label: 'На исходе', variant: AppBadgeVariant.warning, icon: PhosphorIconsRegular.warningCircle),
                  AppStatusBadge(label: 'Долг / Ошибка', variant: AppBadgeVariant.danger, icon: PhosphorIconsRegular.xCircle),
                  AppStatusBadge(label: 'В обработке', variant: AppBadgeVariant.info, icon: PhosphorIconsRegular.info),
                  AppStatusBadge(label: 'Смена открыта', variant: AppBadgeVariant.brand, hasDot: true),
                  AppStatusBadge(label: 'В архиве', variant: AppBadgeVariant.neutral),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 4: Search & Form Controls ───────────────────────
            _buildSectionCard(
              title: '4. Поиск и Инпуты (AppSearchField)',
              description: 'Единая высота 36px (соответствует AppButtonSize.md) для идеального выравнивания в тулбарах.',
              isDark: isDark,
              child: Row(
                children: [
                  AppSearchField(
                    controller: _searchCtrl,
                    hintText: 'Поиск по блюдам или SKU...',
                    width: 300,
                  ),
                  const SizedBox(width: 12),
                  AppPrimaryButton(
                    label: 'Найти',
                    icon: PhosphorIconsRegular.magnifyingGlass,
                    size: AppButtonSize.md,
                    onPressed: () => AppToast.showSuccess(context, 'Поиск: ${_searchCtrl.text}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 5: Dialogs & Alerts ─────────────────────────────
            _buildSectionCard(
              title: '5. Диалоговые окна и Тосты (MynixDialog & AppToast)',
              description: 'Глубокие тени, Backdrop Blur 8px, кнопки размера LG (44-48px).',
              isDark: isDark,
              child: Wrap(
                spacing: 12,
                children: [
                  AppPrimaryButton(
                    label: 'Открыть тестовый диалог',
                    icon: PhosphorIconsRegular.browsers,
                    size: AppButtonSize.md,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => MynixDialog(
                          title: 'Стандартный Mynix Dialog',
                          icon: PhosphorIconsRegular.sparkle,
                          content: const Text(
                            'Это диалоговое окно использует скругления AppRadii.dialog (20px), кнопки размера LG и мягкие тени.',
                          ),
                          actions: [
                            AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
                            const SizedBox(width: 8),
                            AppPrimaryButton(label: 'Подтвердить', onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                      );
                    },
                  ),
                  AppSecondaryButton(
                    label: 'Уведомление (Toast)',
                    icon: PhosphorIconsRegular.bell,
                    size: AppButtonSize.md,
                    onPressed: () => AppToast.showSuccess(context, 'Успешно обновлено!'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 6: Navigation & Category Tiles (AppNavTile) ──────
            _buildSectionCard(
              title: '6. Элементы списков и деревьев (AppNavTile: SM, MD, LG)',
              description: 'Унифицированный компонент для сайдбаров, категорий склада, техкарт и настроек.',
              isDark: isDark,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Size SM
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SM (32px) — Вложенные папки', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          AppNavTile(
                            title: 'Мясо и птица',
                            count: 12,
                            size: AppNavTileSize.sm,
                            isExpandable: true,
                            isExpanded: true,
                            isSelected: false,
                            onTap: () {},
                          ),
                          AppNavTile(
                            title: 'Говядина вырезка',
                            size: AppNavTileSize.sm,
                            depth: 1,
                            isSelected: true,
                            onTap: () {},
                          ),
                          AppNavTile(
                            title: 'Куриное филе',
                            size: AppNavTileSize.sm,
                            depth: 1,
                            isSelected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Size MD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MD (38px) — Стандарт категорий', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          AppNavTile(
                            title: 'ВСЕ СЫРЬЕ',
                            count: 48,
                            size: AppNavTileSize.md,
                            isSelected: true,
                            onTap: () {},
                          ),
                          AppNavTile(
                            title: 'Бургеры и снеки',
                            icon: PhosphorIconsRegular.hamburger,
                            count: 14,
                            size: AppNavTileSize.md,
                            isSelected: false,
                            onTap: () {},
                          ),
                          AppNavTile(
                            title: 'Холодные напитки',
                            icon: PhosphorIconsRegular.brandy,
                            count: 8,
                            size: AppNavTileSize.md,
                            isSelected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Size LG
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LG (48px) — Сайдбар / Настройки', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          AppNavTile(
                            title: 'Основные настройки',
                            subtitle: 'KDS, склад, чеки',
                            icon: PhosphorIconsRegular.sliders,
                            size: AppNavTileSize.lg,
                            isSelected: true,
                            onTap: () {},
                          ),
                          AppNavTile(
                            title: 'Оборудование',
                            subtitle: 'Принтеры и фискал',
                            icon: PhosphorIconsRegular.printer,
                            size: AppNavTileSize.lg,
                            isSelected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSizeRow({
    required String label,
    required Widget Function(AppButtonSize size) builder,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppButtonSize.values.map((size) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: builder(size),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
