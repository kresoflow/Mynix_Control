// ==============================================================================
// МОДУЛЬ: Каталог / Детальная панель техкарты блюда
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe_details_panel.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'recipe/dialogs/ingredient_picker_dialog.dart';
import 'recipe/recipe_analytics_header.dart';
import 'recipe/recipe_variation_tabs.dart';
import 'recipe/recipe_specification_section.dart';

class RecipeDetailsPanel extends StatefulWidget {
  final int selectedMenuItemId;
  final VoidCallback? onBackToSummary;

  const RecipeDetailsPanel({
    super.key,
    required this.selectedMenuItemId,
    this.onBackToSummary,
  });

  @override
  State<RecipeDetailsPanel> createState() => _RecipeDetailsPanelState();
}

class _RecipeDetailsPanelState extends State<RecipeDetailsPanel> {
  int _selectedVariationIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveRecipe();
  }

  @override
  void didUpdateWidget(covariant RecipeDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMenuItemId != widget.selectedMenuItemId) {
      _selectedVariationIndex = 0;
      _loadActiveRecipe();
    }
  }

  void _loadActiveRecipe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetId = _getActiveTargetId();
      context.read<RecipeBloc>().add(LoadRecipe(targetId));
    });
  }

  int _getActiveTargetId() {
    final menuState = context.read<MenuBloc>().state;
    if (menuState is! MenuLoaded) return widget.selectedMenuItemId;

    final menuItem = menuState.items.where((i) => i.id == widget.selectedMenuItemId).firstOrNull;
    if (menuItem == null) return widget.selectedMenuItemId;

    final variations = menuItem.variations;
    if (variations != null && variations.isNotEmpty) {
      final safeIdx = _selectedVariationIndex.clamp(0, variations.length - 1);
      final varId = variations[safeIdx]['id'];
      if (varId is int) return varId;
    }
    return widget.selectedMenuItemId;
  }

  Future<void> _addIngredient(BuildContext context, int targetId) async {
    final ingState = context.read<IngredientBloc>().state;
    if (ingState is! IngredientLoaded) return;
    final available = ingState.ingredients.where((i) => !i.isRetail && !i.isArchived).toList();
    final selectedId = await IngredientPickerDialog.show(context, available);
    if (selectedId != null && context.mounted) {
      final ing = available.where((i) => i.id == selectedId).firstOrNull;
      final unit = ing?.unit.toString().toLowerCase() ?? '';
      final defaultQty = (unit.contains('kg') || unit.contains('кг') || unit.contains('l') || unit.contains('л'))
          ? 0.05
          : 1.0;
      context.read<RecipeBloc>().add(
            AddIngredientToRecipe(
              menuItemId: targetId,
              ingredientId: selectedId,
              quantity: defaultQty,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuState = context.watch<MenuBloc>().state;
    final menuItem = menuState is MenuLoaded
        ? menuState.items.where((i) => i.id == widget.selectedMenuItemId).firstOrNull
        : null;

    final variations = menuItem?.variations ?? [];
    final hasVariations = variations.isNotEmpty;
    final safeVarIdx = hasVariations ? _selectedVariationIndex.clamp(0, variations.length - 1) : 0;
    final activeVariation = hasVariations ? variations[safeVarIdx] : null;

    final double activePrice = hasVariations
        ? ((activeVariation?['price'] as num?)?.toDouble() ?? menuItem?.price ?? 0.0)
        : (menuItem?.price ?? 0.0);

    final int activeTargetId = hasVariations
        ? ((activeVariation?['id'] as int?) ?? widget.selectedMenuItemId)
        : widget.selectedMenuItemId;

    final String baseName = menuItem?.cleanName ?? '';
    final String varName = activeVariation?['name']?.toString() ?? '';
    final String displayName = hasVariations
        ? (varName.toLowerCase().contains(baseName.toLowerCase()) ? varName : '$baseName ($varName)')
        : (baseName.isNotEmpty ? baseName : 'Техкарта блюда');

    final currency = context.watch<SettingsBloc>().state.currency;

    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final bool isCurrentLoading = state is RecipeLoading || (state is RecipeLoaded && state.menuItemId != activeTargetId);
        final List<Map<String, dynamic>> currentRecipes = (state is RecipeLoaded && state.menuItemId == activeTargetId)
            ? state.recipes
            : const [];

        double totalCost = 0.0;
        for (var r in currentRecipes) {
          final double costPerUnit = (r['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
          final double qty = (r['quantity_required'] as num?)?.toDouble() ?? 0.0;
          totalCost += (costPerUnit * qty);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Шапка: Назад к сводке + Название блюда ────────────────────────
            Row(
              children: [
                if (widget.onBackToSummary != null) ...[
                  AppGhostButton(
                    label: 'К сводке фудкоста',
                    icon: PhosphorIconsRegular.arrowLeft,
                    size: AppButtonSize.sm,
                    onPressed: widget.onBackToSummary,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    displayName,
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Переключатель вариаций порций (Стандарт / Макс / VIP) ────────
            if (hasVariations)
              RecipeVariationTabs(
                variations: variations,
                selectedIndex: safeVarIdx,
                currency: currency,
                onSelectVariation: (idx) {
                  setState(() => _selectedVariationIndex = idx);
                  final targetChildId = (variations[idx]['id'] as int?) ?? widget.selectedMenuItemId;
                  context.read<RecipeBloc>().add(LoadRecipe(targetChildId));
                },
              ),

            // ── Финансовый KPI-стрип (Себестоимость, Цена, Маржа) ────────────
            RecipeAnalyticsHeader(
              totalCost: totalCost,
              price: activePrice,
              currency: currency,
            ),

            // ── Заголовок спецификации + Кнопка добавления сырья ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Состав и расход сырья (${currentRecipes.length})',
                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                ),
                AppPrimaryButton(
                  label: 'Добавить ингредиент',
                  icon: PhosphorIconsRegular.plus,
                  size: AppButtonSize.sm,
                  onPressed: () => _addIngredient(context, activeTargetId),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Инлайн-спецификация ──────────────────────────────────────────
            Expanded(
              child: isCurrentLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is RecipeError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(PhosphorIconsRegular.warningCircle, size: 40, color: AppColors.danger),
                              const SizedBox(height: 8),
                              Text('Ошибка загрузки техкарты', style: AppTextStyles.h3),
                              const SizedBox(height: 12),
                              AppSecondaryButton(
                                label: 'Повторить',
                                icon: PhosphorIconsRegular.arrowsClockwise,
                                size: AppButtonSize.md,
                                onPressed: () => context.read<RecipeBloc>().add(
                                      LoadRecipe(activeTargetId, forceRefresh: true),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RecipeSpecificationSection(
                          recipes: currentRecipes,
                          targetMenuItemId: activeTargetId,
                          currency: currency,
                          isDark: isDark,
                          onAddIngredient: () => _addIngredient(context, activeTargetId),
                        ),
            ),
          ],
        );
      },
    );
  }
}
