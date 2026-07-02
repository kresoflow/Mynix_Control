import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class ReceiptRowData {
  Ingredient? ingredient;
  String newName;
  double quantity;
  double price;
  String selectedUnit;
  
  final TextEditingController nameController;
  final TextEditingController flavorController;
  final TextEditingController volumeController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  
  final FocusNode nameFocusNode;
  final FocusNode flavorFocusNode;
  final FocusNode volumeFocusNode;
  final FocusNode qtyFocusNode;
  final FocusNode priceFocusNode;

  ReceiptRowData({
    this.ingredient,
    this.newName = '',
    this.quantity = 1.0,
    this.price = 0.0,
    this.selectedUnit = 'шт',
  })  : nameController = TextEditingController(text: newName),
        flavorController = TextEditingController(),
        volumeController = TextEditingController(),
        qtyController = TextEditingController(text: quantity.toString()),
        priceController = TextEditingController(text: price.toString()),
        nameFocusNode = FocusNode(),
        flavorFocusNode = FocusNode(),
        volumeFocusNode = FocusNode(),
        qtyFocusNode = FocusNode(),
        priceFocusNode = FocusNode();

  void dispose() {
    nameController.dispose();
    flavorController.dispose();
    volumeController.dispose();
    qtyController.dispose();
    priceController.dispose();
    nameFocusNode.dispose();
    flavorFocusNode.dispose();
    volumeFocusNode.dispose();
    qtyFocusNode.dispose();
    priceFocusNode.dispose();
  }
}