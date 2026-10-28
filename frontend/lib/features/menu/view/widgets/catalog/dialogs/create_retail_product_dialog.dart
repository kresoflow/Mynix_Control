import 'dart:convert';
// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Диалог создания и редактирования ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/create_retail_product_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'create_retail_duplicate_helper.dart';
import 'create_retail_product_form.dart';
import 'create_retail_submit_helper.dart';

// ─── 1. Точка входа в диалог ──────────────────────────────────────────────────

void showAddRetailProductDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  showDialog(
    context: context,
    builder: (_) => CreateRetailProductDialog(currentCategoryId: currentCategoryId, itemToEdit: itemToEdit),
  );
}

// ─── 2. Виджет диалога формы товара ──────────────────────────────────────────

class CreateRetailProductDialog extends StatefulWidget {
  final int? currentCategoryId;
  final MenuItem? itemToEdit;

  const CreateRetailProductDialog({super.key, this.currentCategoryId, this.itemToEdit});

  @override
  State<CreateRetailProductDialog> createState() => _CreateRetailProductDialogState();
}

class _CreateRetailProductDialogState extends State<CreateRetailProductDialog> {
  late final TextEditingController _nameController, _flavorController, _volumeController;
  late final TextEditingController _sortOrderController, _sellingPriceController, _barcodeController;
  final List<Map<String, dynamic>> _variations = [];
  int? _selectedCategoryId;
  late String _selectedUnit;
  String? _selectedIcon;
  late final RetailProductSnapshot _initialSnapshot;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.cleanName ?? '');
    _flavorController = TextEditingController(text: item?.flavorString ?? '');
    _sortOrderController = TextEditingController(text: (item != null && item.sortOrder > 0) ? item.sortOrder.toString() : '');
    _sellingPriceController = TextEditingController(text: item != null ? (item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toString()) : '');
    _barcodeController = TextEditingController(text: item?.barcode ?? '');
    final rawCat = item?.categoryId;
    final parsedCat = (rawCat != null && rawCat.isNotEmpty && rawCat != '0') ? int.tryParse(rawCat) : null;
    _selectedCategoryId = widget.currentCategoryId ?? parsedCat;
    if (_selectedCategoryId == 0) _selectedCategoryId = null;
    _selectedIcon = item?.icon;

    final parsedVars = CreateRetailSubmitHelper.parseInitialVariations(item);
    if (parsedVars.isNotEmpty) {
      _variations.addAll(parsedVars);
      _volumeController = TextEditingController(text: '');
    } else {
      _volumeController = TextEditingController(text: item?.variationsSummary ?? '');
    }

    // Инициализация единицы измерения: из атрибутов товара либо из первой вариации
    String detectedUnit = 'pcs';
    final rawUnit = item?.attributes?['unit']?.toString();
    if (rawUnit != null && rawUnit.isNotEmpty) {
      detectedUnit = UnitFormatter.toDbKey(rawUnit, 'pcs');
    } else if (parsedVars.isNotEmpty) {
      final varUnit = parsedVars.first['unit']?.toString();
      if (varUnit != null && varUnit.isNotEmpty) {
        detectedUnit = UnitFormatter.toDbKey(varUnit, 'pcs');
      }
    }
    _selectedUnit = detectedUnit;

    _initialSnapshot = RetailProductSnapshot(
      name: _nameController.text.trim(), flavor: _flavorController.text.trim(),
      volume: _volumeController.text.trim(), sortOrder: _sortOrderController.text.trim(),
      price: _sellingPriceController.text.trim(), barcode: _barcodeController.text.trim(),
      categoryId: _selectedCategoryId, unit: _selectedUnit, icon: _selectedIcon,
      variationsJson: jsonEncode(_variations),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flavorController.dispose();
    _volumeController.dispose();
    _sortOrderController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _addVariation() {
    setState(() {
      if (_variations.isEmpty) {
        final currentVol = _volumeController.text.trim();
        final currentPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
        final currentBc = _barcodeController.text.trim();
        _variations.add({
          'name': currentVol.isNotEmpty ? currentVol : '0.5 л',
          'price': currentPrice,
          'barcode': currentBc.isNotEmpty ? currentBc : null,
          'unit': _selectedUnit,
        });
      }
      _variations.add({
        'name': '',
        'price': 0.0,
        'barcode': null,
        'unit': _selectedUnit,
      });
    });
  }

  void _removeVariation(int index) {
    setState(() {
      _variations.removeAt(index);
    });
  }

  void _extractVariation(int index) {
    if (index >= _variations.length) return;
    final v = _variations[index];
    final childId = v['id'] as int?;
    if (childId == null) return;

    CreateRetailSubmitHelper.showExtractVariationDialog(
      context,
      childId: childId,
      varName: v['name'] ?? '',
      onExtracted: () => setState(() => _variations.removeAt(index)),
    );
  }

  bool _isDirty() => _initialSnapshot.isDirty(
        isEditing: widget.itemToEdit != null,
        currentName: _nameController.text.trim(),
        currentFlavor: _flavorController.text.trim(),
        currentVolume: _volumeController.text.trim(),
        currentSortOrder: _sortOrderController.text.trim(),
        currentPrice: _sellingPriceController.text.trim(),
        currentBarcode: _barcodeController.text.trim(),
        currentCategoryId: _selectedCategoryId,
        currentUnit: _selectedUnit,
        currentIcon: _selectedIcon,
        currentVariations: _variations,
      );

  void _submit() {
    final name = _nameController.text.trim();
    final sPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    if (name.isEmpty || sPrice < 0) return;

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();
    final flavor = _flavorController.text.trim().isEmpty ? null : _flavorController.text.trim();
    final rawVolume = _volumeController.text.trim().isEmpty ? null : _volumeController.text.trim();

    final item = widget.itemToEdit;
    final menuState = context.read<MenuBloc>().state;

    // ─── 1. Poka-Yoke: Проверка на 100% дубликат ──────────────────────────────
    if (item == null && menuState is MenuLoaded) {
      final duplicateMatch = CreateRetailDuplicateHelper.detectDuplicate(
        items: menuState.items,
        name: name,
        flavor: flavor,
        barcode: barcode,
        rawVolume: rawVolume,
        variations: _variations,
        categoryId: _selectedCategoryId,
      );

      if (duplicateMatch != null && duplicateMatch.isSameCategory) {
        if (duplicateMatch.item.id > 0) {
          CreateRetailDuplicateHelper.showDuplicateBlockedDialog(
            context,
            existingItem: duplicateMatch.item,
            selectedCategoryId: _selectedCategoryId,
          );
        }
        return;
      }
    }

    // ─── 2. Формирование полезной нагрузки ───────────────────────────────────
    final payload = CreateRetailSubmitHelper.buildPayload(
      name: name,
      basePrice: sPrice,
      baseBarcode: barcode,
      flavor: flavor,
      rawVolume: rawVolume,
      selectedUnit: _selectedUnit,
      selectedIcon: _selectedIcon,
      variations: _variations,
    );

    CreateRetailSubmitHelper.dispatchSubmit(
      context: context,
      item: item,
      name: name,
      categoryId: _selectedCategoryId,
      sortOrder: sortOrder,
      unit: _selectedUnit,
      payload: payload,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    final menuState = context.watch<MenuBloc>().state;

    DuplicateMatch<MenuItem>? duplicateMatch;
    if (menuState is MenuLoaded) {
      duplicateMatch = CreateRetailDuplicateHelper.detectDuplicate(
        items: menuState.items,
        name: _nameController.text,
        flavor: _flavorController.text.trim().isEmpty ? null : _flavorController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        rawVolume: _volumeController.text.trim().isEmpty ? null : _volumeController.text.trim(),
        variations: _variations,
        categoryId: _selectedCategoryId,
        excludeItemId: widget.itemToEdit?.id,
      );
    }

    return DirtyPopScope(
      isDirty: _isDirty(),
      title: isEditing ? 'Отменить изменения?' : 'Отменить создание товара?',
      message: isEditing ? 'Несохраненные изменения карточки товара будут сброшены.' : 'Все введенные данные о товаре будут сброшены.',
      confirmLabel: 'Сбросить и выйти',
      child: AppDialog(
        title: isEditing ? 'Редактировать товар' : 'Новый товар для витрины',
        icon: PhosphorIconsRegular.storefront,
        width: 520,
        content: SingleChildScrollView(
          child: CreateRetailProductForm(
            nameController: _nameController,
            flavorController: _flavorController,
            volumeController: _volumeController,
            sortOrderController: _sortOrderController,
            sellingPriceController: _sellingPriceController,
            barcodeController: _barcodeController,
            selectedCategoryId: _selectedCategoryId,
            selectedUnit: _selectedUnit,
            selectedIcon: _selectedIcon,
            duplicateMatch: duplicateMatch,
            variations: _variations,
            onAddVariation: _addVariation,
            onRemoveVariation: _removeVariation,
            onExtractVariation: _extractVariation,
            onCategoryChanged: (val) => setState(() => _selectedCategoryId = val),
            onUnitChanged: (val) => setState(() {
              _selectedUnit = val;
              for (final v in _variations) {
                v['unit'] = val;
              }
            }),
            onIconChanged: (icon) => setState(() => _selectedIcon = icon),
            onFieldsChanged: () => setState(() {}),
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.maybePop(context)),
          const SizedBox(width: 12),
          AppPrimaryButton(
            label: isEditing ? 'Сохранить' : 'Создать',
            icon: PhosphorIconsRegular.floppyDisk,
            width: null,
            onPressed: _nameController.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
