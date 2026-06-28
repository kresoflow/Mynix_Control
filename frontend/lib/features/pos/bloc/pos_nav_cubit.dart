import 'package:flutter_bloc/flutter_bloc.dart';

class PosNavCubit extends Cubit<List<dynamic>> {
  PosNavCubit() : super([]);

  void pushCategory(dynamic category) {
    emit(List.from(state)..add(category));
  }

  void popCategory() {
    if (state.isNotEmpty) {
      emit(List.from(state)..removeLast());
    }
  }

  void clearHistory() {
    emit([]);
  }

  void popTo(int index) {
    if (index >= 0 && index < state.length) {
      emit(state.sublist(0, index + 1));
    }
  }
}
