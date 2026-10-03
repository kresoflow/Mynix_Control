// ==============================================================================
// МОДУЛЬ: POS / Меню — Состояния BLoC каталога и меню
// ДОМЕН: lib/features/pos/bloc/menu_state.dart
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';

abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object?> get props => [];
}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItem> items;
  const MenuLoaded({required this.items});
  @override
  List<Object?> get props => [items];
}

class MenuError extends MenuState {
  final String message;
  const MenuError({required this.message});
  @override
  List<Object?> get props => [message];
}
