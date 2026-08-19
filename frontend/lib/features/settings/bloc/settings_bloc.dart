import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:mynix_frontend/core/theme/app_colors.dart';

// --- Events ---
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
  const UpdateFeatureFlags({required this.useKds, required this.useOrders});

  @override
  List<Object?> get props => [useKds, useOrders];
}

class ToggleShowKdsInNav extends SettingsEvent {
  final bool show;
  const ToggleShowKdsInNav(this.show);

  @override
  List<Object?> get props => [show];
}

// --- States ---
class SettingsState extends Equatable {
  final String currency;
  final String themeVariant;
  final bool useKds;
  final bool useOrders;
  final bool showKdsInNav;

  const SettingsState({
    this.currency = 'с',
    this.themeVariant = 'basic',
    this.useKds = true,
    this.useOrders = true,
    this.showKdsInNav = true,
  });

  SettingsState copyWith({
    String? currency,
    String? themeVariant,
    bool? useKds,
    bool? useOrders,
    bool? showKdsInNav,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      themeVariant: themeVariant ?? this.themeVariant,
      useKds: useKds ?? this.useKds,
      useOrders: useOrders ?? this.useOrders,
      showKdsInNav: showKdsInNav ?? this.showKdsInNav,
    );
  }

  @override
  List<Object?> get props => [currency, themeVariant, useKds, useOrders, showKdsInNav];
}

// --- Bloc ---
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

    on<ToggleShowKdsInNav>((event, emit) {
      emit(state.copyWith(showKdsInNav: event.show));
    });
  }
}
