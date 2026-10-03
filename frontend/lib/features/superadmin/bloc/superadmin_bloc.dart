// ============================================================================
// Kreso Flow | Superadmin Domain | Superadmin BLoC
// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/tenant.dart';
import '../repository/superadmin_repository.dart';

// ─── 1. States ───────────────────────────────────────────────────────────────

abstract class SuperadminState extends Equatable {
  const SuperadminState();

  @override
  List<Object?> get props => [];
}

class SuperadminInitial extends SuperadminState {}

class SuperadminLoading extends SuperadminState {}

class SuperadminLoaded extends SuperadminState {
  final List<Tenant> tenants;
  const SuperadminLoaded(this.tenants);

  @override
  List<Object?> get props => [tenants];
}

class SuperadminError extends SuperadminState {
  final String message;
  const SuperadminError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── 2. Cubit / BLoC ─────────────────────────────────────────────────────────

/// BLoC управления реестром организаций и тенантов в Kreso Flow.
class SuperadminBloc extends Cubit<SuperadminState> {
  final SuperadminRepository repository;
  String _systemToken = '';

  SuperadminBloc({required this.repository}) : super(SuperadminInitial());

  void setTokenAndLoad(String token) {
    _systemToken = token;
    loadTenants();
  }

  Future<void> loadTenants() async {
    emit(SuperadminLoading());
    try {
      final tenants = await repository.getTenants(_systemToken);
      tenants.sort((a, b) => a.id.compareTo(b.id));
      emit(SuperadminLoaded(tenants));
    } catch (e) {
      emit(SuperadminError(e.toString()));
    }
  }

  Future<void> createTenant({
    required String name,
    required String schemaName,
    required String address,
    String currency = 'сом',
    required String ownerUsername,
    required String ownerPassword,
    required String ownerFullName,
    String ownerPinCode = '1234',
    String? ownerPhone,
    String? ownerEmail,
    bool useKds = true,
    bool useOrders = true,
    bool enableInventoryDeduction = true,
  }) async {
    final currentState = state;
    emit(SuperadminLoading());
    try {
      await repository.createTenant(
        systemToken: _systemToken,
        name: name,
        schemaName: schemaName,
        address: address,
        currency: currency,
        ownerUsername: ownerUsername,
        ownerPassword: ownerPassword,
        ownerFullName: ownerFullName,
        ownerPinCode: ownerPinCode,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        useKds: useKds,
        useOrders: useOrders,
        enableInventoryDeduction: enableInventoryDeduction,
      );
      await loadTenants();
    } catch (e) {
      emit(SuperadminError(e.toString()));
      if (currentState is SuperadminLoaded) {
        await Future.delayed(const Duration(seconds: 3));
        emit(currentState);
      }
    }
  }

  Future<void> toggleTenantStatus(int tenantId, bool isActive) async {
    try {
      await repository.toggleTenantStatus(
        systemToken: _systemToken,
        tenantId: tenantId,
        isActive: isActive,
      );
      await loadTenants();
    } catch (e) {
      emit(SuperadminError(e.toString()));
    }
  }

  Future<void> updateTenant({
    required int tenantId,
    String? name,
    String? address,
    String? currency,
    bool? isActive,
    bool? useKds,
    bool? useOrders,
    bool? enableInventoryDeduction,
    String? ownerFullName,
    String? ownerPhone,
    String? ownerEmail,
    String? ownerPassword,
    String? ownerPinCode,
  }) async {
    emit(SuperadminLoading());
    try {
      await repository.updateTenant(
        systemToken: _systemToken,
        tenantId: tenantId,
        name: name,
        address: address,
        currency: currency,
        isActive: isActive,
        useKds: useKds,
        useOrders: useOrders,
        enableInventoryDeduction: enableInventoryDeduction,
        ownerFullName: ownerFullName,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        ownerPassword: ownerPassword,
        ownerPinCode: ownerPinCode,
      );
      await loadTenants();
    } catch (e) {
      emit(SuperadminError(e.toString()));
    }
  }

  Future<void> deleteTenant(int tenantId) async {
    emit(SuperadminLoading());
    try {
      await repository.deleteTenant(
        systemToken: _systemToken,
        tenantId: tenantId,
      );
      await loadTenants();
    } catch (e) {
      emit(SuperadminError(e.toString()));
    }
  }
}
