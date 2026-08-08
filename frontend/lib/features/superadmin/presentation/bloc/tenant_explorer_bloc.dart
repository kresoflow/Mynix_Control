import 'package:equatable/equatable.dart';
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

  const TenantExplorerLoaded({
    required this.tables,
    this.selectedTable,
    this.columns,
    this.primaryKeys,
    this.rows,
  });

  TenantExplorerLoaded copyWith({
    List<String>? tables,
    String? selectedTable,
    List<Map<String, dynamic>>? columns,
    List<String>? primaryKeys,
    List<Map<String, dynamic>>? rows,
  }) {
    return TenantExplorerLoaded(
      tables: tables ?? this.tables,
      selectedTable: selectedTable ?? this.selectedTable,
      columns: columns ?? this.columns,
      primaryKeys: primaryKeys ?? this.primaryKeys,
      rows: rows ?? this.rows,
    );
  }

  @override
  List<Object?> get props => [tables, selectedTable, columns, primaryKeys, rows];
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
    } catch (e) {
      emit(TenantExplorerError(e.toString()));
    }
  }

  Future<void> loadTableData(String tableName) async {
    final currentState = state;
    if (currentState is! TenantExplorerLoaded) return;
    
    emit(TenantExplorerLoading());
    try {
      final data = await repository.getTableData(
        systemToken: systemToken,
        schemaName: schemaName,
        tableName: tableName,
      );
      
      final columns = List<Map<String, dynamic>>.from(data['columns']);
      final pks = List<String>.from(data['primary_keys']);
      final rows = List<Map<String, dynamic>>.from(data['rows']);

      emit(currentState.copyWith(
        selectedTable: tableName,
        columns: columns,
        primaryKeys: pks,
        rows: rows,
      ));
    } catch (e) {
      emit(TenantExplorerError(e.toString()));
      // Reset back to loaded state after delay
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) emit(currentState);
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
