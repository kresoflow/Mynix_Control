
class PosOrder {
  final int id;
  final int orderNumber;
  final String status;
  final String paymentMethod;
  final String? paymentAccount;
  final double total;
  final String? note;
  final DateTime createdAt;
  final List<PosOrderItem> items;

  PosOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    this.paymentAccount,
    required this.total,
    this.note,
    required this.createdAt,
    required this.items,
  });

  PosOrder copyWith({
    int? id,
    int? orderNumber,
    String? status,
    String? paymentMethod,
    String? paymentAccount,
    double? total,
    String? note,
    DateTime? createdAt,
    List<PosOrderItem>? items,
  }) {
    return PosOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccount: paymentAccount ?? this.paymentAccount,
      total: total ?? this.total,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  String get paymentMethodLabel {
    final method = paymentMethod.toLowerCase();
    final account = (paymentAccount ?? '').toLowerCase();
    final rawNote = (note ?? '').toLowerCase();

    if (account == 'dc' || account.contains('dc')) return 'Перевод (DC)';
    if (account == 'alif' || account.contains('alif')) return 'Перевод (Алиф)';
    if (account == 'spitamen' || account.contains('spitamen')) return 'Перевод (Спитамен)';
    if (account == 'other') return 'Перевод (Другой)';
    if (account == 'cash') return 'Наличные';

    if (rawNote.contains('dc') || rawNote.contains('dushanbe')) return 'Перевод (DC)';
    if (rawNote.contains('alif') || rawNote.contains('алиф')) return 'Перевод (Алиф)';
    if (rawNote.contains('spitamen') || rawNote.contains('спитамен')) return 'Перевод (Спитамен)';
    if (rawNote.startsWith('перевод:')) return note!;

    if (method.contains('dc')) return 'Перевод (DC)';
    if (method.contains('alif')) return 'Перевод (Алиф)';
    if (method.contains('spitamen')) return 'Перевод (Спитамен)';
    if (method == 'cash') return 'Наличные';
    if (method == 'transfer' || method == 'card') return 'Перевод';
    if (method == 'debt') return 'В долг';
    if (method == 'deposit') return 'Депозит';
    return 'Безналичный';
  }

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] as String?;
    DateTime parsedDate;
    if (rawDate != null) {
      if (!rawDate.endsWith('Z') && !rawDate.contains('+')) {
        parsedDate = DateTime.parse('${rawDate}Z').toLocal();
      } else {
        parsedDate = DateTime.parse(rawDate).toLocal();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return PosOrder(
      id: json['id'] as int,
      orderNumber: json['order_number'] as int,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentAccount: json['payment_account'] as String?,
      total: (json['total'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: parsedDate,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PosOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PosOrderItem {
  final String menuItemName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String itemType;
  final Map<String, dynamic>? selectedOptions;

  PosOrderItem({
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.itemType,
    this.selectedOptions,
  });

  /// Базовое очищенное имя товара без скобок, вкусов и системных тегов.
  String get cleanName {
    String name = menuItemName.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0].trim();
    if (name.contains('(')) {
      name = name.split('(')[0].trim();
    }
    return name;
  }

  /// Краткая сводка выбранной вариации и модификаторов (например, "Классик • 200 г").
  String? get optionsSummary {
    final List<String> parts = [];

    if (selectedOptions != null && selectedOptions!.isNotEmpty) {
      if (selectedOptions!['variation'] != null) {
        String varName = selectedOptions!['variation'].toString();
        varName = varName.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0];
        final baseName = cleanName;
        if (varName.startsWith(baseName)) {
          varName = varName.substring(baseName.length).trim();
        }
        if (varName.startsWith('(') && varName.endsWith(')')) {
          varName = varName.substring(1, varName.length - 1).trim();
        }
        if (varName.startsWith('•')) {
          varName = varName.substring(1).trim();
        }
        if (varName.isNotEmpty) {
          parts.add(varName);
        }
      }

      if (selectedOptions!['modifiers'] != null && selectedOptions!['modifiers'] is List) {
        for (var m in selectedOptions!['modifiers']) {
          if (m is Map && m['name'] != null) {
            final String mName = m['name'].toString().split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0].trim();
            if (mName.isNotEmpty) {
              parts.add(mName);
            }
          }
        }
      }
    }

    if (parts.isEmpty) {
      final rawClean = menuItemName.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0].trim();
      if (rawClean.contains('(') && rawClean.endsWith(')')) {
        final startIndex = rawClean.indexOf('(');
        final extracted = rawClean.substring(startIndex + 1, rawClean.length - 1).trim();
        if (extracted.isNotEmpty) {
          parts.add(extracted);
        }
      }
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return null;
  }

  factory PosOrderItem.fromJson(Map<String, dynamic> json) {
    return PosOrderItem(
      menuItemName: json['menu_item_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      itemType: json['item_type'] as String,
      selectedOptions: json['selected_options'] as Map<String, dynamic>?,
    );
  }
}
