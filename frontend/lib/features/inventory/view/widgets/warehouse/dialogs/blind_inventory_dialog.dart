// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'blind_inventory/blind_inventory_tabs_bar.dart';
import 'blind_inventory/blind_inventory_add_item_bar.dart';
import 'blind_inventory/blind_inventory_items_table.dart';
import 'blind_inventory/blind_inventory_toolbar.dart';
import 'blind_inventory/blind_inventory_grouped_view.dart';
import 'blind_inventory/blind_inventory_progress_card.dart';
import 'blind_inventory/blind_inventory_cart_sheet.dart';

// ==============================================================================
// 2. ДИАЛОГ СЛЕПОЙ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Диалог ревизии склада со строчным и категорийным режимами и корзиной.
class BlindInventoryDialog extends StatefulWidget {
  const BlindInventoryDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => const BlindInventoryDialog(),
    );
  }

  @override
  State<BlindInventoryDialog> createState() => _BlindInventoryDialogState();
}

class _BlindInventoryDialogState extends State<BlindInventoryDialog> {
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _addItemFocusNode = FocusNode();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _expansionMap = {};
  final List<Ingredient> _addedItems = [];
  BlindInventoryViewMode _viewMode = BlindInventoryViewMode.items;
  BlindInventoryFilter _activeFilter = BlindInventoryFilter.all;
  String _searchQuery = '';
  bool _isAllExpanded = false;
  bool _isCartOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusSearch();
  }

  void _focusSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_viewMode == BlindInventoryViewMode.items) {
        _addItemFocusNode.requestFocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _addItemFocusNode.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isDirty => _controllers.values.any((c) => c.text.trim().isNotEmpty);

  int _getFilledCount(List<Ingredient> ingredients) {
    return ingredients.where((it) => _controllers[it.uniqueKey]?.text.trim().isNotEmpty == true).length;
  }

  void _onIngredientSelected(Ingredient item) {
    if (!_addedItems.any((e) => e.isSameAs(item))) {
      setState(() => _addedItems.add(item));
    }
    _controllers.putIfAbsent(item.uniqueKey, () => TextEditingController());
  }

  void _removeItem(Ingredient item) {
    setState(() {
      _controllers[item.uniqueKey]?.clear();
      _addedItems.removeWhere((e) => e.isSameAs(item));
    });
  }

  Future<void> _submit(List<Ingredient> ingredients) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<InventoryRepository>();
      final List<Map<String, dynamic>> items = [];

      for (final item in ingredients) {
        final actualQty = double.tryParse((_controllers[item.uniqueKey]?.text ?? '').replaceAll(',', '.'));
        if (actualQty == null) continue;
        final isRetail = item.isRetail;
        items.add({
          isRetail ? 'retail_product_id' : 'ingredient_id': item.id,
          'quantity': actualQty,
          'expected_quantity': item.currentStock,
          'price_per_unit': item.costPerUnit,
          'total_price': actualQty * item.costPerUnit,
        });
      }

      if (items.isEmpty) {
        AppToast.showWarning(context, 'Внимание', subtitle: 'Вы не ввели ни одного остатка');
        setState(() => _isLoading = false);
        return;
      }

      final doc = await repo.createDocument({
        'type': 'inventory',
        'reason': 'Слепая инвентаризация',
        'items': items,
      });
      await repo.completeDocument(doc.id);

      if (mounted) {
        context.read<IngredientBloc>().add(const LoadIngredients());
        try { context.read<DocumentBloc>().add(const LoadDocuments()); } catch (_) {}
        Navigator.pop(context);
        AppToast.showSuccess(context, 'Инвентаризация успешно проведена!');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Ошибка проведения', subtitle: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSaveShortcutScope(
      onCancel: () => _isCartOpen ? setState(() => _isCartOpen = false) : Navigator.maybePop(context),
      onSearch: _focusSearch,
      child: DirtyPopScope(
        isDirtyCheck: () => _isDirty,
        title: 'Отменить инвентаризацию?',
        message: 'Все введенные фактические остатки будут сброшены. Вы уверены, что хотите выйти?',
        confirmLabel: 'Сбросить и выйти',
        child: BlocBuilder<IngredientBloc, IngredientState>(
          builder: (context, state) {
            final all = (state is IngredientLoaded)
                ? state.ingredients.where((i) => !i.isArchived).toList()
                : <Ingredient>[];
            final filledCount = _getFilledCount(all);
            final unfilledCount = all.length - filledCount;

            final activeItems = all.where((it) {
              final hasText = _controllers[it.uniqueKey]?.text.trim().isNotEmpty == true;
              final isExplicitlyAdded = _addedItems.any((e) => e.isSameAs(it));
              return hasText || isExplicitlyAdded;
            }).toList();

            return AppCardDialog(
              title: 'Слепая Инвентаризация',
              subtitle: 'Сплошной пересчет фактических остатков склада',
              icon: PhosphorIconsRegular.clipboardText,
              width: 680,
              overlay: _isCartOpen
                  ? BlindInventoryCartSheet(
                      allItems: all,
                      controllers: _controllers,
                      onRemove: _removeItem,
                      onChanged: () => setState(() {}),
                      onClose: () => setState(() => _isCartOpen = false),
                    )
                  : null,
              body: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlindInventoryTabsBar(
                        viewMode: _viewMode,
                        onViewModeChanged: (mode) {
                          setState(() => _viewMode = mode);
                          _focusSearch();
                        },
                        filledCount: filledCount,
                      ),
                      const SizedBox(height: 10),
                      if (_viewMode == BlindInventoryViewMode.items) ...[
                        BlindInventoryAddItemBar(
                          availableIngredients: all,
                          onIngredientSelected: _onIngredientSelected,
                          focusNode: _addItemFocusNode,
                          autoFocus: true,
                        ),
                        const SizedBox(height: 12),
                        BlindInventoryItemsTable(
                          activeItems: activeItems,
                          controllers: _controllers,
                          onRemove: _removeItem,
                          onChanged: () => setState(() {}),
                        ),
                      ] else ...[
                        BlindInventoryToolbar(
                          searchFocusNode: _searchFocusNode,
                          searchQuery: _searchQuery,
                          onSearchChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                          activeFilter: _activeFilter,
                          onFilterChanged: (filter) => setState(() => _activeFilter = filter),
                          unfilledCount: unfilledCount,
                          filledCount: filledCount,
                          isAllExpanded: _isAllExpanded,
                          onToggleExpandAll: () => setState(() => _isAllExpanded = !_isAllExpanded),
                        ),
                        const SizedBox(height: 12),
                        state is IngredientLoading
                            ? const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))
                            : BlindInventoryGroupedView(
                                items: all,
                                controllers: _controllers,
                                searchQuery: _searchQuery,
                                activeFilter: _activeFilter,
                                isAllExpanded: _isAllExpanded,
                                expansionMap: _expansionMap,
                                onExpansionChanged: (cat, exp) => setState(() => _expansionMap[cat] = exp),
                                onChanged: () => setState(() {}),
                              ),
                      ],
                      const SizedBox(height: 14),
                      BlindInventoryProgressCard(
                        filledCount: filledCount,
                        totalCount: all.length,
                        isCartOpen: _isCartOpen,
                        onToggleCart: () => setState(() => _isCartOpen = !_isCartOpen),
                      ),
                    ],
                  ),
                  actions: [
                    AppGhostButton(
                      label: 'Отмена',
                      height: 38,
                      onPressed: _isLoading ? null : () => Navigator.maybePop(context),
                    ),
                    AppPrimaryButton(
                      label: 'Провести',
                      icon: PhosphorIconsRegular.checkCircle,
                      height: 38,
                      isLoading: _isLoading,
                      onPressed: !_isLoading && filledCount > 0 ? () => _submit(all) : null,
                    ),
                  ],
                );
          },
        ),
      ),
    );
  }
}
