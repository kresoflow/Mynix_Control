import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'menu_item/menu_item_basic_fields.dart';
import 'menu_item/menu_item_variations_section.dart';
import 'menu_item/menu_item_modifier_groups_section.dart';

class MenuItemModal extends StatefulWidget {
  final int? preselectedCategoryId;
  final MenuItem? existingItem;

  const MenuItemModal({super.key, this.preselectedCategoryId, this.existingItem});

  @override
  State<MenuItemModal> createState() => _MenuItemModalState();
}

class _MenuItemModalState extends State<MenuItemModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;
  late TextEditingController _sortOrderController;

  bool _hasModifiers = false;
  final List<Map<String, dynamic>> _variations = [];
  final List<Map<String, dynamic>> _modifierGroups = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.cleanName ?? '');
    _priceController = TextEditingController(text: widget.existingItem?.price.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.existingItem?.barcode ?? '');
    final sort = widget.existingItem?.sortOrder ?? 0;
    _sortOrderController = TextEditingController(text: sort > 0 ? sort.toString() : '');

    if (widget.existingItem?.attributesJson != null && widget.existingItem!.attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(widget.existingItem!.attributesJson!);
        if (attrs.containsKey('variations')) {
          for (var v in attrs['variations']) {
            _variations.add(Map<String, dynamic>.from(v));
          }
        }
        if (attrs.containsKey('modifier_groups')) {
          for (var mg in attrs['modifier_groups']) {
            _modifierGroups.add(Map<String, dynamic>.from(mg));
          }
        }
        if (_variations.isNotEmpty || _modifierGroups.isNotEmpty) {
          _hasModifiers = true;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _addVariation() {
    setState(() {
      _variations.add({'name': '', 'price': 0});
    });
  }

  void _addModifierGroup() {
    setState(() {
      _modifierGroups.add({
        'name': '',
        'required': false,
        'max_selections': 1,
        'modifiers': [],
      });
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate() && (widget.preselectedCategoryId != null || widget.existingItem != null)) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final categoryId = widget.existingItem?.categoryId.toString() ?? widget.preselectedCategoryId.toString();
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

      Map<String, dynamic>? attributes;

      if (_hasModifiers) {
        attributes = {};
        if (_variations.isNotEmpty) {
          attributes['variations'] = _variations;
        }
        if (_modifierGroups.isNotEmpty) {
          attributes['modifier_groups'] = _modifierGroups;
        }
      }

      final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();

      if (widget.existingItem != null) {
        context.read<MenuBloc>().add(UpdateMenuItem(
          widget.existingItem!.id,
          {
            'name': name,
            'price': price,
            'sort_order': sortOrder,
            'attributes': attributes,
            'barcode': barcode,
          },
        ));
      } else {
        context.read<MenuBloc>().add(
          CreateMenuItem(
            name: name,
            category: categoryId,
            price: price,
            sortOrder: sortOrder,
            attributes: attributes,
            barcode: barcode,
          ),
        );
      }

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MynixDialog(
      title: isEditing ? 'Редактировать блюдо' : 'Новое блюдо',
      icon: PhosphorIconsRegular.bowlFood,
      width: 580,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MenuItemBasicFields(
                nameController: _nameController,
                priceController: _priceController,
                barcodeController: _barcodeController,
                sortOrderController: _sortOrderController,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  borderRadius: AppRadii.cardRadius,
                ),
                child: SwitchListTile(
                  title: Text(
                    'Размеры или модификаторы (опции)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  value: _hasModifiers,
                  onChanged: (val) => setState(() => _hasModifiers = val),
                  activeColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
                ),
              ),
              if (_hasModifiers) ...[
                const SizedBox(height: 20),
                MenuItemVariationsSection(
                  variations: _variations,
                  onAddVariation: _addVariation,
                  onRemoveVariation: (i) => setState(() => _variations.removeAt(i)),
                ),
                const SizedBox(height: 20),
                MenuItemModifierGroupsSection(
                  modifierGroups: _modifierGroups,
                  onAddGroup: _addModifierGroup,
                  onRemoveGroup: (gIndex) => setState(() => _modifierGroups.removeAt(gIndex)),
                  onAddOption: (gIndex) => setState(() => (_modifierGroups[gIndex]['modifiers'] as List).add({'name': '', 'price': 0})),
                  onRemoveOption: (gIndex, mIndex) => setState(() => (_modifierGroups[gIndex]['modifiers'] as List).removeAt(mIndex)),
                  onToggleRequired: (gIndex, val) => setState(() => _modifierGroups[gIndex]['required'] = val),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        AppPrimaryButton(
          label: isEditing ? 'Сохранить' : 'Создать',
          icon: PhosphorIconsRegular.floppyDisk,
          width: null,
          onPressed: _submit,
        ),
      ],
    );
  }
}
