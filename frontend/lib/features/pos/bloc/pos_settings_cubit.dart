import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosSettingsState {
  final bool enableRainbowColors;
  final int cartWidthPercentage; // 20 to 50
  final int columnsCount; // 3 to 6

  const PosSettingsState({
    required this.enableRainbowColors,
    required this.cartWidthPercentage,
    required this.columnsCount,
  });

  /// Совместимость со старым свойством cardSize
  double get cardSize => switch (columnsCount) {
    3 => 270.0,
    4 => 220.0,
    5 => 175.0,
    6 => 145.0,
    _ => 220.0,
  };

  static int cardSizeToColumns(double size) {
    if (size >= 250) return 3;
    if (size >= 200) return 4;
    if (size >= 160) return 5;
    return 6;
  }

  PosSettingsState copyWith({
    bool? enableRainbowColors,
    int? cartWidthPercentage,
    int? columnsCount,
    double? cardSize,
  }) {
    return PosSettingsState(
      enableRainbowColors: enableRainbowColors ?? this.enableRainbowColors,
      cartWidthPercentage: cartWidthPercentage ?? this.cartWidthPercentage,
      columnsCount: columnsCount ?? (cardSize != null ? cardSizeToColumns(cardSize) : this.columnsCount),
    );
  }
}

class PosSettingsCubit extends Cubit<PosSettingsState> {
  static const _kRainbowColorsKey = 'pos_rainbow_colors';
  static const _kCartWidthKey = 'pos_cart_width';
  static const _kColumnsCountKey = 'pos_columns_count';
  static const _kCardSizeKey = 'pos_card_size';

  PosSettingsCubit() : super(const PosSettingsState(
    enableRainbowColors: true,
    cartWidthPercentage: 30, // Default 30%
    columnsCount: 4, // Default 4 колонки
  ),) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kRainbowColorsKey) ?? true;
      final cartWidth = prefs.getInt(_kCartWidthKey) ?? 30;
      
      int columns = prefs.getInt(_kColumnsCountKey) ?? 0;
      if (columns < 3 || columns > 6) {
        final oldCardSize = prefs.getDouble(_kCardSizeKey);
        if (oldCardSize != null) {
          columns = PosSettingsState.cardSizeToColumns(oldCardSize);
        } else {
          columns = 4;
        }
      }
      
      emit(PosSettingsState(
        enableRainbowColors: enabled,
        cartWidthPercentage: cartWidth,
        columnsCount: columns,
      ),);
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

  Future<void> updateColumnsCount(int count) async {
    if (count < 3 || count > 6) return;
    emit(state.copyWith(columnsCount: count));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kColumnsCountKey, count);
    } catch (_) {}
  }

  Future<void> updateCardSize(double size) async {
    final count = PosSettingsState.cardSizeToColumns(size);
    await updateColumnsCount(count);
  }
}
