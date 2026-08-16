import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/view/widgets/menu_modifiers_dialog.dart';

void handlePosItemClick(BuildContext context, MenuItem item) {
  final List<MenuItem> allItems = context.read<MenuBloc>().state is MenuLoaded
      ? (context.read<MenuBloc>().state as MenuLoaded).items
      : <MenuItem>[];
  final children = allItems.where((i) => i.parentId == item.id).toList();
  bool hasOptions = children.isNotEmpty;
  bool hasExactlyOneVariation = false;
  Map<String, dynamic>? singleVariation;
  List<dynamic>? variations;
  List<dynamic>? modifiers;

  if (item.attributesJson != null &&
      item.attributesJson!.isNotEmpty &&
      item.attributesJson != '{}') {
    try {
      final attrs = jsonDecode(item.attributesJson!);
      variations = attrs['variations'] as List?;
      modifiers = attrs['modifier_groups'] as List?;
      if ((variations != null && variations.isNotEmpty) ||
          (modifiers != null && modifiers.isNotEmpty)) {
        hasOptions = true;
      }
    } catch (_) {}
  }

  if (hasOptions && (modifiers == null || modifiers.isEmpty)) {
    final int varCount = variations != null ? variations.length : 0;
    final int childCount = children.length;

    if (varCount <= 1 && childCount <= 1 && (varCount == 1 || childCount == 1)) {
      hasExactlyOneVariation = true;
      if (varCount == 1) {
        singleVariation = Map<String, dynamic>.from(variations!.first as Map);
      } else {
        singleVariation = {
          'name': children.first.name,
          'price': children.first.price,
        };
      }
      if (childCount == 1) {
        singleVariation['id'] = children.first.id;
      }
    }
  }

  if (hasExactlyOneVariation) {
    final selected = <String, dynamic>{};
    selected['variation'] = singleVariation!['name'];
    if (singleVariation['id'] != null) {
      selected['child_item_id'] = singleVariation['id'];
    }

    final varPrice = (singleVariation['price'] as num?)?.toDouble() ?? 0.0;
    final additional = varPrice - item.price;

    context.read<CartBloc>().add(AddItemToCart(
      item,
      selectedOptionsJson: jsonEncode(selected),
      selectedOptionsPrice: additional,
    ));
  } else if (hasOptions) {
    showDialog(
      context: context,
      builder: (ctx) => MenuModifiersDialog(
        item: item,
        childrenItems: children,
        onAdd: (result) {
          context.read<CartBloc>().add(AddItemToCart(
            item,
            selectedOptionsJson: result['json'],
            selectedOptionsPrice: result['price'],
          ));
        },
      ),
    );
  } else {
    context.read<CartBloc>().add(AddItemToCart(item));
  }
}
