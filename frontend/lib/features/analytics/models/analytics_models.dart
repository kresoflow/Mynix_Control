class TimeSeriesPoint {
  final String timestamp;
  final double revenue;
  final int orders;

  TimeSeriesPoint({
    required this.timestamp,
    required this.revenue,
    required this.orders,
  });

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      timestamp: json['timestamp'],
      revenue: (json['revenue'] as num).toDouble(),
      orders: json['orders'] as int,
    );
  }
}

class AnalyticsMetrics {
  final double totalRevenue;
  final int totalOrders;
  final double netProfit;
  final double marginPercentage;
  final double averageCheck;
  final List<TimeSeriesPoint> timeSeries;

  AnalyticsMetrics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.netProfit,
    required this.marginPercentage,
    required this.averageCheck,
    required this.timeSeries,
  });

  factory AnalyticsMetrics.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetrics(
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalOrders: json['total_orders'] as int,
      netProfit: (json['net_profit'] as num).toDouble(),
      marginPercentage: (json['margin_percentage'] as num).toDouble(),
      averageCheck: (json['average_check'] as num).toDouble(),
      timeSeries: (json['time_series'] as List)
          .map((e) => TimeSeriesPoint.fromJson(e))
          .toList(),
    );
  }
}

class CategorySales {
  final String categoryName;
  final double revenue;
  final double percentage;

  CategorySales({
    required this.categoryName,
    required this.revenue,
    required this.percentage,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) {
    return CategorySales(
      categoryName: json['category_name'],
      revenue: (json['revenue'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class XRayItem {
  final String name;
  final String? options;
  final String category;
  final int quantity;
  final double revenue;

  XRayItem({
    required this.name,
    this.options,
    required this.category,
    required this.quantity,
    required this.revenue,
  });

  factory XRayItem.fromJson(Map<String, dynamic> json) {
    return XRayItem(
      name: json['name'],
      options: json['options'],
      category: json['category'],
      quantity: json['quantity'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class AnalyticsXRay {
  final List<CategorySales> categories;
  final List<XRayItem> items;

  AnalyticsXRay({
    required this.categories,
    required this.items,
  });

  factory AnalyticsXRay.fromJson(Map<String, dynamic> json) {
    return AnalyticsXRay(
      categories: (json['categories'] as List)
          .map((e) => CategorySales.fromJson(e))
          .toList(),
      items: (json['items'] as List)
          .map((e) => XRayItem.fromJson(e))
          .toList(),
    );
  }
}
