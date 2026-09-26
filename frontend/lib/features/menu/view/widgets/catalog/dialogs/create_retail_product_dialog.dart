// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Диалог создания и редактирования ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/create_retail_product_dialog.dart
// ==============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'create_retail_product_form.dart';

const Map<String, String> _unitLabels = {
  'l': 'л',
  'ml': 'мл',
  'kg': 'кг',
  'g': 'г',
  'pcs': 'шт',
};

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
  late final TextEditingController _nameController;
  late final TextEditingController _flavorController;
  late final TextEditingController _volumeController;
  late final TextEditingController _sortOrderController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _barcodeController;
  final List<Map<String, dynamic>> _variations = [];
  int? _selectedCategoryId;
  String _selectedUnit = 'pcs';
  String? _selectedIcon;

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

    if (item?.variations != null && item!.variations!.isNotEmpty) {
      for (var v in item.variations!) {
        final rawMap = Map<String, dynamic>.from(v);
        String varName = rawMap['name']?.toString() ?? '';
        final cleanN = item.cleanName.trim().toLowerCase();
        final flavN = (item.flavorString ?? '').trim().toLowerCase();
        final prefix1 = '$cleanN $flavN'.trim();
        final prefix2 = cleanN;
        if (prefix1.isNotEmpty && varName.toLowerCase().startsWith(prefix1)) {
          varName = varName.substring(prefix1.length).trim();
        } else if (prefix2.isNotEmpty && varName.toLowerCase().startsWith(prefix2)) {
          varName = varName.substring(prefix2.length).trim();
        }
        _variations.add({
          'name': varName.isNotEmpty ? varName : (rawMap['name']?.toString() ?? ''),
          'price': (rawMap['price'] is num) ? (rawMap['price'] as num).toDouble() : (double.tryParse(rawMap['price']?.toString() ?? '') ?? 0.0),
          'barcode': rawMap['barcode']?.toString(),
          'unit': rawMap['unit']?.toString() ?? 'pcs',
        });
      }
      _volumeController = TextEditingController(text: '');
    } else {
      _volumeController = TextEditingController(text: item?.variationsSummary ?? '');
    }
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

  bool _isDirty() {
    final item = widget.itemToEdit;
    final parsedCat = (item?.categoryId != null && item!.categoryId != '0') ? int.tryParse(item.categoryId) : null;
    final initialCat = widget.currentCategoryId ?? parsedCat;
    if (_variations.isNotEmpty && (item == null || item.variations == null || item.variations!.isEmpty)) return true;
    return _nameController.text.trim() != (item?.cleanName ?? '') ||
        _flavorController.text.trim() != (item?.flavorString ?? '') ||
        _volumeController.text.trim() != (item?.variationsSummary ?? '') ||
        _sortOrderController.text.trim() != ((item != null && item.sortOrder > 0) ? item.sortOrder.toString() : '') ||
        _sellingPriceController.text.trim() != (item != null ? (item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toString()) : '') ||
        _barcodeController.text.trim() != (item?.barcode ?? '') ||
        _selectedCategoryId != (initialCat == 0 ? null : initialCat) ||
        _selectedUnit != 'pcs' ||
        _selectedIcon != item?.icon;
  }

  String _formatVolume(String volume, String unit) {
    final clean = volume.trim();
    if (clean.isEmpty) return '';
    if (clean.contains(RegExp(r'[а-яА-Яa-zA-Z]'))) {
      return clean;
    }
    final uLabel = _unitLabels[unit] ?? '';
    if (uLabel.isNotEmpty) {
      return '$clean $uLabel'.trim();
    }
    return clean;
  }

  void _showDuplicateBlockedDialog(BuildContext context, MenuItem existingItem) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'Товар уже существует',
        icon: PhosphorIconsRegular.warningCircle,
        width: 440,
        content: Text(
          'В этой категории уже есть активный товар «${existingItem.cleanName}» с таким же вкусом и объемом.\n\nОткрыть существующую карточку для редактирования?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          const SizedBox(width: 8),
          AppPrimaryButton(
            label: 'Открыть карточку',
            icon: PhosphorIconsRegular.arrowSquareOut,
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              showAddRetailProductDialog(
                context,
                currentCategoryId: _selectedCategoryId,
                itemToEdit: existingItem,
              );
            },
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final sPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    if (name.isEmpty || sPrice < 0) return;

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();
    final flavor = _flavorController.text.trim().isEmpty ? null : _flavorController.text.trim();
    final rawVolume = _volumeController.text.trim().isEmpty ? null : _volumeController.text.trim();
    final formattedVol = rawVolume != null ? _formatVolume(rawVolume, _selectedUnit) : null;

    final item = widget.itemToEdit;
    final menuState = context.read<MenuBloc>().state;

    // ─── 1. Poka-Yoke: Проверка на 100% дубликат ──────────────────────────────
    if (item == null && menuState is MenuLoaded) {
      final duplicateMatch = DuplicateDetector.findMenuItemDuplicate(
        items: menuState.items,
        queryName: name,
        isRetail: true,
        queryFlavor: flavor,
        queryVolume: rawVolume,
        queryBarcode: barcode,
        currentCategoryId: _selectedCategoryId,
      );

      if (duplicateMatch != null && duplicateMatch.isSameCategory) {
        _showDuplicateBlockedDialog(context, duplicateMatch.item);
        return;
      }

      // ─── 2. Слияние вариаций в существующую карточку (Smart Merge) ──────────
      final existingParent = menuState.items.where((i) {
        if (!i.isRetail || !i.isAvailable) return false;
        final isSameCat = _selectedCategoryId == null || i.categoryId == _selectedCategoryId.toString();
        if (!isSameCat) return false;
        final isSameName = _normalize(i.cleanName) == _normalize(name);
        final isSameFlavor = _normalize(i.flavorString ?? '') == _normalize(flavor ?? '');
        return isSameName && isSameFlavor;
      }).firstOrNull;

      if (existingParent != null && formattedVol != null && _variations.isEmpty) {
        final existingVars = existingParent.variations != null
            ? List<Map<String, dynamic>>.from(existingParent.variations!)
            : <Map<String, dynamic>>[];

        final nameParts = [name, if (flavor != null) flavor, formattedVol];
        final newVar = {
          'name': nameParts.join(' '),
          'unit': (_selectedUnit != 'pcs') ? 'pcs' : _selectedUnit,
          'price': sPrice,
          'selling_price': sPrice,
          'purchase_price': 0.0,
          'initial_stock': 0.0,
          if (barcode != null) 'barcode': barcode,
        };

        existingVars.add(newVar);

        final Map<String, dynamic> newAttrs = existingParent.attributesJson != null
            ? Map<String, dynamic>.from(jsonDecode(existingParent.attributesJson!))
            : {};

        if (_selectedIcon != null) newAttrs['icon'] = 'icon:$_selectedIcon';
        if (flavor != null) newAttrs['flavor'] = flavor;
        newAttrs['variations'] = existingVars;

        context.read<MenuBloc>().add(UpdateMenuItem(existingParent.id, {
          'attributes': newAttrs,
        },),);

        Navigator.pop(context);
        return;
      }
    }

    // ─── 3. Формирование атрибутов и массива вариаций ─────────────────────────
    Map<String, dynamic>? attributes;
    double effectivePrice = sPrice;

    if (_variations.isNotEmpty) {
      final List<Map<String, dynamic>> formattedVars = [];
      for (final v in _variations) {
        final vName = v['name']?.toString().trim() ?? '';
        final vPrice = (v['price'] is num) ? (v['price'] as num).toDouble() : (double.tryParse(v['price']?.toString() ?? '') ?? 0.0);
        final vBarcode = v['barcode']?.toString().trim();
        if (vName.isNotEmpty) {
          final fullName = [name, if (flavor != null) flavor, vName].join(' ');
          formattedVars.add({
            'name': fullName,
            'unit': _selectedUnit != 'pcs' ? 'pcs' : _selectedUnit,
            'price': vPrice,
            'selling_price': vPrice,
            'purchase_price': 0.0,
            'initial_stock': 0.0,
            if (vBarcode != null && vBarcode.isNotEmpty) 'barcode': vBarcode,
          });
        }
      }

      if (formattedVars.isNotEmpty) {
        effectivePrice = formattedVars.first['price'] as double;
        attributes = {
          if (_selectedIcon != null) 'icon': 'icon:$_selectedIcon',
          if (flavor != null) 'flavor': flavor,
          'variations': formattedVars,
        };
      }
    } else {
      final bool hasOptions = (flavor != null && flavor.isNotEmpty) || (formattedVol != null && formattedVol.isNotEmpty);
      final String stockUnit = (hasOptions && _selectedUnit != 'pcs' && formattedVol != null)
          ? 'pcs'
          : _selectedUnit;

      if (hasOptions) {
        final nameParts = [name, if (flavor != null) flavor, if (formattedVol != null) formattedVol];
        final List<Map<String, dynamic>> variationsList = [
          {
            'name': nameParts.join(' '),
            'unit': stockUnit,
            'price': sPrice,
            'selling_price': sPrice,
            'purchase_price': 0.0,
            'initial_stock': 0.0,
            if (barcode != null) 'barcode': barcode,
          },
        ];

        attributes = {
          if (_selectedIcon != null) 'icon': 'icon:$_selectedIcon',
          if (flavor != null) 'flavor': flavor,
          'variations': variationsList,
        };
      } else if (_selectedIcon != null) {
        attributes = {'icon': 'icon:$_selectedIcon'};
      }
    }

    if (item != null) {
      context.read<MenuBloc>().add(UpdateMenuItem(item.id, {
        'name': name,
        'price': effectivePrice,
        'category_id': _selectedCategoryId,
        'sort_order': sortOrder,
        'barcode': barcode,
        if (attributes != null) 'attributes': attributes,
      },),);
    } else {
      context.read<MenuBloc>().add(CreateRetailProduct(
        name: name,
        categoryId: _selectedCategoryId,
        unit: _selectedUnit,
        purchasePrice: 0.0,
        sellingPrice: effectivePrice,
        sortOrder: sortOrder,
        barcode: barcode,
        attributes: attributes,
      ),);
    }
    Navigator.pop(context);
  }

  static String _normalize(String input) => input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    final menuState = context.watch<MenuBloc>().state;

    DuplicateMatch<MenuItem>? duplicateMatch;
    if (menuState is MenuLoaded) {
      duplicateMatch = DuplicateDetector.findMenuItemDuplicate(
        items: menuState.items,
        queryName: _nameController.text,
        isRetail: true,
        queryFlavor: _flavorController.text,
        queryVolume: _volumeController.text,
        queryBarcode: _barcodeController.text,
        currentCategoryId: _selectedCategoryId,
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
            onCategoryChanged: (val) => setState(() => _selectedCategoryId = val),
            onUnitChanged: (val) => setState(() => _selectedUnit = val),
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
