import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'bulk_add/bulk_add_controller.dart';
import 'bulk_add/bulk_add_header.dart';
import 'bulk_add/bulk_add_tabs_bar.dart';
import 'bulk_add/bulk_add_category_selector.dart';
import 'bulk_add/bulk_add_list_widget.dart';
import 'bulk_add/bulk_add_footer.dart';
import 'bulk_add/bulk_add_save_helper.dart';

class BulkAddModal extends StatefulWidget {
  final int initialTabIndex;
  final int? initialParentId;
  final int? initialChildId;

  const BulkAddModal({
    super.key,
    this.initialTabIndex = 0,
    this.initialParentId,
    this.initialChildId,
  });

  @override
  State<BulkAddModal> createState() => _BulkAddModalState();
}

class _BulkAddModalState extends State<BulkAddModal> {
  final BulkAddController _controller = BulkAddController();
  int _tabIndex = 0;
  int? _selectedParentId;
  int? _selectedChildId;
  String _categoryType = 'dish';

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _selectedParentId = widget.initialParentId;
    _selectedChildId = widget.initialChildId;
    _addRow();
  }

  void _addRow() {
    setState(() {
      _controller.addRow(_tabIndex);
    });
    _focusNode(_controller.getLastFocusNode(_tabIndex));
  }

  void _focusNode(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _duplicateRow(int index) {
    setState(() {
      _controller.duplicateRow(_tabIndex, index);
    });
    _focusNode(_controller.getRowFocusNode(_tabIndex, index + 1));
  }

  void _removeRow(int index) {
    setState(() {
      _controller.removeRow(_tabIndex, index);
    });
  }

  void _loadPreset(String presetType) {
    setState(() {
      _controller.loadPreset(
        context: context,
        tabIndex: _tabIndex,
        presetType: presetType,
        categoryType: _categoryType,
      );
    });
  }

  Future<void> _saveAll() async {
    await performBulkSave(
      context: context,
      tabIndex: _tabIndex,
      targetCategoryId: _selectedChildId ?? _selectedParentId,
      dishRows: _controller.dishRows,
      ingredientRows: _controller.ingredientRows,
      retailRows: _controller.retailRows,
      categoryRows: _controller.categoryRows,
      globalCategoryType: _categoryType,
    );
  }

  bool get _isDirty {
    final hasDishes = _controller.dishRows.any((r) => r.nameController.text.trim().isNotEmpty);
    final hasRetail = _controller.retailRows.any((r) => r.nameController.text.trim().isNotEmpty);
    final hasIngs = _controller.ingredientRows.any((r) => r.nameController.text.trim().isNotEmpty);
    final hasCats = _controller.categoryRows.any((r) => r.nameController.text.trim().isNotEmpty);
    final hasMultipleRows = _controller.dishRows.length > 1 ||
        _controller.retailRows.length > 1 ||
        _controller.ingredientRows.length > 1 ||
        _controller.categoryRows.length > 1;
    return hasDishes || hasRetail || hasIngs || hasCats || hasMultipleRows;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveAll,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _saveAll,
      },
      child: Focus(
        autofocus: true,
        child: DirtyPopScope(
          isDirtyCheck: () => _isDirty,
          title: 'Отменить массовое добавление?',
          message: 'Все введенные строки и данные будут сброшены. Вы уверены, что хотите выйти?',
          confirmLabel: 'Сбросить строки',
          child: Dialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppRadii.dialogRadius,
              boxShadow: AppShadows.dialog,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BulkAddHeader(),
                const SizedBox(height: 16),
                BulkAddTabsBar(
                  tabIndex: _tabIndex,
                  categoryType: _categoryType,
                  onTabSelected: (i) => setState(() {
                    // Сбрасываем категорию при переключении между доменами
                    // (dish/retail/ingredient — разные типы категорий)
                    const tabTypes = ['dish', 'retail', 'ingredient', null];
                    final prevType = tabTypes[_tabIndex];
                    final nextType = tabTypes[i < 4 ? i : 3];
                    if (prevType != nextType) {
                      _selectedParentId = null;
                      _selectedChildId = null;
                    }
                    _tabIndex = i;
                    if ((i == 0 && _controller.dishRows.isEmpty) ||
                        (i == 1 && _controller.retailRows.isEmpty) ||
                        (i == 2 && _controller.ingredientRows.isEmpty) ||
                        (i == 3 && _controller.categoryRows.isEmpty)) {
                      _addRow();
                    }
                  }),
                  onCategoryTypeChanged: (val) => setState(() => _categoryType = val),
                  onAddRow: _addRow,
                  onLoadPreset: _loadPreset,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: AppRadii.radiusLg,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: BulkAddCategorySelector(
                      tabIndex: _tabIndex,
                      globalCategoryType: _categoryType,
                      onCategoryTypeChanged: (val) => setState(() => _categoryType = val),
                      selectedParentId: _selectedParentId,
                      selectedChildId: _selectedChildId,
                      onParentChanged: (val) => setState(() => _selectedParentId = val),
                      onChildChanged: (val) => setState(() => _selectedChildId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: BulkAddListWidget(
                      tabIndex: _tabIndex,
                      dishRows: _controller.dishRows,
                      retailRows: _controller.retailRows,
                      ingredientRows: _controller.ingredientRows,
                      categoryRows: _controller.categoryRows,
                      onAddRow: _addRow,
                      onDuplicateRow: _duplicateRow,
                      onRemoveRow: _removeRow,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                  child: BulkAddFooter(onSaveAll: _saveAll),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
