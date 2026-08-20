import 'dart:convert';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';

class ModifiersCalculator {
  static double calculateModifiersPrice({
    required List<dynamic> modifierGroups,
    required Map<int, Set<int>> selectedModifiers,
  }) {
    double additional = 0.0;
    for (int g = 0; g < modifierGroups.length; g++) {
      final mods = modifierGroups[g]['modifiers'] as List<dynamic>;
      for (int mIndex in (selectedModifiers[g] ?? {})) {
        additional += (mods[mIndex]['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return additional;
  }

  static double calculateAdditionalPrice({
    required MenuItem item,
    required List<dynamic> variations,
    required List<dynamic> modifierGroups,
    required Map<int, Set<int>> selectedModifiers,
    required int? variationIndex,
  }) {
    double additional = calculateModifiersPrice(
      modifierGroups: modifierGroups,
      selectedModifiers: selectedModifiers,
    );
    if (variationIndex != null && variations.isNotEmpty) {
      final basePrice = item.price;
      final varPrice = (variations[variationIndex]['price'] as num?)?.toDouble() ?? 0.0;
      additional += (varPrice - basePrice);
    }
    return additional;
  }

  static String generateSelectedJson({
    required List<dynamic> variations,
    required List<dynamic> modifierGroups,
    required Map<int, Set<int>> selectedModifiers,
    required int? variationIndex,
  }) {
    final Map<String, dynamic> selected = {};
    if (variationIndex != null && variations.isNotEmpty) {
      selected['variation'] = variations[variationIndex]['name'];
      if (variations[variationIndex]['id'] != null) {
        selected['child_item_id'] = variations[variationIndex]['id'];
      }
    }
    final List<Map<String, dynamic>> modsList = [];
    for (int g = 0; g < modifierGroups.length; g++) {
      final group = modifierGroups[g];
      final mods = group['modifiers'] as List<dynamic>;
      for (int mIndex in (selectedModifiers[g] ?? {})) {
        modsList.add({
          'group': group['name'],
          'name': mods[mIndex]['name'],
          'price': mods[mIndex]['price'],
        });
      }
    }
    if (modsList.isNotEmpty) {
      selected['modifiers'] = modsList;
    }
    return jsonEncode(selected);
  }
}
