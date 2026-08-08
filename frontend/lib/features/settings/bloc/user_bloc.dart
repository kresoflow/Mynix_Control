import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/settings/models/user_model.dart';
import 'package:mynix_frontend/features/settings/repository/user_repository.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserEvent {}

class CreateUser extends UserEvent {
  final String username;
  final String fullName;
  final String password;
  final String? pinCode;
  final List<int> roleIds;

  const CreateUser({
    required this.username,
    required this.fullName,
    required this.password,
    this.pinCode,
    required this.roleIds,
  });

  @override
  List<Object?> get props => [username, fullName, password, pinCode, roleIds];
}

class UpdateUser extends UserEvent {
  final int userId;
  final String? username;
  final String? fullName;
  final String? password;
  final String? pinCode;
  final List<int>? roleIds;

  const UpdateUser({
    required this.userId,
    this.username,
    this.fullName,
    this.password,
    this.pinCode,
    this.roleIds,
  });

  @override
  List<Object?> get props => [userId, username, fullName, password, pinCode, roleIds];
}

class DeleteUser extends UserEvent {
  final int userId;

  const DeleteUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UserState extends Equatable {
  final List<StaffUser> users;
  final List<Role> roles;
  final bool isLoading;
  final String? error;

  const UserState({
    this.users = const [],
    this.roles = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    List<StaffUser>? users,
    List<Role>? roles,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [users, roles, isLoading, error];
}

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;

  UserBloc({required this.repository}) : super(const UserState()) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final users = await repository.getUsers();
      final roles = await repository.getRoles();
      emit(state.copyWith(users: users, roles: roles, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await repository.createUser(
        username: event.username,
        fullName: event.fullName,
        password: event.password,
        pinCode: event.pinCode,
        roleIds: event.roleIds,
      );
      final users = await repository.getUsers();
      emit(state.copyWith(users: users, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await repository.updateUser(
        event.userId,
        username: event.username,
        fullName: event.fullName,
        password: event.password,
        pinCode: event.pinCode,
        roleIds: event.roleIds,
      );
      final users = await repository.getUsers();
      emit(state.copyWith(users: users, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await repository.deleteUser(event.userId);
      final users = await repository.getUsers();
      emit(state.copyWith(users: users, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
