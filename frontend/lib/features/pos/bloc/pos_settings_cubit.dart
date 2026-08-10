import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosSettingsState {
  final bool enableRainbowColors;
  final int cartWidthPercentage; // 20 to 50
  final double cardSize; // 150.0 to 300.0

  const PosSettingsState({
    required this.enableRainbowColors,
    required this.cartWidthPercentage,
    required this.cardSize,
  });

  PosSettingsState copyWith({
    bool? enableRainbowColors,
    int? cartWidthPercentage,
    double? cardSize,
  }) {
    return PosSettingsState(
      enableRainbowColors: enableRainbowColors ?? this.enableRainbowColors,
      cartWidthPercentage: cartWidthPercentage ?? this.cartWidthPercentage,
      cardSize: cardSize ?? this.cardSize,
    );
  }
}

class PosSettingsCubit extends Cubit<PosSettingsState> {
  static const _kRainbowColorsKey = 'pos_rainbow_colors';
  static const _kCartWidthKey = 'pos_cart_width';
  static const _kCardSizeKey = 'pos_card_size';

  PosSettingsCubit() : super(const PosSettingsState(
    enableRainbowColors: true,
    cartWidthPercentage: 30, // Default 30%
    cardSize: 220.0, // Default 220px
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kRainbowColorsKey) ?? true;
      final cartWidth = prefs.getInt(_kCartWidthKey) ?? 30;
      final cardSize = prefs.getDouble(_kCardSizeKey) ?? 220.0;
      
      emit(PosSettingsState(
        enableRainbowColors: enabled,
        cartWidthPercentage: cartWidth,
        cardSize: cardSize,
      ));
    } catch (_) {}
  }

  Future<void> toggleRainbowColors() async {
    final newState = !state.enableRainbowColors;
    emit(state.copyWith(enableRainbowColors: newState));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRainbowColorsKey, newState);
    } catch (_) {}
  }

  Future<void> updateCartWidth(int percentage) async {
    if (percentage < 20 || percentage > 50) return;
    emit(state.copyWith(cartWidthPercentage: percentage));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCartWidthKey, percentage);
    } catch (_) {}
  }

  Future<void> updateCardSize(double size) async {
    if (size < 120.0 || size > 350.0) return;
    emit(state.copyWith(cardSize: size));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kCardSizeKey, size);
    } catch (_) {}
  }
}
