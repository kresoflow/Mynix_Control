import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/superadmin_repository.dart';

abstract class TenantExplorerState extends Equatable {
  const TenantExplorerState();

  @override
  List<Object?> get props => [];
}

class TenantExplorerInitial extends TenantExplorerState {}

class TenantExplorerLoading extends TenantExplorerState {}

class TenantExplorerLoaded extends TenantExplorerState {
  final List<String> tables;
  final String? selectedTable;
  final List<Map<String, dynamic>>? columns;
  final List<String>? primaryKeys;
  final List<Map<String, dynamic>>? rows;
  final bool isTableLoading;

  const TenantExplorerLoaded({
    required this.tables,
    this.selectedTable,
    this.columns,
    this.primaryKeys,
    this.rows,
    this.isTableLoading = false,
  });

  TenantExplorerLoaded copyWith({
    List<String>? tables,
    String? selectedTable,
    List<Map<String, dynamic>>? columns,
    List<String>? primaryKeys,
    List<Map<String, dynamic>>? rows,
    bool? isTableLoading,
  }) {
    return TenantExplorerLoaded(
      tables: tables ?? this.tables,
      selectedTable: selectedTable ?? this.selectedTable,
      columns: columns ?? this.columns,
      primaryKeys: primaryKeys ?? this.primaryKeys,
      rows: rows ?? this.rows,
      isTableLoading: isTableLoading ?? this.isTableLoading,
    );
  }

  @override
  List<Object?> get props => [tables, selectedTable, columns, primaryKeys, rows, isTableLoading];
}

class TenantExplorerError extends TenantExplorerState {
  final String message;
  const TenantExplorerError(this.message);

  @override
  List<Object?> get props => [message];
}

class TenantExplorerBloc extends Cubit<TenantExplorerState> {
  final SuperadminRepository repository;
  final String systemToken;
  final String schemaName;

  TenantExplorerBloc({
    required this.repository,
    required this.systemToken,
    required this.schemaName,
  }) : super(TenantExplorerInitial());

  Future<void> loadTables() async {
    emit(TenantExplorerLoading());
    try {
      final tables = await repository.getSchemaTables(
        systemToken: systemToken,
        schemaName: schemaName,
      );
      emit(TenantExplorerLoaded(tables: tables));
      if (tables.isNotEmpty) {
        final defaultTable = tables.contains('menu_items') ? 'menu_items' : tables.first;
        await loadTableData(defaultTable);
      }
    } catch (e) {
      emit(TenantExplorerError(e.toString()));
    }
  }

  Future<void> loadTableData(String tableName) async {
    final currentState = state;
    if (currentState is! TenantExplorerLoaded) return;

    emit(currentState.copyWith(selectedTable: tableName, isTableLoading: true));
    try {
      final data = await repository.getTableData(
        systemToken: systemToken,
        schemaName: schemaName,
        tableName: tableName,
      );

      final rawColumns = (data['columns'] as List<dynamic>?) ?? [];
      final columns = rawColumns
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();

      final rawPks = (data['primary_keys'] as List<dynamic>?) ?? [];
      final pks = rawPks.map((k) => k.toString()).toList();

      final rawRows = (data['rows'] as List<dynamic>?) ?? [];
      final rows = rawRows
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

      emit(
        currentState.copyWith(
          selectedTable: tableName,
          columns: columns,
          primaryKeys: pks,
          rows: rows,
          isTableLoading: false,
        ),
      );
    } catch (e) {
      debugPrint('[TenantExplorerBloc] loadTableData error: $e');
      emit(TenantExplorerError(e.toString()));
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) emit(currentState.copyWith(isTableLoading: false));
    }
  }

  Future<void> createRow(Map<String, dynamic> payload) async {
    final currentState = state;
    if (currentState is! TenantExplorerLoaded || currentState.selectedTable == null) return;
    
    final table = currentState.selectedTable!;
    try {
      await repository.createTableRow(
        systemToken: systemToken,
        schemaName: schemaName,
        tableName: table,
        payload: payload,
      );
      await loadTableData(table); // Reload data
    } catch (e) {
      emit(TenantExplorerError('Create Error: $e'));
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> updateRow(Map<String, dynamic> payload) async {
    final currentState = state;
    if (currentState is! TenantExplorerLoaded || currentState.selectedTable == null) return;
    
    final table = currentState.selectedTable!;
    try {
      await repository.updateTableRow(
        systemToken: systemToken,
        schemaName: schemaName,
        tableName: table,
        payload: payload,
      );
      await loadTableData(table); // Reload data
    } catch (e) {
      emit(TenantExplorerError('Update Error: $e'));
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> deleteRow(Map<String, dynamic> pkPayload) async {
    final currentState = state;
    if (currentState is! TenantExplorerLoaded || currentState.selectedTable == null) return;
    
    final table = currentState.selectedTable!;
    try {
      await repository.deleteTableRow(
        systemToken: systemToken,
        schemaName: schemaName,
        tableName: table,
        pkPayload: pkPayload,
      );
      await loadTableData(table); // Reload data
    } catch (e) {
      emit(TenantExplorerError('Delete Error: $e'));
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) emit(currentState);
    }
  }
}
