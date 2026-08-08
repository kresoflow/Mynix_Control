import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/settings/models/user_model.dart';

class UserRepository {
  Future<List<StaffUser>> getUsers() async {
    final response = await apiClient.dio.get('/users/');
    return (response.data as List).map((e) => StaffUser.fromJson(e)).toList();
  }

  Future<List<Role>> getRoles() async {
    final response = await apiClient.dio.get('/roles/');
    return (response.data as List).map((e) => Role.fromJson(e)).toList();
  }

  Future<StaffUser> createUser({
    required String username,
    required String fullName,
    required String password,
    String? pinCode,
    required List<int> roleIds,
  }) async {
    final response = await apiClient.dio.post('/users/', data: {
      'username': username,
      'full_name': fullName,
      'password': password,
      'pin_code': pinCode,
      'tenant_id': 0, // Backend sets this to current user's tenant_id automatically
      'role_ids': roleIds,
    });
    return StaffUser.fromJson(response.data);
  }

  Future<StaffUser> updateUser(
    int userId, {
    String? username,
    String? fullName,
    String? password,
    String? pinCode,
    List<int>? roleIds,
  }) async {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (fullName != null) data['full_name'] = fullName;
    if (password != null && password.isNotEmpty) data['password'] = password;
    if (pinCode != null && pinCode.isNotEmpty) data['pin_code'] = pinCode;
    if (roleIds != null) data['role_ids'] = roleIds;

    final response = await apiClient.dio.put('/users/$userId', data: data);
    return StaffUser.fromJson(response.data);
  }

  Future<void> deleteUser(int userId) async {
    await apiClient.dio.delete('/users/$userId');
  }
}
