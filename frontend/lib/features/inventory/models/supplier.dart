class Supplier {
  final int id;
  final String name;
  final String? contactInfo;
  final bool isActive;
  final double balance;

  Supplier({
    required this.id,
    required this.name,
    this.contactInfo,
    required this.isActive,
    this.balance = 0.0,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      contactInfo: json['contact_info'],
      isActive: json['is_active'] ?? true,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
      'is_active': isActive,
      'balance': balance,
    };
  }
}
