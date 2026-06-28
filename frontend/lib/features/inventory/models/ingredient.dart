class Ingredient {
  final int id;
  final String name;
  final String unit;
  final double currentStock;
  final double minStockAlert;
  final double costPerUnit;
  final bool isLowStock;
  final double? price;
  final Map<String, dynamic>? attributes;
  final int? categoryId;
  final String? categoryName;

  bool get isRetail => attributes?['is_retail'] == true;

  Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStockAlert,
    required this.costPerUnit,
    required this.isLowStock,
    this.price,
    this.attributes,
    this.categoryId,
    this.categoryName,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      currentStock: (json['current_stock'] as num).toDouble(),
      minStockAlert: (json['min_stock_alert'] as num).toDouble(),
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      isLowStock: json['is_low_stock'] ?? false,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      attributes: json['attributes'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }
}
