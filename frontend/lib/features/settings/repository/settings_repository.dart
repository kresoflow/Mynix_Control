// ==============================================================================
// МОДУЛЬ: Настройки / Репозиторий взаимодействия с API настроек (SettingsRepository)
// ДОМЕН: lib/features/settings/repository/settings_repository.dart
// ==============================================================================

import 'package:dio/dio.dart';

// ─── 1. Репозиторий сетевого взаимодействия с настройками ─────────────────────

/// [ИНВАРИАНТ] Сетевой репозиторий для чтения и сохранения конфигурационных
/// параметров торговой точки / заведения в рамках схемы тенанта.
class SettingsRepository {
  final Dio _dio;

  /// Создает экземпляр репозитория с настроенным Dio-клиентом
  SettingsRepository(this._dio);

  /// Получает актуальный словарь параметров заведения с бэкенда.
  ///
  /// Эндпоинт: `GET /settings/`
  /// Возвращает конфигурацию фиче-флагов, интеграций кухни (KDS),
  /// списания ингредиентов и параметров кассы.
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/settings/');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    } on DioException catch (dioErr) {
      throw Exception(
        'Ошибка сети при загрузке настроек: ${dioErr.message ?? dioErr.toString()}',
      );
    } catch (e) {
      throw Exception('Непредвиденная ошибка при загрузке настроек: $e');
    }
  }

  /// Обновляет конфигурационные параметры заведения на бэкенде.
  ///
  /// Эндпоинт: `PUT /settings/`
  /// [data] содержит обновленные поля, например:
  /// `{'use_kds': bool, 'use_orders': bool, 'enable_inventory_deduction': bool}`
  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      await _dio.put('/settings/', data: data);
    } on DioException catch (dioErr) {
      throw Exception(
        'Ошибка сети при сохранении настроек: ${dioErr.message ?? dioErr.toString()}',
      );
    } catch (e) {
      throw Exception('Непредвиденная ошибка при сохранении настроек: $e');
    }
  }
}
