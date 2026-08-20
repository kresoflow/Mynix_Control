class OfflineOrderPayload {
  final String clientUuid;
  final int orderNumber;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final double totalAmount;
  final int? customerId;
  final double bonusSpent;
  final String? note;
  final DateTime createdAt;
  final String status;
  final String? error;

  const OfflineOrderPayload({
    required this.clientUuid,
    required this.orderNumber,
    required this.items,
    required this.paymentMethod,
    required this.totalAmount,
    this.customerId,
    this.bonusSpent = 0.0,
    this.note,
    required this.createdAt,
    this.status = 'pending',
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_uuid': clientUuid,
      'order_number': orderNumber,
      'items': items,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'customer_id': customerId,
      'bonus_spent': bonusSpent,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'error': error,
    };
  }

  factory OfflineOrderPayload.fromJson(Map<String, dynamic> json) {
    return OfflineOrderPayload(
      clientUuid: json['client_uuid'] as String? ?? '',
      orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customer_id'] as int?,
      bonusSpent: (json['bonus_spent'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      error: json['error'] as String?,
    );
  }

  OfflineOrderPayload copyWith({
    String? status,
    String? error,
  }) {
    return OfflineOrderPayload(
      clientUuid: clientUuid,
      orderNumber: orderNumber,
      items: items,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      customerId: customerId,
      bonusSpent: bonusSpent,
      note: note,
      createdAt: createdAt,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}
