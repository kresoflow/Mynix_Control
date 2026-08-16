import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/superadmin_repository.dart';

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
      emit(SuperadminLoaded(tenants));
    } catch (e) {
      emit(SuperadminError(e.toString()));
    }
  }

  Future<void> createTenant({
    required String name,
    required String schemaName,
    required String address,
    required String ownerUsername,
    required String ownerPassword,
    required String ownerFullName,
    String ownerPinCode = '1234',
    String? ownerPhone,
    String? ownerEmail,
    bool useKds = true,
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
        ownerUsername: ownerUsername,
        ownerPassword: ownerPassword,
        ownerFullName: ownerFullName,
        ownerPinCode: ownerPinCode,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        useKds: useKds,
        enableInventoryDeduction: enableInventoryDeduction,
      );
      // Reload tenants
      await loadTenants();
    } catch (e) {
      emit(SuperadminError(e.toString()));
      if (currentState is SuperadminLoaded) {
        // Revert to loaded state after showing error
        await Future.delayed(const Duration(seconds: 3));
        emit(currentState);
      }
    }
  }
}
