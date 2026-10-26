import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class PosNavCubit extends Cubit<List<dynamic>> {
  PosNavCubit() : super([]);

  // Syncs the cubit state with the URL
  void syncWithUrl(BuildContext context, String? categoryId, List<dynamic> allCategories) {
    if (categoryId == null || categoryId.isEmpty) {
      if (state.isNotEmpty) emit([]);
      return;
    }

    // Only rebuild history if it doesn't match current state to avoid loops
    final currentId = state.isEmpty ? null : state.last.id.toString();
    if (currentId == categoryId) return;

    final history = <dynamic>[];
    String? currentLookupId = categoryId;

    while (currentLookupId != null) {
      final cat = allCategories.where((c) => c.id.toString() == currentLookupId).firstOrNull;
      if (cat != null) {
        history.insert(0, cat); // insert at beginning
        currentLookupId = cat.parentId?.toString();
      } else {
        break;
      }
    }

    emit(history);
  }

  void pushCategory(BuildContext context, dynamic category) {
    emit(List.from(state)..add(category));
    _updateUrl(context, category.id.toString());
  }

  void popCategory(BuildContext context) {
    if (state.isNotEmpty) {
      final newState = List<dynamic>.from(state)..removeLast();
      emit(newState);
      final newId = newState.isEmpty ? null : newState.last.id.toString();
      _updateUrl(context, newId);
    }
  }

  void clearHistory(BuildContext context) {
    emit([]);
    _updateUrl(context, null);
  }

  void popTo(BuildContext context, int index) {
    if (index >= 0 && index < state.length) {
      final newState = state.sublist(0, index + 1);
      emit(newState);
      _updateUrl(context, newState.last.id.toString());
    }
  }

  void _updateUrl(BuildContext context, String? categoryId) {
    if (categoryId == null) {
      context.go('/pos');
    } else {
      context.go('/pos?category=$categoryId');
    }
  }
}
