import 'package:dio/dio.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';

part 'parts/categories_part.dart';
part 'parts/ingredients_part.dart';
part 'parts/recipes_part.dart';
part 'parts/documents_part.dart';
part 'parts/suppliers_part.dart';
part 'parts/stock_part.dart';

class InventoryRepository {
  final Dio _dio;

  InventoryRepository(this._dio);
}
