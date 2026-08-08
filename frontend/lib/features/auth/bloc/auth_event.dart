import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String tenantId;
  final String role;
  final List<String> permissions;

  const LoggedIn({
    required this.tenantId,
    required this.role,
    required this.permissions,
  });

  @override
  List<Object?> get props => [tenantId, role, permissions];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  
  const LoginRequested(this.username, this.password);
  
  @override
  List<Object?> get props => [username, password];
}

class LoginByPinRequested extends AuthEvent {
  final String pinCode;
  
  const LoginByPinRequested(this.pinCode);
  
  @override
  List<Object?> get props => [pinCode];
}

class LoggedOut extends AuthEvent {}
