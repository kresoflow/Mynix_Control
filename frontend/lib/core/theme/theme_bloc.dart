import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

enum ThemePalette {
  ember, // Классический Mynix (☀️ Basic / 🌙 Ember)
  cream, // Тёплый крем (☀️ Soft Cream / 🌙 Dark Espresso)
  ocean, // Морской неон (☀️ High Contrast / 🌙 Deep Ocean)
}

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

class SetThemePalette extends ThemeEvent {
  final ThemePalette palette;
  const SetThemePalette(this.palette);
  @override
  List<Object?> get props => [palette];
}

class LoadSavedTheme extends ThemeEvent {}

class ThemeState extends Equatable {
  final ThemeMode mode;
  final ThemePalette palette;

  const ThemeState({
    this.mode = ThemeMode.dark,
    this.palette = ThemePalette.ocean,
  });

  bool isDark(BuildContext context) {
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  ThemeState copyWith({
    ThemeMode? mode,
    ThemePalette? palette,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      palette: palette ?? this.palette,
    );
  }

  @override
  List<Object?> get props => [mode, palette];
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _kThemeModeKey = 'mynix_theme_mode';
  static const _kThemePaletteKey = 'mynix_theme_palette';

  ThemeBloc() : super(const ThemeState(mode: ThemeMode.dark, palette: ThemePalette.ocean)) {
    on<LoadSavedTheme>(_onLoadSavedTheme);
    on<ToggleThemeMode>(_onToggleThemeMode);
    on<SetThemeMode>(_onSetThemeMode);
    on<SetThemePalette>(_onSetThemePalette);

    // Apply default palette
    AppColors.applyPalette(
      palette: state.palette,
      isDark: state.mode != ThemeMode.light,
    );
  }

  Future<void> _onLoadSavedTheme(LoadSavedTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_kThemeModeKey);
      final paletteIndex = prefs.getInt(_kThemePaletteKey);

      ThemeMode mode = state.mode;
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        mode = ThemeMode.values[modeIndex];
      }

      ThemePalette palette = state.palette;
      if (paletteIndex != null && paletteIndex >= 0 && paletteIndex < ThemePalette.values.length) {
        palette = ThemePalette.values[paletteIndex];
      }

      AppColors.applyPalette(
        palette: palette,
        isDark: mode != ThemeMode.light,
      );
      emit(ThemeState(mode: mode, palette: palette));
    } catch (_) {}
  }

  Future<void> _onToggleThemeMode(ToggleThemeMode event, Emitter<ThemeState> emit) async {
    final nextMode = state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppColors.applyPalette(
      palette: state.palette,
      isDark: nextMode != ThemeMode.light,
    );
    emit(state.copyWith(mode: nextMode));
    _saveState(nextMode, state.palette);
  }

  Future<void> _onSetThemeMode(SetThemeMode event, Emitter<ThemeState> emit) async {
    AppColors.applyPalette(
      palette: state.palette,
      isDark: event.mode != ThemeMode.light,
    );
    emit(state.copyWith(mode: event.mode));
    _saveState(event.mode, state.palette);
  }

  Future<void> _onSetThemePalette(SetThemePalette event, Emitter<ThemeState> emit) async {
    AppColors.applyPalette(
      palette: event.palette,
      isDark: state.mode != ThemeMode.light,
    );
    emit(state.copyWith(palette: event.palette));
    _saveState(state.mode, event.palette);
  }

  Future<void> _saveState(ThemeMode mode, ThemePalette palette) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeModeKey, mode.index);
      await prefs.setInt(_kThemePaletteKey, palette.index);
    } catch (_) {}
  }
}
