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

  Future<String?> loginByPin(String pinCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tenantId = prefs.getInt('last_tenant_id') ?? 0;
      
      final response = await _dio.post(
        '/auth/pin',
        data: {
          'tenant_id': tenantId,
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
      final data = response.data;
      if (data['tenant_id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_tenant_id', data['tenant_id']);
      }
      return data;
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
