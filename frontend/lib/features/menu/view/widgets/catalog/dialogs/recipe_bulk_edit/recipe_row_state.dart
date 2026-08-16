import 'package:flutter/material.dart';

class RecipeRowState {
  int? ingredientId;
  TextEditingController quantityController;
  final FocusNode ingredientFocusNode = FocusNode();

  RecipeRowState({this.ingredientId, double quantity = 0})
      : quantityController = TextEditingController(
          text: quantity > 0 ? quantity.toString() : '',
        );

  void dispose() {
    quantityController.dispose();
    ingredientFocusNode.dispose();
  }
}
