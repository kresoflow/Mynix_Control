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
    on<LoginByPinRequested>(_onLoginByPinRequested);
    on<RefreshProfile>(_onRefreshProfile);
    on<LoggedOut>(_onLoggedOut);
  }

  AuthAuthenticated _createAuthenticatedState(Map<String, dynamic> profile) {
    final roles = profile['roles'] as List? ?? [];
    final role = roles.isNotEmpty ? roles.first.toString() : 'unknown';

    return AuthAuthenticated(
      tenantId: profile['tenant_id']?.toString() ?? 'unknown',
      role: role,
      permissions: List<String>.from(profile['permissions'] ?? []),
      fullName: profile['full_name']?.toString() ?? '',
      username: profile['username']?.toString() ?? '',
      tenantName: profile['tenant_name']?.toString() ?? 'Kreso Flow Point',
      tenantAddress: profile['tenant_address']?.toString(),
      useKds: profile['use_kds'] as bool? ?? true,
      useOrders: profile['use_orders'] as bool? ?? true,
      enableInventoryDeduction: profile['enable_inventory_deduction'] as bool? ?? true,
    );
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final hasToken = await authRepository.hasToken();
      if (hasToken) {
        final profile = await authRepository.getMe();
        emit(_createAuthenticatedState(profile));
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
        emit(_createAuthenticatedState(profile));
      } else {
        emit(const AuthError('Не удалось выполнить вход'));
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      emit(AuthError(msg));
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(
      tenantId: event.tenantId,
      role: event.role,
      permissions: event.permissions,
    ));
  }

  Future<void> _onLoginByPinRequested(LoginByPinRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.loginByPin(event.pinCode);
      if (token != null) {
        final profile = await authRepository.getMe();
        emit(_createAuthenticatedState(profile));
      } else {
        emit(const AuthError('Неверный PIN-код'));
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      emit(AuthError(msg));
    }
  }

  Future<void> _onRefreshProfile(RefreshProfile event, Emitter<AuthState> emit) async {
    try {
      final profile = await authRepository.getMe();
      emit(_createAuthenticatedState(profile));
    } catch (_) {}
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
