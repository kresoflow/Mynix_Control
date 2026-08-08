import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosSettingsState {
  final bool enableRainbowColors;
  const PosSettingsState({required this.enableRainbowColors});
}

class PosSettingsCubit extends Cubit<PosSettingsState> {
  static const _kRainbowColorsKey = 'pos_rainbow_colors';

  PosSettingsCubit() : super(const PosSettingsState(enableRainbowColors: true)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kRainbowColorsKey) ?? true;
      emit(PosSettingsState(enableRainbowColors: enabled));
    } catch (_) {}
  }

  Future<void> toggleRainbowColors() async {
    final newState = !state.enableRainbowColors;
    emit(PosSettingsState(enableRainbowColors: newState));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRainbowColorsKey, newState);
    } catch (_) {}
  }
}
