// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog_scaffold.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'blind_inventory/blind_inventory_toolbar.dart';
import 'blind_inventory/blind_inventory_grouped_view.dart';
import 'blind_inventory/blind_inventory_progress_card.dart';

// ==============================================================================
// 2. ДИАЛОГ СЛЕПОЙ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Диалог ревизии склада с группировкой номенклатуры по цехам.
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
  final Map<int, TextEditingController> _controllers = {};
  final Map<String, bool> _expansionMap = {};
  String _searchQuery = '';
  bool _onlyUnfilled = false;
  bool _isAllExpanded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isDirty => _controllers.values.any((c) => c.text.trim().isNotEmpty);

  int _getFilledCount(List<Ingredient> ingredients) {
    int count = 0;
    for (final it in ingredients) {
      if (_controllers[it.id]?.text.trim().isNotEmpty == true) {
        count++;
      }
    }
    return count;
  }

  Future<void> _submit(List<Ingredient> ingredients) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<InventoryRepository>();
      final List<Map<String, dynamic>> items = [];

      for (final item in ingredients) {
        final actualQty = double.tryParse((_controllers[item.id]?.text ?? '').replaceAll(',', '.'));
        if (actualQty == null) continue;
        final isRetail = item.attributes?['is_retail'] == true;
        items.add({
          isRetail ? 'retail_product_id' : 'ingredient_id': item.id,
          'quantity': actualQty,
          'expected_quantity': item.currentStock,
          'price_per_unit': item.costPerUnit,
          'total_price': actualQty * item.costPerUnit,
        });
      }

      if (items.isEmpty) {
        AppToast.showWarning(
          context,
          'Внимание',
          subtitle: 'Вы не ввели ни одного остатка',
        );
        setState(() => _isLoading = false);
        return;
      }

      final docData = {
        'type': 'inventory',
        'reason': 'Слепая инвентаризация',
        'items': items,
      };

      final doc = await repo.createDocument(docData);
      await repo.completeDocument(doc.id);

      if (mounted) {
        context.read<IngredientBloc>().add(const LoadIngredients());
        try {
          context.read<DocumentBloc>().add(const LoadDocuments());
        } catch (_) {}

        Navigator.pop(context);
        AppToast.showSuccess(context, 'Инвентаризация успешно проведена!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'Ошибка проведения',
          subtitle: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirtyPopScope(
      isDirtyCheck: () => _isDirty,
      title: 'Отменить инвентаризацию?',
      message:
          'Все введенные фактические остатки будут сброшены. Вы уверены, что хотите выйти?',
      confirmLabel: 'Сбросить и выйти',
      child: AppDialogScaffold(
        title: 'Слепая Инвентаризация',
        icon: PhosphorIconsRegular.clipboardText,
        dialogSize: AppDialogSize.md,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlindInventoryToolbar(
                searchQuery: _searchQuery,
                onSearchChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase().trim()),
                onlyUnfilled: _onlyUnfilled,
                onOnlyUnfilledChanged: (val) =>
                    setState(() => _onlyUnfilled = val),
                isAllExpanded: _isAllExpanded,
                onToggleExpandAll: () =>
                    setState(() => _isAllExpanded = !_isAllExpanded),
              ),
              const SizedBox(height: 12),
              BlocBuilder<IngredientBloc, IngredientState>(
                builder: (context, state) {
                  if (state is IngredientLoading) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is! IngredientLoaded) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: Text('Ошибка загрузки позиций')),
                    );
                  }

                  return BlindInventoryGroupedView(
                    items: state.ingredients,
                    controllers: _controllers,
                    searchQuery: _searchQuery,
                    onlyUnfilled: _onlyUnfilled,
                    isAllExpanded: _isAllExpanded,
                    expansionMap: _expansionMap,
                    onExpansionChanged: (cat, exp) {
                      setState(() => _expansionMap[cat] = exp);
                    },
                    onChanged: () => setState(() {}),
                  );
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<IngredientBloc, IngredientState>(
                builder: (context, state) {
                  if (state is! IngredientLoaded) return const SizedBox.shrink();
                  final all =
                      state.ingredients.where((i) => !i.isArchived).toList();
                  return BlindInventoryProgressCard(
                    filledCount: _getFilledCount(all),
                    totalCount: all.length,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          AppButton.secondary(
            label: 'Отмена',
            height: 40,
            onPressed: _isLoading ? null : () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 10),
          BlocBuilder<IngredientBloc, IngredientState>(
            builder: (context, state) {
              final isReady = !_isLoading && state is IngredientLoaded;
              return AppButton.primary(
                label: 'Завершить инвентаризацию',
                icon: PhosphorIconsRegular.checkCircle,
                height: 40,
                isLoading: _isLoading,
                onPressed: isReady ? () => _submit(state.ingredients) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
