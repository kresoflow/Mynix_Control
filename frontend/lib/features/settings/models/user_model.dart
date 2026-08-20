class StaffUser {
  final int id;
  final int tenantId;
  final String username;
  final String fullName;
  final bool isActive;
  final String? pinCode;
  final List<String> roles;

  StaffUser({
    required this.id,
    required this.tenantId,
    required this.username,
    required this.fullName,
    required this.isActive,
    this.pinCode,
    required this.roles,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool,
      pinCode: json['pin_code'] as String?,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}

class Role {
  final int id;
  final String name;
  final String description;

  Role({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}
