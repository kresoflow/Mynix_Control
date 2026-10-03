// ============================================================================
// Kreso Flow | Superadmin Domain | Tenant Entity Model
// ============================================================================

import 'package:equatable/equatable.dart';

// ─── 1. Tenant Entity ────────────────────────────────────────────────────────

/// Сущность организации (тенанта) в multi-tenant архитектуре Kreso Flow.
/// Отражает конфигурацию изолированной PostgreSQL схемы и данные владельца.
class Tenant extends Equatable {
  final int id;
  final String name;
  final String schemaName;
  final String address;
  final String currency;
  final bool isActive;
  final bool useKds;
  final bool useOrders;
  final bool enableInventoryDeduction;
  final String createdAt;
  final int? ownerId;
  final String? ownerUsername;
  final String? ownerFullName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? ownerPinCode;

  const Tenant({
    required this.id,
    required this.name,
    required this.schemaName,
    required this.address,
    this.currency = 'сом',
    required this.isActive,
    this.useKds = true,
    this.useOrders = true,
    this.enableInventoryDeduction = true,
    required this.createdAt,
    this.ownerId,
    this.ownerUsername,
    this.ownerFullName,
    this.ownerPhone,
    this.ownerEmail,
    this.ownerPinCode,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as int,
      name: json['name'] as String,
      schemaName: json['schema_name'] as String,
      address: (json['address'] as String?) ?? '',
      currency: (json['currency'] as String?) ?? 'сом',
      isActive: (json['is_active'] as bool?) ?? true,
      useKds: (json['use_kds'] as bool?) ?? true,
      useOrders: (json['use_orders'] as bool?) ?? true,
      enableInventoryDeduction: (json['enable_inventory_deduction'] as bool?) ?? true,
      createdAt: (json['created_at'] as String?) ?? '',
      ownerId: json['owner_id'] as int?,
      ownerUsername: json['owner_username'] as String?,
      ownerFullName: json['owner_full_name'] as String?,
      ownerPhone: json['owner_phone'] as String?,
      ownerEmail: json['owner_email'] as String?,
      ownerPinCode: json['owner_pin_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schema_name': schemaName,
      'address': address,
      'currency': currency,
      'is_active': isActive,
      'use_kds': useKds,
      'use_orders': useOrders,
      'enable_inventory_deduction': enableInventoryDeduction,
      'created_at': createdAt,
      'owner_id': ownerId,
      'owner_username': ownerUsername,
      'owner_full_name': ownerFullName,
      'owner_phone': ownerPhone,
      'owner_email': ownerEmail,
      'owner_pin_code': ownerPinCode,
    };
  }

  Tenant copyWith({
    int? id,
    String? name,
    String? schemaName,
    String? address,
    String? currency,
    bool? isActive,
    bool? useKds,
    bool? useOrders,
    bool? enableInventoryDeduction,
    String? createdAt,
    int? ownerId,
    String? ownerUsername,
    String? ownerFullName,
    String? ownerPhone,
    String? ownerEmail,
    String? ownerPinCode,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      schemaName: schemaName ?? this.schemaName,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      useKds: useKds ?? this.useKds,
      useOrders: useOrders ?? this.useOrders,
      enableInventoryDeduction: enableInventoryDeduction ?? this.enableInventoryDeduction,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerFullName: ownerFullName ?? this.ownerFullName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPinCode: ownerPinCode ?? this.ownerPinCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    schemaName,
    address,
    currency,
    isActive,
    useKds,
    useOrders,
    enableInventoryDeduction,
    createdAt,
    ownerId,
    ownerUsername,
    ownerFullName,
    ownerPhone,
    ownerEmail,
    ownerPinCode,
  ];
}
