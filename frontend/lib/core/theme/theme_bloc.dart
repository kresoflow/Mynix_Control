import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object?> get props => [];
}

class ToggleThemeMode extends ThemeEvent {}

class SetThemeMode extends ThemeEvent {
  final ThemeMode mode;
  const SetThemeMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

class SetThemeVariant extends ThemeEvent {
  final String variant;
  const SetThemeVariant(this.variant);
  @override
  List<Object?> get props => [variant];
}

class SelectTheme extends ThemeEvent {
  final ThemeMode mode;
  final String variant;
  const SelectTheme({required this.mode, required this.variant});
  @override
  List<Object?> get props => [mode, variant];
}

class LoadSavedTheme extends ThemeEvent {}

class ThemeState extends Equatable {
  final ThemeMode mode;
  final String variant;

  const ThemeState({
    this.mode = ThemeMode.dark,
    this.variant = 'deep_ocean',
  });

  bool isDark(BuildContext context) {
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  ThemeState copyWith({
    ThemeMode? mode,
    String? variant,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
    );
  }

  @override
  List<Object?> get props => [mode, variant];
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _kThemeModeKey = 'mynix_theme_mode';
  static const _kThemeVariantKey = 'mynix_theme_variant';

  ThemeBloc() : super(const ThemeState(mode: ThemeMode.dark, variant: 'deep_ocean')) {
    on<LoadSavedTheme>(_onLoadSavedTheme);
    on<ToggleThemeMode>(_onToggleThemeMode);
    on<SetThemeMode>(_onSetThemeMode);
    on<SetThemeVariant>(_onSetThemeVariant);
    on<SelectTheme>(_onSelectTheme);

    // Apply initial variant
    AppColors.applyThemeVariant(state.variant);
  }

  Future<void> _onLoadSavedTheme(LoadSavedTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_kThemeModeKey);
      final savedVariant = prefs.getString(_kThemeVariantKey);

      ThemeMode mode = state.mode;
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        mode = ThemeMode.values[modeIndex];
      }

      String variant = savedVariant ?? state.variant;
      AppColors.applyThemeVariant(variant);
      emit(ThemeState(mode: mode, variant: variant));
    } catch (_) {}
  }

  Future<void> _onToggleThemeMode(ToggleThemeMode event, Emitter<ThemeState> emit) async {
    ThemeMode nextMode;
    String nextVariant = state.variant;

    if (state.mode == ThemeMode.dark) {
      nextMode = ThemeMode.light;
      if (state.variant == 'deep_ocean') {
        nextVariant = 'high_contrast_light';
      }
    } else {
      nextMode = ThemeMode.dark;
      if (state.variant == 'high_contrast_light') {
        nextVariant = 'deep_ocean';
      }
    }

    AppColors.applyThemeVariant(nextVariant);
    emit(state.copyWith(mode: nextMode, variant: nextVariant));
    _saveState(nextMode, nextVariant);
  }

  Future<void> _onSetThemeMode(SetThemeMode event, Emitter<ThemeState> emit) async {
    emit(state.copyWith(mode: event.mode));
    _saveState(event.mode, state.variant);
  }

  Future<void> _onSetThemeVariant(SetThemeVariant event, Emitter<ThemeState> emit) async {
    AppColors.applyThemeVariant(event.variant);
    emit(state.copyWith(variant: event.variant));
    _saveState(state.mode, event.variant);
  }

  Future<void> _onSelectTheme(SelectTheme event, Emitter<ThemeState> emit) async {
    AppColors.applyThemeVariant(event.variant);
    emit(ThemeState(mode: event.mode, variant: event.variant));
    _saveState(event.mode, event.variant);
  }

  Future<void> _saveState(ThemeMode mode, String variant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeModeKey, mode.index);
      await prefs.setString(_kThemeVariantKey, variant);
    } catch (_) {}
  }
}
