import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/orders/models/pos_order.dart';

void main() {
  group('MenuItem Flavor & Variations Invariants', () {
    test('Correctly extracts flavor and formats 3 variations summary without commas', () {
      const item = MenuItem(
        id: 1,
        name: 'Сникерс|TYPE|retail|ATTR|{}|ICON|chocolate',
        price: 10.0,
        categoryId: '1',
        attributesJson: '{"flavor": "Классик", "variations": [{"name": "Сникерс (Классик • 50г)", "price": 10}, {"name": "Сникерс (Классик • 200г)", "price": 30}, {"name": "Сникерс (Классик • 300г)", "price": 40}]}',
      );

      expect(item.cleanName, 'Сникерс');
      expect(item.flavorString, 'Классик');
      expect(item.variationLabels, ['50г', '200г', '300г']);
      expect(item.variationsSummary, '50г  200г  300г');
      expect(item.attributesString, 'Классик • 50г  200г  300г');
      expect(item.variationPrices, [10.0, 30.0, 40.0]);
    });

    test('Correctly formats single variation created from retail dialog with unit', () {
      const item = MenuItem(
        id: 2,
        name: 'Фанта|TYPE|retail',
        price: 10.0,
        categoryId: '1',
        attributesJson: '{"flavor": "апельсин", "variations": [{"name": "Фанта апельсин 1 л", "price": 10.0}]}',
      );

      expect(item.cleanName, 'Фанта');
      expect(item.flavorString, 'апельсин');
      expect(item.variationLabels, ['1 л']);
      expect(item.variationsSummary, '1 л');
      expect(item.attributesString, 'апельсин • 1 л');
    });

    test('Correctly formats merged variations for same flavor', () {
      const item = MenuItem(
        id: 3,
        name: 'Фанта|TYPE|retail',
        price: 10.0,
        categoryId: '1',
        attributesJson: '{"flavor": "апельсин", "variations": [{"name": "Фанта апельсин 1 л", "price": 10.0}, {"name": "Фанта апельсин 1.5 л", "price": 15.0}]}',
      );

      expect(item.cleanName, 'Фанта');
      expect(item.flavorString, 'апельсин');
      expect(item.variationLabels, ['1 л', '1.5 л']);
      expect(item.variationsSummary, '1 л  1.5 л');
      expect(item.attributesString, 'апельсин • 1 л  1.5 л');
    });

    test('Correctly formats 4+ variations count', () {
      const item = MenuItem(
        id: 4,
        name: 'Кола|TYPE|retail',
        price: 5.0,
        categoryId: '2',
        attributesJson: '{"flavor": "Zero", "variations": [{"name": "0.33л", "price": 5}, {"name": "0.5л", "price": 7}, {"name": "1л", "price": 10}, {"name": "1.5л", "price": 12}]}',
      );

      expect(item.cleanName, 'Кола');
      expect(item.flavorString, 'Zero');
      expect(item.variationLabels.length, 4);
      expect(item.variationsSummary, '4 вариаций');
      expect(item.attributesString, 'Zero • 4 вариаций');
    });
  });

  group('PosOrderItem cleanName & optionsSummary Invariants', () {
    test('Correctly parses cleanName and optionsSummary from selectedOptions', () {
      final item = PosOrderItem(
        menuItemName: 'Сникерс (Классик • 200 г)|TYPE|retail',
        quantity: 1,
        unitPrice: 10.0,
        subtotal: 10.0,
        itemType: 'retail',
        selectedOptions: {'variation': 'Сникерс (Классик • 200 г)', 'child_item_id': 123},
      );

      expect(item.cleanName, 'Сникерс');
      expect(item.optionsSummary, 'Классик • 200 г');
    });

    test('Correctly extracts optionsSummary from menuItemName when selectedOptions is null', () {
      final item = PosOrderItem(
        menuItemName: 'Сникерс (Классик • 300 г)',
        quantity: 1,
        unitPrice: 20.0,
        subtotal: 20.0,
        itemType: 'retail',
      );

      expect(item.cleanName, 'Сникерс');
      expect(item.optionsSummary, 'Классик • 300 г');
    });

    test('Simple item without variations returns null optionsSummary', () {
      final item = PosOrderItem(
        menuItemName: 'Самса|TYPE|dish',
        quantity: 2,
        unitPrice: 15.0,
        subtotal: 30.0,
        itemType: 'dish',
      );

      expect(item.cleanName, 'Самса');
      expect(item.optionsSummary, isNull);
    });
  });
}
