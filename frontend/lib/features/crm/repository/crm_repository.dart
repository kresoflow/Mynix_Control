import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';
import 'package:mynix_frontend/features/crm/models/bonus_transaction.dart';

class CrmRepository {
  final Dio _dio;

  CrmRepository(this._dio);

  Future<List<Customer>> getCustomers({String? query, String? filterType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (filterType != null && filterType != 'all') {
        queryParams['filter_type'] = filterType;
      }

      final response = await _dio.get('/crm/customers/', queryParameters: queryParams);
      final List data = response.data;
      return data.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Не удалось загрузить клиентов: $e');
    }
  }

  Future<Customer> getCustomer(int id) async {
    try {
      final response = await _dio.get('/crm/customers/$id');
      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception('Не удалось загрузить данные клиента: $e');
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/crm/customers/', data: data);
      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception('Не удалось создать клиента: $e');
    }
  }

  Future<Customer> updateCustomer(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/crm/customers/$id', data: data);
      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception('Не удалось обновить клиента: $e');
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _dio.delete('/crm/customers/$id');
    } catch (e) {
      throw Exception('Не удалось удалить клиента: $e');
    }
  }

  Future<List<CustomerTransaction>> getCustomerTransactions(int customerId) async {
    try {
      final response = await _dio.get('/crm/customers/$customerId/transactions');
      final List data = response.data;
      return data.map((json) => CustomerTransaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Не удалось загрузить проводки клиента: $e');
    }
  }

  Future<CustomerTransaction> createCustomerTransaction(
    int customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/crm/customers/$customerId/transactions', data: data);
      return CustomerTransaction.fromJson(response.data);
    } catch (e) {
      throw Exception('Не удалось провести операцию: $e');
    }
  }

  Future<List<BonusTransaction>> getBonusTransactions(int customerId) async {
    try {
      final response = await _dio.get('/crm/customers/$customerId/bonus-transactions');
      final List data = response.data;
      return data.map((json) => BonusTransaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Не удалось загрузить историю бонусов: $e');
    }
  }

  Future<BonusTransaction> createBonusTransaction(
    int customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/crm/customers/$customerId/bonus-transactions', data: data);
      return BonusTransaction.fromJson(response.data);
    } catch (e) {
      throw Exception('Не удалось провести бонусную операцию: $e');
    }
  }
}
