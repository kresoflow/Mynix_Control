import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'dialogs/recipe_bulk_edit_dialog.dart';
import 'recipe/recipe_analytics_header.dart';
import 'recipe/recipe_ingredient_item_tile.dart';
import 'recipe/recipe_variation_tabs.dart';

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

    final String displayName = hasVariations
        ? '${menuItem?.cleanName ?? ''} (${activeVariation?['name'] ?? ''})'
        : (menuItem?.cleanName ?? 'Техкарта блюда');

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
            // Top Bar: Back to Summary Button + Dish Clean Name
            Row(
              children: [
                if (widget.onBackToSummary != null) ...[
                  InkWell(
                    onTap: widget.onBackToSummary,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.arrowLeft, size: 14, color: isDark ? AppColors.darkText : AppColors.lightText),
                          const SizedBox(width: 6),
                          Text(
                            'К сводке фудкоста',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                    ),
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

            // Variation Switcher Tabs (if dish has size options S/M/L)
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

            // KPI Strip (Cost, Active Selling Price, Margin)
            RecipeAnalyticsHeader(
              totalCost: totalCost,
              price: activePrice,
              currency: currency,
            ),

            // Ingredients Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ингредиенты (${currentRecipes.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                BlocBuilder<IngredientBloc, IngredientState>(
                  builder: (context, ingState) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (ingState is IngredientLoaded) {
                          showDialog(
                            context: context,
                            builder: (_) => RecipeBulkEditDialog(
                              menuItemId: activeTargetId,
                              availableIngredients: ingState.ingredients.where((i) => !i.isRetail && !i.isArchived).toList(),
                              currentRecipes: currentRecipes,
                            ),
                          );
                        }
                      },
                      icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                      label: const Text('Редактировать состав'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ingredients List Body
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
                              ElevatedButton.icon(
                                onPressed: () => context.read<RecipeBloc>().add(LoadRecipe(activeTargetId)),
                                icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                                label: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : currentRecipes.isEmpty
                          ? Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.cookingPot,
                                    size: 48,
                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'В техкарте пока нет ингредиентов',
                                    style: AppTextStyles.h3.copyWith(
                                      color: isDark ? AppColors.darkText : AppColors.lightText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Нажмите «Редактировать состав», чтобы настроить рецептуру и калькуляцию.',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: currentRecipes.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    return RecipeIngredientItemTile(
                                      recipe: currentRecipes[index],
                                      selectedMenuItemId: activeTargetId,
                                      currency: currency,
                                    );
                                  },
                                ),
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}
