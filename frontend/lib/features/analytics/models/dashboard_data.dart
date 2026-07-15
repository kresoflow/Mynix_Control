class TopItem {
  final String name;
  final String? options;
  final int quantitySold;

  TopItem({required this.name, this.options, required this.quantitySold});

  factory TopItem.fromJson(Map<String, dynamic> json) {
    return TopItem(
      name: json['name'] ?? '',
      options: json['options'],
      quantitySold: json['quantity_sold'] ?? 0,
    );
  }
}

class RecentOrderItem {
  final String name;
  final String? options;
  final int quantity;

  RecentOrderItem({required this.name, this.options, required this.quantity});

  factory RecentOrderItem.fromJson(Map<String, dynamic> json) {
    return RecentOrderItem(
      name: json['name'] ?? '',
      options: json['options'],
      quantity: json['quantity'] ?? 1,
    );
  }
}

class RecentOrder {
  final String orderNumber;
  final DateTime createdAt;
  final double total;
  final List<RecentOrderItem> items;

  RecentOrder({
    required this.orderNumber,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      orderNumber: json['order_number'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List?)?.map((e) => RecentOrderItem.fromJson(e)).toList() ?? [],
    );
  }
}

class LowStockAlert {
  final String name;
  final double currentStock;

  LowStockAlert({required this.name, required this.currentStock});

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    return LowStockAlert(
      name: json['name'] ?? '',
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardData {
  final double totalRevenue;
  final int totalOrders;
  final double dishesRevenue;
  final double retailRevenue;
  final List<LowStockAlert> lowStockAlerts;
  final List<TopItem> topItems;
  final List<RecentOrder> recentOrders;

  DashboardData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.dishesRevenue,
    required this.retailRevenue,
    required this.lowStockAlerts,
    required this.topItems,
    required this.recentOrders,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      dishesRevenue: (json['dishes_revenue'] as num?)?.toDouble() ?? 0.0,
      retailRevenue: (json['retail_revenue'] as num?)?.toDouble() ?? 0.0,
      lowStockAlerts:
          (json['low_stock_alerts'] as List?)
              ?.map((e) => LowStockAlert.fromJson(e))
              .toList() ??
          [],
      topItems:
          (json['top_items'] as List?)
              ?.map((e) => TopItem.fromJson(e))
              .toList() ??
          [],
      recentOrders:
          (json['recent_orders'] as List?)
              ?.map((e) => RecentOrder.fromJson(e))
              .toList() ??
          [],
    );
  }
}
