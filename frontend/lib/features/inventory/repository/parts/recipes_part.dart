part of '../inventory_repository.dart';

extension RecipesPart on InventoryRepository {
  Future<List<Map<String, dynamic>>> getRecipe(int menuItemId) async {
    try {
      final response = await _dio.get('/menu/$menuItemId/recipe');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load recipe: ${e.toString()}');
    }
  }

  Future<void> addIngredientToRecipe(
    int menuItemId,
    int ingredientId,
    double quantity,
  ) async {
    try {
      await _dio.post(
        '/menu/$menuItemId/recipe',
        data: {'ingredient_id': ingredientId, 'quantity_required': quantity},
      );
    } catch (e) {
      throw Exception('Failed to add ingredient to recipe: ${e.toString()}');
    }
  }

  Future<void> bulkUpdateRecipe(int menuItemId, List<Map<String, dynamic>> recipes) async {
    try {
      await _dio.put(
        '/menu/$menuItemId/recipe',
        data: {'recipes': recipes},
      );
    } catch (e) {
      throw Exception('Failed to bulk update recipe: ${e.toString()}');
    }
  }

  Future<void> removeIngredientFromRecipe(
    int menuItemId,
    int ingredientId,
  ) async {
    try {
      await _dio.delete('/menu/$menuItemId/recipe/$ingredientId');
    } catch (e) {
      throw Exception(
        'Failed to remove ingredient from recipe: ${e.toString()}',
      );
    }
  }

  Future<void> receiveStock(
    int ingredientId,
    double quantity,
    String reason, {
    bool isRetail = false,
  }) async {
    try {
      if (isRetail) {
        await _dio.post(
          '/inventory/retail/receive',
          data: {
            'retail_product_id': ingredientId,
            'quantity': quantity,
            'reason': reason,
          },
        );
      } else {
        await _dio.post(
          '/ingredients/receive',
          data: {
            'ingredient_id': ingredientId,
            'quantity': quantity,
            'reason': reason,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to receive stock: ${e.toString()}');
    }
  }
}
