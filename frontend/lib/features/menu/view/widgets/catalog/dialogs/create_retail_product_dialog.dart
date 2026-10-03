// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Диалог создания и редактирования ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/create_retail_product_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'create_retail_product_form.dart';

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
          'id': rawMap['id'],
          'retail_product_id': rawMap['retail_product_id'],
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

  void _extractVariation(int index) {
    if (index >= _variations.length) return;
    final v = _variations[index];
    final childId = v['id'] as int?;
    if (childId == null) return;

    final varName = v['name'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Отсоединить вариацию?',
        icon: PhosphorIconsRegular.arrowsSplit,
        width: 420,
        content: Text(
          'Вынести «$varName» в отдельный самостоятельный товар в каталоге?\n'
          'Складской товар и остатки будут сохранены.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppPrimaryButton(
            label: 'Отсоединить',
            icon: PhosphorIconsRegular.arrowSquareOut,
            onPressed: () {
              context.read<MenuBloc>().add(ExtractVariation(childId));
              setState(() {
                _variations.removeAt(index);
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
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
    final uLabel = UnitFormatter.format(unit);
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

  DuplicateMatch<MenuItem>? _detectDuplicate({
    required List<MenuItem> items,
    required String name,
    required String? flavor,
    required String? barcode,
    required String? rawVolume,
    required List<Map<String, dynamic>> variations,
    required int? categoryId,
    int? excludeItemId,
  }) {
    if (variations.isNotEmpty) {
      final seenVolumes = <String>{};
      final seenBarcodes = <String>{};
      for (final v in variations) {
        final rawVName = v['name']?.toString().trim() ?? '';
        final vBc = v['barcode']?.toString().trim();
        final normV = DuplicateDetector.normalizeVolume(rawVName);

        if (normV.isNotEmpty) {
          if (seenVolumes.contains(normV)) {
            return DuplicateMatch(
              item: MenuItem(id: -1, name: name, price: 0, categoryId: categoryId?.toString() ?? ''),
              matchReason: 'Дубликат объема «$rawVName» внутри серии',
              isSameCategory: true,
            );
          }
          seenVolumes.add(normV);
        }
        if (vBc != null && vBc.isNotEmpty) {
          if (seenBarcodes.contains(vBc)) {
            return DuplicateMatch(
              item: MenuItem(id: -1, name: name, price: 0, categoryId: categoryId?.toString() ?? ''),
              matchReason: 'Дубликат штрихкода «$vBc» внутри серии',
              isSameCategory: true,
            );
          }
          seenBarcodes.add(vBc);
        }

        final match = DuplicateDetector.findMenuItemDuplicate(
          items: items,
          queryName: name,
          isRetail: true,
          queryFlavor: flavor,
          queryVolume: rawVName.isNotEmpty ? rawVName : null,
          queryBarcode: vBc,
          currentCategoryId: categoryId,
          excludeItemId: excludeItemId,
        );
        if (match != null) return match;
      }
      return null;
    }

    return DuplicateDetector.findMenuItemDuplicate(
      items: items,
      queryName: name,
      isRetail: true,
      queryFlavor: flavor,
      queryVolume: rawVolume,
      queryBarcode: barcode,
      currentCategoryId: categoryId,
      excludeItemId: excludeItemId,
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
      final duplicateMatch = _detectDuplicate(
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
          _showDuplicateBlockedDialog(context, duplicateMatch.item);
        }
        return;
      }
    }

    // ─── 2. Формирование атрибутов и массива вариаций ─────────────────────────
    Map<String, dynamic>? attributes;
    double effectivePrice = sPrice;
    String? effectiveBarcode = barcode;

    final List<Map<String, dynamic>> validVars = [];
    if (_variations.isNotEmpty) {
      for (final v in _variations) {
        final rawVName = v['name']?.toString().trim() ?? '';
        final vPrice = (v['price'] is num) ? (v['price'] as num).toDouble() : (double.tryParse(v['price']?.toString() ?? '') ?? 0.0);
        final vBarcode = v['barcode']?.toString().trim();
        if (rawVName.isNotEmpty) {
          final vName = _formatVolume(rawVName, _selectedUnit);
          final fullName = [name, if (flavor != null) flavor, vName].join(' ');
          validVars.add({
            if (v['id'] != null) 'id': v['id'],
            if (v['retail_product_id'] != null) 'retail_product_id': v['retail_product_id'],
            'name': fullName,
            'unit': 'pcs',
            'price': vPrice,
            'selling_price': vPrice,
            'purchase_price': 0.0,
            'initial_stock': 0.0,
            if (vBarcode != null && vBarcode.isNotEmpty) 'barcode': vBarcode,
          });
        }
      }
    }

    if (validVars.length >= 2) {
      effectivePrice = validVars.first['price'] as double;
      attributes = {
        if (_selectedIcon != null) 'icon': 'icon:$_selectedIcon',
        if (flavor != null) 'flavor': flavor,
        'variations': validVars,
      };
    } else {
      // [ИНВАРИАНТ] Если вариаций <= 1 — сохраняем как плоский Flat SKU (без массива variations)
      String? singleVol = formattedVol;
      if (validVars.length == 1) {
        final sVar = validVars.first;
        effectivePrice = sVar['price'] as double;
        final sBc = sVar['barcode'] as String?;
        if (sBc != null && sBc.isNotEmpty) {
          effectiveBarcode = sBc;
        }
        final matchingRow = _variations.firstWhere((v) => (v['name']?.toString().trim().isNotEmpty ?? false));
        singleVol = _formatVolume(matchingRow['name'].toString(), _selectedUnit);
      }
      attributes = {
        if (_selectedIcon != null) 'icon': 'icon:$_selectedIcon',
        if (flavor != null) 'flavor': flavor,
        if (singleVol != null && singleVol.isNotEmpty) 'volume': singleVol,
        'unit': _selectedUnit,
      };
    }

    if (item != null) {
      context.read<MenuBloc>().add(UpdateMenuItem(item.id, {
        'name': name,
        'price': effectivePrice,
        'category_id': _selectedCategoryId,
        'sort_order': sortOrder,
        'barcode': effectiveBarcode,
        'attributes': attributes,
      },),);
    } else {
      context.read<MenuBloc>().add(CreateRetailProduct(
        name: name,
        categoryId: _selectedCategoryId,
        unit: 'pcs',
        purchasePrice: 0.0,
        sellingPrice: effectivePrice,
        sortOrder: sortOrder,
        barcode: effectiveBarcode,
        attributes: attributes,
      ),);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    final menuState = context.watch<MenuBloc>().state;

    DuplicateMatch<MenuItem>? duplicateMatch;
    if (menuState is MenuLoaded) {
      duplicateMatch = _detectDuplicate(
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
