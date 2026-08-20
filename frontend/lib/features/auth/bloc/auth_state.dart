import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String tenantId;
  final String role;
  final List<String> permissions;
  final String fullName;
  final String username;
  final String tenantName;
  final String? tenantAddress;

  const AuthAuthenticated({
    required this.tenantId,
    required this.role,
    required this.permissions,
    this.fullName = '',
    this.username = '',
    this.tenantName = '',
    this.tenantAddress,
  });

  bool hasPermission(String permission) {
    if (role.toLowerCase().contains('owner') || role.toLowerCase().contains('superadmin')) return true;
    return permissions.contains(permission);
  }

  @override
  List<Object?> get props => [tenantId, role, permissions, fullName, username, tenantName, tenantAddress];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
