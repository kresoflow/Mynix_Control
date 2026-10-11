// ==============================================================================
// МОДУЛЬ: POS / Управление вкладками и оперативным состоянием кассы
// ДОМЕН: lib/features/pos/bloc/pos_tab_cubit.dart
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';

// ── Состояние вкладок и столиков кассы ───────────────────────────────────────

class PosTabState extends Equatable {
  final int currentTab; // 0: Касса, 1: Заказы
  final int activeTablesCount;

  const PosTabState({
    this.currentTab = 0,
    this.activeTablesCount = 0,
  });

  PosTabState copyWith({
    int? currentTab,
    int? activeTablesCount,
  }) {
    return PosTabState(
      currentTab: currentTab ?? this.currentTab,
      activeTablesCount: activeTablesCount ?? this.activeTablesCount,
    );
  }

  @override
  List<Object?> get props => [currentTab, activeTablesCount];
}

// ── Cubit оперативного управления POS ─────────────────────────────────────────

class PosTabCubit extends Cubit<PosTabState> {
  final OrderRepository _orderRepo;

  PosTabCubit(this._orderRepo) : super(const PosTabState());

  void setTab(int tab) {
    if (state.currentTab != tab) {
      emit(state.copyWith(currentTab: tab));
    }
  }

  bool _isRefreshing = false;

  Future<void> refreshCounts() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final tables = await _orderRepo.fetchActiveTables();
      emit(
        state.copyWith(
          activeTablesCount: tables.length,
        ),
      );
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  void updateCounts({int? activeTablesCount}) {
    emit(
      state.copyWith(
        activeTablesCount: activeTablesCount,
      ),
    );
  }
}
