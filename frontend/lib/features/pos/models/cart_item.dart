import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'menu_item.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 1)
class CartItem extends Equatable {
  @HiveField(0)
  final String id; // Unique ID for this cart item entry (could be UUID)

  @HiveField(1)
  final MenuItem menuItem;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final String? selectedOptionsJson;

  @HiveField(4)
  final double selectedOptionsPrice;

  const CartItem({
    required this.id,
    required this.menuItem,
    this.quantity = 1,
    this.selectedOptionsJson,
    this.selectedOptionsPrice = 0.0,
  });

  double get total => (menuItem.price + selectedOptionsPrice) * quantity;

  CartItem copyWith({
    String? id,
    MenuItem? menuItem,
    int? quantity,
    String? selectedOptionsJson,
    double? selectedOptionsPrice,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      selectedOptionsJson: selectedOptionsJson ?? this.selectedOptionsJson,
      selectedOptionsPrice: selectedOptionsPrice ?? this.selectedOptionsPrice,
    );
  }

  @override
  List<Object?> get props => [id, menuItem, quantity, selectedOptionsJson, selectedOptionsPrice];
}
