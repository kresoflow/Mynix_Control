import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../repository/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoginRequested>(_onLoginRequested);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final hasToken = await authRepository.hasToken();
      if (hasToken) {
        final profile = await authRepository.getMe();
        emit(AuthAuthenticated(
          tenantId: profile['tenant_id']?.toString() ?? 'unknown',
          role: (profile['roles'] is List) ? (profile['roles'] as List).firstOrNull?.toString() ?? 'unknown' : 'unknown',
          permissions: List<String>.from(profile['permissions'] ?? []),
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.login(event.username, event.password);
      if (token != null) {
        final profile = await authRepository.getMe();
        emit(AuthAuthenticated(
          tenantId: profile['tenant_id']?.toString() ?? 'unknown',
          role: (profile['roles'] is List) ? (profile['roles'] as List).firstOrNull?.toString() ?? 'unknown' : 'unknown',
          permissions: List<String>.from(profile['permissions'] ?? []),
        ));
      } else {
        emit(const AuthError("Login failed"));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(
      tenantId: event.tenantId,
      role: event.role,
      permissions: event.permissions,
    ));
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
