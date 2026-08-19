import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_event.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_state.dart';
import 'package:mynix_frontend/features/crm/models/bonus_transaction.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';
import 'package:mynix_frontend/features/crm/repository/crm_repository.dart';

class CrmBloc extends Bloc<CrmEvent, CrmState> {
  final CrmRepository repository;

  CrmBloc(this.repository) : super(CrmInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<LoadCustomerTransactionsEvent>(_onLoadTransactions);
    on<CreateCustomerTransactionEvent>(_onCreateTransaction);
    on<LoadCustomerBonusTransactionsEvent>(_onLoadBonusTransactions);
    on<CreateCustomerBonusTransactionEvent>(_onCreateBonusTransaction);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CrmState> emit,
  ) async {
    final query = event.query ?? (state is CrmLoaded ? (state as CrmLoaded).searchQuery : '');
    final filter = event.filterType ?? (state is CrmLoaded ? (state as CrmLoaded).activeFilter : 'all');

    if (state is! CrmLoaded) {
      emit(CrmLoading());
    }

    try {
      final customers = await repository.getCustomers(
        query: query,
        filterType: filter,
      );

      final txnCache = state is CrmLoaded ? (state as CrmLoaded).transactionsCache : <int, List<CustomerTransaction>>{};
      final bonusCache = state is CrmLoaded ? (state as CrmLoaded).bonusTransactionsCache : <int, List<BonusTransaction>>{};

      emit(CrmLoaded(
        customers: customers,
        searchQuery: query,
        activeFilter: filter,
        transactionsCache: Map.from(txnCache),
        bonusTransactionsCache: Map.from(bonusCache),
      ));
    } catch (e) {
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CrmState> emit,
  ) async {
    try {
      await repository.createCustomer(event.data);
      add(const LoadCustomers());
    } catch (e) {
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CrmState> emit,
  ) async {
    try {
      await repository.updateCustomer(event.id, event.data);
      add(const LoadCustomers());
    } catch (e) {
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CrmState> emit,
  ) async {
    try {
      await repository.deleteCustomer(event.id);
      add(const LoadCustomers());
    } catch (e) {
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadTransactions(
    LoadCustomerTransactionsEvent event,
    Emitter<CrmState> emit,
  ) async {
    if (state is! CrmLoaded) return;
    final loadedState = state as CrmLoaded;

    try {
      final txns = await repository.getCustomerTransactions(event.customerId);
      final newCache = Map<int, List<CustomerTransaction>>.from(loadedState.transactionsCache);
      newCache[event.customerId] = txns;
      emit(loadedState.copyWith(transactionsCache: Map.from(newCache)));
    } catch (e) {
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateTransaction(
    CreateCustomerTransactionEvent event,
    Emitter<CrmState> emit,
  ) async {
    if (state is! CrmLoaded) return;
    final loadedState = state as CrmLoaded;

    try {
      emit(loadedState.copyWith(isSubmitting: true));
      await repository.createCustomerTransaction(event.customerId, event.data);
      
      final txns = await repository.getCustomerTransactions(event.customerId);
      final updatedCustomers = await repository.getCustomers(
        query: loadedState.searchQuery,
        filterType: loadedState.activeFilter,
      );

      final newCache = Map<int, List<CustomerTransaction>>.from(loadedState.transactionsCache);
      newCache[event.customerId] = txns;

      emit(loadedState.copyWith(
        customers: updatedCustomers,
        transactionsCache: Map.from(newCache),
        isSubmitting: false,
      ));
    } catch (e) {
      emit(loadedState.copyWith(isSubmitting: false));
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadBonusTransactions(
    LoadCustomerBonusTransactionsEvent event,
    Emitter<CrmState> emit,
  ) async {
    if (state is! CrmLoaded) return;
    final loadedState = state as CrmLoaded;

    try {
      final txns = await repository.getBonusTransactions(event.customerId);
      final newCache = Map<int, List<BonusTransaction>>.from(loadedState.bonusTransactionsCache);
      newCache[event.customerId] = txns;
      emit(loadedState.copyWith(bonusTransactionsCache: Map.from(newCache)));
    } catch (e) {
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateBonusTransaction(
    CreateCustomerBonusTransactionEvent event,
    Emitter<CrmState> emit,
  ) async {
    if (state is! CrmLoaded) return;
    final loadedState = state as CrmLoaded;

    try {
      emit(loadedState.copyWith(isSubmitting: true));
      await repository.createBonusTransaction(event.customerId, event.data);
      
      final txns = await repository.getBonusTransactions(event.customerId);
      final updatedCustomers = await repository.getCustomers(
        query: loadedState.searchQuery,
        filterType: loadedState.activeFilter,
      );

      final newCache = Map<int, List<BonusTransaction>>.from(loadedState.bonusTransactionsCache);
      newCache[event.customerId] = txns;

      emit(loadedState.copyWith(
        customers: updatedCustomers,
        bonusTransactionsCache: Map.from(newCache),
        isSubmitting: false,
      ));
    } catch (e) {
      emit(loadedState.copyWith(isSubmitting: false));
      emit(CrmError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
