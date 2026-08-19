class InventoryDocumentItem {
  final int? id;
  final int? documentId;
  final int? ingredientId;
  final String? ingredientName;
  final int? retailProductId;
  final String? retailProductName;
  final double quantity;
  final double pricePerUnit;
  final double totalPrice;

  InventoryDocumentItem({
    this.id,
    this.documentId,
    this.ingredientId,
    this.ingredientName,
    this.retailProductId,
    this.retailProductName,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
  });

  factory InventoryDocumentItem.fromJson(Map<String, dynamic> json) {
    return InventoryDocumentItem(
      id: json['id'],
      documentId: json['document_id'],
      ingredientId: json['ingredient_id'],
      ingredientName: json['ingredient_name'],
      retailProductId: json['retail_product_id'],
      retailProductName: json['retail_product_name'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      pricePerUnit: (json['price_per_unit'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'retail_product_id': retailProductId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
    };
  }
}

class InventoryDocument {
  final int id;
  final String type; // 'receipt', 'write_off'
  final String status; // 'draft', 'completed'
  final DateTime date;
  final int? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final String? reason;
  final double totalAmount;
  final String paymentStatus; // 'unpaid', 'paid', 'partial'
  final double paidAmount;
  final String paymentMethod;
  final List<InventoryDocumentItem>? items;

  InventoryDocument({
    required this.id,
    required this.type,
    required this.status,
    required this.date,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.reason,
    required this.totalAmount,
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0.0,
    this.paymentMethod = 'cash',
    this.items,
  });

  factory InventoryDocument.fromJson(Map<String, dynamic> json) {
    return InventoryDocument(
      id: json['id'],
      type: json['type'] ?? 'receipt',
      status: json['status'] ?? 'draft',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      invoiceNumber: json['invoice_number'],
      reason: json['reason'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => InventoryDocumentItem.fromJson(i)).toList()
          : null,
    );
  }
}
