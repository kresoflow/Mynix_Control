// ==============================================================================
// МОДУЛЬ: POS / Управление вкладками и оперативным состоянием кассы
// ДОМЕН: lib/features/pos/bloc/pos_tab_cubit.dart
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';

// ── Состояние вкладок и бейджей кассы ─────────────────────────────────────────

class PosTabState extends Equatable {
  final int currentTab; // 0: Касса, 1: Заказы, 2: Кухня (KDS)
  final int incomingCount;
  final int activeTablesCount;

  const PosTabState({
    this.currentTab = 0,
    this.incomingCount = 0,
    this.activeTablesCount = 0,
  });

  PosTabState copyWith({
    int? currentTab,
    int? incomingCount,
    int? activeTablesCount,
  }) {
    return PosTabState(
      currentTab: currentTab ?? this.currentTab,
      incomingCount: incomingCount ?? this.incomingCount,
      activeTablesCount: activeTablesCount ?? this.activeTablesCount,
    );
  }

  @override
  List<Object?> get props => [currentTab, incomingCount, activeTablesCount];
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
      final pending = await _orderRepo.fetchPendingOrders();
      final tables = await _orderRepo.fetchActiveTables();
      emit(
        state.copyWith(
          incomingCount: pending.length,
          activeTablesCount: tables.length,
        ),
      );
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  void updateCounts({int? incomingCount, int? activeTablesCount}) {
    emit(
      state.copyWith(
        incomingCount: incomingCount,
        activeTablesCount: activeTablesCount,
      ),
    );
  }
}
