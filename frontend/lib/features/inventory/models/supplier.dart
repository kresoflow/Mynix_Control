class Supplier {
  final int id;
  final String name;
  final String? contactInfo;
  final bool isActive;

  Supplier({
    required this.id,
    required this.name,
    this.contactInfo,
    required this.isActive,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      contactInfo: json['contact_info'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
      'is_active': isActive,
    };
  }
}
