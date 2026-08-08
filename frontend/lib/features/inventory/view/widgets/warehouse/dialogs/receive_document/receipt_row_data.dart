import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class ReceiptRowData {
  Ingredient? ingredient;
  String newName;
  double quantity;
  double price;
  double sellPrice;
  double minStockAlert;
  String selectedUnit;
  
  final TextEditingController nameController;
  final TextEditingController flavorController;
  final TextEditingController volumeController;
  final TextEditingController qtyController;
  final TextEditingController minStockAlertController;
  final TextEditingController priceController;
  final TextEditingController sellPriceController;
  
  final FocusNode nameFocusNode;
  final FocusNode flavorFocusNode;
  final FocusNode volumeFocusNode;
  final FocusNode qtyFocusNode;
  final FocusNode minStockAlertFocusNode;
  final FocusNode priceFocusNode;
  final FocusNode sellPriceFocusNode;

  ReceiptRowData({
    this.ingredient,
    this.newName = '',
    this.quantity = 1.0,
    this.price = 0.0,
    this.sellPrice = 0.0,
    this.minStockAlert = 0.0,
    this.selectedUnit = 'шт',
  })  : nameController = TextEditingController(text: newName),
        flavorController = TextEditingController(),
        volumeController = TextEditingController(),
        qtyController = TextEditingController(text: quantity.toString()),
        minStockAlertController = TextEditingController(text: minStockAlert.toString()),
        priceController = TextEditingController(text: price.toString()),
        sellPriceController = TextEditingController(text: sellPrice.toString()),
        nameFocusNode = FocusNode(),
        flavorFocusNode = FocusNode(),
        volumeFocusNode = FocusNode(),
        qtyFocusNode = FocusNode(),
        minStockAlertFocusNode = FocusNode(),
        priceFocusNode = FocusNode(),
        sellPriceFocusNode = FocusNode();

  void dispose() {
    nameController.dispose();
    flavorController.dispose();
    volumeController.dispose();
    qtyController.dispose();
    minStockAlertController.dispose();
    priceController.dispose();
    sellPriceController.dispose();
    nameFocusNode.dispose();
    flavorFocusNode.dispose();
    volumeFocusNode.dispose();
    qtyFocusNode.dispose();
    minStockAlertFocusNode.dispose();
    priceFocusNode.dispose();
    sellPriceFocusNode.dispose();
  }
}