// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_dialog_scaffold.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'write_off/write_off_meta_row.dart';
import 'write_off/write_off_tabs_bar.dart';
import 'write_off/write_off_add_item_bar.dart';
import 'write_off/write_off_items_table.dart';
import 'write_off/write_off_category_section.dart';
import 'write_off/write_off_summary_card.dart';

// ==============================================================================
// 2. ДИАЛОГ СОЗДАНИЯ АКТА СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Гибридный диалог списания: по строкам или по категориям цехов.
class WriteOffDocumentDialog extends StatefulWidget {
  const WriteOffDocumentDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => const WriteOffDocumentDialog(),
    );
  }

  @override
  State<WriteOffDocumentDialog> createState() => _WriteOffDocumentDialogState();
}

class _WriteOffDocumentDialogState extends State<WriteOffDocumentDialog> {
  String _selectedReason = 'Порча / Просрочка';
  final TextEditingController _commentController = TextEditingController();
  final List<WriteOffItemEntry> _entries = [];
  WriteOffViewMode _viewMode = WriteOffViewMode.items;
  bool _isLoading = false;

  final List<String> _reasons = const [
    'Порча / Просрочка',
    'Брак / Бой',
    'Питание персонала',
    'Угощение гостя',
    'Прочее',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    for (var e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  void _addItem(Ingredient item) {
    if (_entries.any((e) => e.item.id == item.id)) {
      AppToast.showWarning(context, 'Внимание',
          subtitle: '«${item.name}» уже в списке',);
      return;
    }
    setState(() {
      _entries.add(WriteOffItemEntry(item: item, quantity: 1.0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final e = _entries.removeAt(index);
      e.controller.dispose();
    });
  }

  void _onCategoryQuantityChanged(Ingredient item, double qty) {
    final idx = _entries.indexWhere((e) => e.item.id == item.id);
    if (idx != -1) {
      if (qty <= 0) {
        final removed = _entries.removeAt(idx);
        removed.controller.dispose();
      } else {
        _entries[idx].quantity = qty;
        _entries[idx].controller.text = qty == qty.truncateToDouble()
            ? qty.toInt().toString()
            : qty.toString();
      }
    } else if (qty > 0) {
      _entries.add(WriteOffItemEntry(item: item, quantity: qty));
    }
    setState(() {});
  }

  double get _totalAmount => _entries.fold(0.0, (sum, e) => sum + e.total);
  double get _totalUnits => _entries.fold(0.0, (sum, e) => sum + e.quantity);

  bool get _isDirty =>
      _entries.isNotEmpty || _commentController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final validEntries = _entries.where((e) => e.quantity > 0).toList();
    if (validEntries.isEmpty) {
      AppToast.showWarning(
        context,
        'Внимание',
        subtitle: 'Укажите количество для списания хотя бы одной позиции',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<InventoryRepository>();
      final reasonText = _commentController.text.trim().isNotEmpty
          ? '$_selectedReason: ${_commentController.text.trim()}'
          : _selectedReason;

      final items = validEntries.map((e) {
        final isRetail = e.item.attributes?['is_retail'] == true;
        return {
          if (isRetail)
            'retail_product_id': e.item.id
          else
            'ingredient_id': e.item.id,
          'quantity': e.quantity,
          'price_per_unit': e.cost,
          'total_price': e.total,
        };
      }).toList();

      final docData = {
        'type': 'write_off',
        'reason': reasonText,
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
        AppToast.showSuccess(context, 'Акт списания успешно проведен!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Ошибка списания', subtitle: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsBloc>().state.currency;
    final ingState = context.watch<IngredientBloc>().state;
    final availableIngredients =
        ingState is IngredientLoaded ? ingState.ingredients : <Ingredient>[];

    return DirtyPopScope(
      isDirtyCheck: () => _isDirty,
      title: 'Отменить списание?',
      message:
          'Все выбранные позиции и данные акта будут сброшены. Вы уверены, что хотите выйти?',
      confirmLabel: 'Сбросить акт',
      child: AppDialogScaffold(
        title: 'Акт списания со склада',
        icon: PhosphorIconsRegular.archive,
        dialogSize: AppDialogSize.md,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            WriteOffMetaRow(
              selectedReason: _selectedReason,
              reasons: _reasons,
              onReasonChanged: (r) => setState(() => _selectedReason = r),
              commentController: _commentController,
            ),
            const SizedBox(height: 12),
            WriteOffTabsBar(
              viewMode: _viewMode,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              itemsCount: _entries.where((e) => e.quantity > 0).length,
            ),
            const SizedBox(height: 10),
            if (_viewMode == WriteOffViewMode.items) ...[
              WriteOffAddItemBar(
                availableIngredients: availableIngredients,
                onIngredientSelected: _addItem,
              ),
              const SizedBox(height: 12),
              WriteOffItemsTable(
                items: _entries,
                currency: currency,
                onRemove: _removeItem,
                onChanged: () => setState(() {}),
              ),
            ] else ...[
              WriteOffCategorySection(
                availableIngredients: availableIngredients,
                activeEntries: _entries,
                currency: currency,
                onQuantityChanged: _onCategoryQuantityChanged,
              ),
            ],
            const SizedBox(height: 14),
            WriteOffSummaryCard(
              itemsCount: _entries.where((e) => e.quantity > 0).length,
              totalUnits: _totalUnits,
              totalAmount: _totalAmount,
              currency: currency,
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
          AppButton.primary(
            label: 'Провести списание',
            icon: PhosphorIconsRegular.checkCircle,
            height: 40,
            isLoading: _isLoading,
            onPressed: _isLoading || _entries.isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
