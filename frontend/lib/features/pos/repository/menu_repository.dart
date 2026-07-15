import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';

class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await _dio.get('/menu/');
      final data = response.data as List;
      
      return data.map((json) {
        String fullName = json['name'] as String;
        final type = json['type'] as String? ?? 'dish';

        if (json['attributes'] != null) {
          final attrs = json['attributes'] as Map<String, dynamic>;
          final iconValue = attrs['icon'];
          if (iconValue != null) {
            fullName = '$fullName|ICON|$iconValue';
          }
          final attrList = attrs.entries
              .where((e) => e.key != 'icon' && e.key != 'variations' && e.key != 'modifier_groups' && e.value != null && e.value.toString().isNotEmpty)
              .map((e) => e.value.toString())
              .join('\n');
          if (attrList.isNotEmpty) {
            fullName = '$fullName|ATTR|$attrList';
          }
        }
        fullName = '$fullName|TYPE|$type';

        return MenuItem(
          id: json['id'] as int,
          name: fullName,
          price: (json['price'] as num).toDouble(),
          categoryId: json['category_id']?.toString() ?? '0',
          categoryName: json['category_name'] as String?,
          shortName: json['short_name'] as String?,
          tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
          attributesJson: json['attributes'] != null ? jsonEncode(json['attributes']) : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load menu: ${e.toString()}');
    }
  }

  Future<void> createMenuItem({
    required String name,
    required double price,
    required String category,
    int sortOrder = 0,
    Map<String, dynamic>? attributes,
  }) async {
    try {
      await _dio.post('/menu/', data: {
        'name': name,
        'price': price,
        'category_id': int.tryParse(category) ?? 0,
        'is_available': true,
        'sort_order': sortOrder,
        'attributes': attributes,
      });
    } catch (e) {
      throw Exception('Failed to create menu item: ${e.toString()}');
    }
  }

  Future<int> createRetailProduct({
    required String name,
    required int categoryId,
    required String unit,
    required double purchasePrice,
    required double sellingPrice,
    Map<String, dynamic>? attributes,
    double initialStock = 0.0,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _dio.post('/retail-product/', data: {
        'name': name,
        'category_id': categoryId,
        'unit': unit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'attributes': attributes,
        'initial_stock': initialStock,
        'sort_order': sortOrder,
      });
      return response.data['id'] as int;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to create retail product');
      }
      throw Exception('Failed to create retail product: ${e.toString()}');
    }
  }

  Future<void> deleteMenuItem(int id) async {
    try {
      await _dio.delete('/menu/$id');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to delete menu item');
      }
      throw Exception('Failed to delete menu item: ${e.toString()}');
    }
  }

  Future<void> updateMenuItem(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/menu/$id', data: data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to update menu item');
      }
      throw Exception('Failed to update menu item: ${e.toString()}');
    }
  }

  Future<void> updateRetailProduct(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/retail-product/$id', data: data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to update retail product');
      }
      throw Exception('Failed to update retail product: ${e.toString()}');
    }
  }
}
