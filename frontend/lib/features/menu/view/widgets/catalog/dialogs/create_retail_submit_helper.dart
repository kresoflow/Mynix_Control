// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Хелпер сборки полезной нагрузки ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/create_retail_submit_helper.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';

class CreateRetailSubmitPayload {
  final Map<String, dynamic>? attributes;
  final double effectivePrice;
  final String? effectiveBarcode;

  const CreateRetailSubmitPayload({
    required this.attributes,
    required this.effectivePrice,
    required this.effectiveBarcode,
  });
}

class CreateRetailSubmitHelper {
  static List<Map<String, dynamic>> parseInitialVariations(MenuItem? item) {
    if (item?.variations == null || item!.variations!.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
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
      result.add({
        'id': rawMap['id'],
        'retail_product_id': rawMap['retail_product_id'],
        'name': varName.isNotEmpty ? varName : (rawMap['name']?.toString() ?? ''),
        'price': (rawMap['price'] is num)
            ? (rawMap['price'] as num).toDouble()
            : (double.tryParse(rawMap['price']?.toString() ?? '') ?? 0.0),
        'barcode': rawMap['barcode']?.toString(),
        'unit': rawMap['unit']?.toString() ?? 'pcs',
      });
    }
    return result;
  }

  static void showExtractVariationDialog(
    BuildContext context, {
    required int childId,
    required String varName,
    required VoidCallback onExtracted,
  }) {
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
              onExtracted();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static String formatVolume(String volume, String unit) {
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

  static CreateRetailSubmitPayload buildPayload({
    required String name,
    required double basePrice,
    required String? baseBarcode,
    required String? flavor,
    required String? rawVolume,
    required String selectedUnit,
    required String? selectedIcon,
    required List<Map<String, dynamic>> variations,
  }) {
    final formattedVol = rawVolume != null ? formatVolume(rawVolume, selectedUnit) : null;
    Map<String, dynamic>? attributes;
    double effectivePrice = basePrice;
    String? effectiveBarcode = baseBarcode;

    final List<Map<String, dynamic>> validVars = [];
    if (variations.isNotEmpty) {
      for (final v in variations) {
        final rawVName = v['name']?.toString().trim() ?? '';
        final vPrice = (v['price'] is num)
            ? (v['price'] as num).toDouble()
            : (double.tryParse(v['price']?.toString() ?? '') ?? 0.0);
        final vBarcode = v['barcode']?.toString().trim();
        if (rawVName.isNotEmpty) {
          final vName = formatVolume(rawVName, selectedUnit);
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
        if (selectedIcon != null) 'icon': 'icon:$selectedIcon',
        if (flavor != null) 'flavor': flavor,
        'variations': validVars,
      };
    } else {
      String? singleVol = formattedVol;
      if (validVars.length == 1) {
        final sVar = validVars.first;
        effectivePrice = sVar['price'] as double;
        final sBc = sVar['barcode'] as String?;
        if (sBc != null && sBc.isNotEmpty) {
          effectiveBarcode = sBc;
        }
        final matchingRow = variations.firstWhere((v) => (v['name']?.toString().trim().isNotEmpty ?? false));
        singleVol = formatVolume(matchingRow['name'].toString(), selectedUnit);
      }
      attributes = {
        if (selectedIcon != null) 'icon': 'icon:$selectedIcon',
        if (flavor != null) 'flavor': flavor,
        if (singleVol != null && singleVol.isNotEmpty) 'volume': singleVol,
        'unit': selectedUnit,
      };
    }

    return CreateRetailSubmitPayload(
      attributes: attributes,
      effectivePrice: effectivePrice,
      effectiveBarcode: effectiveBarcode,
    );
  }
}
