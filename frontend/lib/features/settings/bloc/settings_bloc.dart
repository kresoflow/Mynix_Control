// ==============================================================================
// МОДУЛЬ: Настройки / Управление глобальными параметрами приложения (SettingsBloc)
// ДОМЕН: lib/features/settings/bloc/settings_bloc.dart
// ==============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';

// ── События настроек ─────────────────────────────────────────────────────────

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class UpdateCurrency extends SettingsEvent {
  final String currency;
  const UpdateCurrency(this.currency);

  @override
  List<Object?> get props => [currency];
}

class UpdateThemeVariant extends SettingsEvent {
  final String themeVariant;
  const UpdateThemeVariant(this.themeVariant);

  @override
  List<Object?> get props => [themeVariant];
}

class UpdateFeatureFlags extends SettingsEvent {
  final bool useKds;
  final bool useOrders;
  const UpdateFeatureFlags({this.useKds = false, required this.useOrders});

  @override
  List<Object?> get props => [useKds, useOrders];
}

// ── Состояние настроек ───────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final String currency;
  final String themeVariant;
  final bool useKds;
  final bool useOrders;

  const SettingsState({
    this.currency = 'с',
    this.themeVariant = 'basic',
    this.useKds = false,
    this.useOrders = true,
  });

  SettingsState copyWith({
    String? currency,
    String? themeVariant,
    bool? useKds,
    bool? useOrders,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      themeVariant: themeVariant ?? this.themeVariant,
      useKds: useKds ?? this.useKds,
      useOrders: useOrders ?? this.useOrders,
    );
  }

  @override
  List<Object?> get props => [currency, themeVariant, useKds, useOrders];
}

// ── BLoC настроек ───────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<UpdateCurrency>((event, emit) {
      emit(state.copyWith(currency: event.currency));
    });

    on<UpdateThemeVariant>((event, emit) {
      AppColors.applyThemeVariant(event.themeVariant);
      emit(state.copyWith(themeVariant: event.themeVariant));
    });

    on<UpdateFeatureFlags>((event, emit) {
      emit(state.copyWith(useKds: event.useKds, useOrders: event.useOrders));
    });
  }
}
