import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:retail_os_frontend/core/theme/app_colors.dart';

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

// --- States ---
class SettingsState extends Equatable {
  final String currency;
  final String themeVariant;

  const SettingsState({
    this.currency = 'с',
    this.themeVariant = 'basic',
  });

  SettingsState copyWith({
    String? currency,
    String? themeVariant,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      themeVariant: themeVariant ?? this.themeVariant,
    );
  }

  @override
  List<Object?> get props => [currency, themeVariant];
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
  }
}
