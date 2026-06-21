import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

enum ThemeEvent { toggleTheme }

class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  ThemeBloc() : super(ThemeMode.light) {
    on<ThemeEvent>((event, emit) {
      if (event == ThemeEvent.toggleTheme) {
        emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
      }
    });
  }
}
