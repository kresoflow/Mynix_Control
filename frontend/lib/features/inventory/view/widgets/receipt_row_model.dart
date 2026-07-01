import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class ReceiptRowModel {
  Ingredient? ingredient;
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final FocusNode qtyFocus = FocusNode();
  final FocusNode costFocus = FocusNode();
  FocusNode? searchFocus;

  void dispose() {
    qtyController.dispose();
    costController.dispose();
    qtyFocus.dispose();
    costFocus.dispose();
  }
}
