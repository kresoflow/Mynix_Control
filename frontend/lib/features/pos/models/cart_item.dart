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

  const CartItem({
    required this.id,
    required this.menuItem,
    this.quantity = 1,
  });

  double get total => menuItem.price * quantity;

  CartItem copyWith({
    String? id,
    MenuItem? menuItem,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [id, menuItem, quantity];
}
