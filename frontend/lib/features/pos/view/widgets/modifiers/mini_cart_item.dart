class MiniCartItem {
  final String variationName;
  final List<String> modifierNames;
  final String jsonStr;
  final double price;
  int quantity;

  MiniCartItem({
    required this.variationName,
    required this.modifierNames,
    required this.jsonStr,
    required this.price,
    this.quantity = 1,
  });
}
