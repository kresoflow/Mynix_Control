import 'package:flutter_bloc/flutter_bloc.dart';

class PosNavCubit extends Cubit<List<dynamic>> {
  PosNavCubit() : super([]);

  // Syncs the cubit state with the URL (только при инициализации/диплинке)
  void syncWithUrl(String? categoryId, List<dynamic> allCategories) {
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

  void pushCategory(dynamic category) {
    emit(List.from(state)..add(category));
  }

  void popCategory() {
    if (state.isNotEmpty) {
      final newState = List<dynamic>.from(state)..removeLast();
      emit(newState);
    }
  }

  void clearHistory() {
    if (state.isNotEmpty) {
      emit([]);
    }
  }

  void popTo(int index) {
    if (index >= 0 && index < state.length) {
      final newState = state.sublist(0, index + 1);
      emit(newState);
    }
  }
}
