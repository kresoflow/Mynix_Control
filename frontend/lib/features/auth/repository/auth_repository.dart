import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      
      final token = response.data['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        return token;
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<String?> loginByPin(String tenantId, String pinCode) async {
    try {
      final response = await _dio.post(
        '/auth/pin',
        data: {
          'tenant_id': int.tryParse(tenantId) ?? 0,
          'pin_code': pinCode,
        },
      );
      
      final token = response.data['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        return token;
      }
      return null;
    } catch (e) {
      throw Exception('PIN Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }
}
