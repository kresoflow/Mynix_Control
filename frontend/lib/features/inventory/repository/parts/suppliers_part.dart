part of '../inventory_repository.dart';

extension SuppliersPart on InventoryRepository {
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _dio.get('/suppliers/');
      final data = response.data as List;
      return data.map((json) => Supplier.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load suppliers: ${e.toString()}');
    }
  }

  Future<Supplier> createSupplier(String name, {String? contactInfo, double? initialBalance}) async {
    try {
      final response = await _dio.post(
        '/suppliers/',
        data: {
          'name': name,
          'contact_info': contactInfo,
          if (initialBalance != null) 'initial_balance': initialBalance,
        },
      );
      return Supplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create supplier: ${e.toString()}');
    }
  }

  Future<void> updateSupplier(int id, {String? name, String? contactInfo, bool? isActive}) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (contactInfo != null) data['contact_info'] = contactInfo;
      if (isActive != null) data['is_active'] = isActive;
      await _dio.put('/suppliers/$id', data: data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to update supplier');
      }
      throw Exception('Failed to update supplier: ${e.toString()}');
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _dio.delete('/suppliers/$id');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to delete supplier');
      }
      throw Exception('Failed to delete supplier: ${e.toString()}');
    }
  }

  // --- Transactions & Ledger ---

  Future<List<SupplierTransaction>> getSupplierTransactions(int supplierId) async {
    try {
      final response = await _dio.get('/suppliers/$supplierId/transactions');
      final data = response.data as List;
      return data.map((json) => SupplierTransaction.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to load supplier transactions');
      }
      throw Exception('Failed to load supplier transactions: ${e.toString()}');
    }
  }

  Future<SupplierTransaction> createSupplierTransaction(
    int supplierId, {
    required SupplierTransactionType type,
    required double amount,
    String paymentMethod = 'cash',
    String? comment,
    DateTime? date,
  }) async {
    try {
      final response = await _dio.post(
        '/suppliers/$supplierId/transactions',
        data: {
          'type': type.toApiString(),
          'amount': amount,
          'payment_method': paymentMethod,
          'comment': comment,
          if (date != null) 'date': date.toIso8601String(),
        },
      );
      return SupplierTransaction.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to record transaction');
      }
      throw Exception('Failed to record transaction: ${e.toString()}');
    }
  }

  Future<SupplierTransaction> updateSupplierTransaction(
    int supplierId,
    int transactionId, {
    double? amount,
    String? paymentMethod,
    String? comment,
    DateTime? date,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (amount != null) data['amount'] = amount;
      if (paymentMethod != null) data['payment_method'] = paymentMethod;
      if (comment != null) data['comment'] = comment;
      if (date != null) data['date'] = date.toIso8601String();

      final response = await _dio.put(
        '/suppliers/$supplierId/transactions/$transactionId',
        data: data,
      );
      return SupplierTransaction.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to update transaction');
      }
      throw Exception('Failed to update transaction: ${e.toString()}');
    }
  }

  Future<void> deleteSupplierTransaction(int supplierId, int transactionId) async {
    try {
      await _dio.delete('/suppliers/$supplierId/transactions/$transactionId');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to delete transaction');
      }
      throw Exception('Failed to delete transaction: ${e.toString()}');
    }
  }

  Future<void> recordSupplierPayment(
    int supplierId, {
    required double amount,
    String paymentMethod = 'cash',
    String? comment,
  }) async {
    await createSupplierTransaction(
      supplierId,
      type: SupplierTransactionType.payment,
      amount: amount,
      paymentMethod: paymentMethod,
      comment: comment,
    );
  }
}
