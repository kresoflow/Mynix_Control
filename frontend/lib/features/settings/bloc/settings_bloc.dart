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

/// Загрузка настроек с бэкенда через SettingsRepository
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Обновление валюты
class UpdateCurrency extends SettingsEvent {
  final String currency;
  const UpdateCurrency(this.currency);

  @override
  List<Object?> get props => [currency];
}

/// Обновление цветового варианта
class UpdateThemeVariant extends SettingsEvent {
  final String themeVariant;
  const UpdateThemeVariant(this.themeVariant);

  @override
  List<Object?> get props => [themeVariant];
}

/// Обновление флагов кассы/кухни
class UpdateFeatureFlags extends SettingsEvent {
  final bool useKds;
  final bool useOrders;
  const UpdateFeatureFlags({this.useKds = false, required this.useOrders});

  @override
  List<Object?> get props => [useKds, useOrders];
}

/// Обновление бизнес-параметров заведения
class UpdateStoreSettings extends SettingsEvent {
  final bool? useOrders;
  final bool? enableInventory;
  final String? timezone;
  final bool? soundEnabled;
  final bool? blindPosEnabled;

  const UpdateStoreSettings({
    this.useOrders,
    this.enableInventory,
    this.timezone,
    this.soundEnabled,
    this.blindPosEnabled,
  });

  @override
  List<Object?> get props => [useOrders, enableInventory, timezone, soundEnabled, blindPosEnabled];
}

/// Смена мастер-PIN кода кассы заведения
class ChangeMasterPin extends SettingsEvent {
  final String newPin;
  const ChangeMasterPin(this.newPin);

  @override
  List<Object?> get props => [newPin];
}

// ── Состояние настроек ───────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final bool isLoading;
  final String currency;
  final String themeVariant;
  final bool useKds;
  final bool useOrders;
  final bool enableInventory;
  final String timezone;
  final bool soundEnabled;
  final bool blindPosEnabled;
  final bool posMasterPinSet;
  final String? error;

  const SettingsState({
    this.isLoading = false,
    this.currency = 'с',
    this.themeVariant = 'basic',
    this.useKds = false,
    this.useOrders = true,
    this.enableInventory = true,
    this.timezone = 'GMT+3 (Москва)',
    this.soundEnabled = true,
    this.blindPosEnabled = true,
    this.posMasterPinSet = true,
    this.error,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? currency,
    String? themeVariant,
    bool? useKds,
    bool? useOrders,
    bool? enableInventory,
    String? timezone,
    bool? soundEnabled,
    bool? blindPosEnabled,
    bool? posMasterPinSet,
    String? error,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      currency: currency ?? this.currency,
      themeVariant: themeVariant ?? this.themeVariant,
      useKds: useKds ?? this.useKds,
      useOrders: useOrders ?? this.useOrders,
      enableInventory: enableInventory ?? this.enableInventory,
      timezone: timezone ?? this.timezone,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      blindPosEnabled: blindPosEnabled ?? this.blindPosEnabled,
      posMasterPinSet: posMasterPinSet ?? this.posMasterPinSet,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        currency,
        themeVariant,
        useKds,
        useOrders,
        enableInventory,
        timezone,
        soundEnabled,
        blindPosEnabled,
        posMasterPinSet,
        error,
      ];
}

// ── BLoC настроек ───────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final dynamic _repository;

  SettingsBloc({dynamic settingsRepository})
      : _repository = settingsRepository,
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateStoreSettings>(_onUpdateStoreSettings);
    on<ChangeMasterPin>(_onChangeMasterPin);
    on<UpdateCurrency>(_onUpdateCurrency);
    on<UpdateThemeVariant>(_onUpdateThemeVariant);
    on<UpdateFeatureFlags>(_onUpdateFeatureFlags);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (_repository == null) return;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repository.getSettings();
      emit(state.copyWith(
        isLoading: false,
        useOrders: data['use_orders'] ?? state.useOrders,
        enableInventory: data['enable_inventory_deduction'] ?? state.enableInventory,
        blindPosEnabled: data['blind_pos_enabled'] ?? state.blindPosEnabled,
        posMasterPinSet: data['pos_master_pin_set'] ?? state.posMasterPinSet,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateStoreSettings(
    UpdateStoreSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final newUseOrders = event.useOrders ?? state.useOrders;
    final newEnableInventory = event.enableInventory ?? state.enableInventory;
    final newTimezone = event.timezone ?? state.timezone;
    final newSoundEnabled = event.soundEnabled ?? state.soundEnabled;
    final newBlindPos = event.blindPosEnabled ?? state.blindPosEnabled;

    emit(state.copyWith(
      useOrders: newUseOrders,
      enableInventory: newEnableInventory,
      timezone: newTimezone,
      soundEnabled: newSoundEnabled,
      blindPosEnabled: newBlindPos,
    ));

    if (_repository != null) {
      try {
        await _repository.updateSettings({
          'use_kds': state.useKds,
          'use_orders': newUseOrders,
          'enable_inventory_deduction': newEnableInventory,
          'blind_pos_enabled': newBlindPos,
        });
      } catch (e) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> _onChangeMasterPin(
    ChangeMasterPin event,
    Emitter<SettingsState> emit,
  ) async {
    if (_repository == null) return;
    try {
      await _repository.updateSettings({
        'use_kds': state.useKds,
        'use_orders': state.useOrders,
        'enable_inventory_deduction': state.enableInventory,
        'blind_pos_enabled': state.blindPosEnabled,
        'pos_master_pin': event.newPin,
      });
      emit(state.copyWith(posMasterPinSet: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  void _onUpdateCurrency(
    UpdateCurrency event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(currency: event.currency));
  }

  void _onUpdateThemeVariant(
    UpdateThemeVariant event,
    Emitter<SettingsState> emit,
  ) {
    AppColors.applyThemeVariant(event.themeVariant);
    emit(state.copyWith(themeVariant: event.themeVariant));
  }

  void _onUpdateFeatureFlags(
    UpdateFeatureFlags event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(useKds: event.useKds, useOrders: event.useOrders));
  }
}
