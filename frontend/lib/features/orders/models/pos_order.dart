
class PosOrder {
  final int id;
  final int orderNumber;
  final String status;
  final String paymentMethod;
  final double total;
  final String? note;
  final DateTime createdAt;
  final List<PosOrderItem> items;

  PosOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
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
      total: total ?? this.total,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    return PosOrder(
      id: json['id'] as int,
      orderNumber: json['order_number'] as int,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      total: (json['total'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
