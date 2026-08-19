import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';
import 'package:mynix_frontend/features/crm/models/bonus_transaction.dart';

abstract class CrmState extends Equatable {
  const CrmState();

  @override
  List<Object?> get props => [];
}

class CrmInitial extends CrmState {}

class CrmLoading extends CrmState {}

class CrmLoaded extends CrmState {
  final List<Customer> customers;
  final String searchQuery;
  final String activeFilter; // "all", "debtors", "deposits", "vip", "churn", "new"
  final Map<int, List<CustomerTransaction>> transactionsCache;
  final Map<int, List<BonusTransaction>> bonusTransactionsCache;
  final Map<int, List<Map<String, dynamic>>> ordersCache;
  final bool isSubmitting;

  const CrmLoaded({
    required this.customers,
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.transactionsCache = const {},
    this.bonusTransactionsCache = const {},
    this.ordersCache = const {},
    this.isSubmitting = false,
  });

  double get totalDebt {
    return customers
        .where((c) => c.balance < 0)
        .fold(0.0, (sum, c) => sum + c.balance.abs());
  }

  double get totalDeposit {
    return customers
        .where((c) => c.balance > 0)
        .fold(0.0, (sum, c) => sum + c.balance);
  }

  double get totalLtv => customers.fold(0.0, (sum, c) => sum + c.totalSpent);
  double get totalBonuses => customers.fold(0.0, (sum, c) => sum + c.bonusBalance);

  int get debtorsCount => customers.where((c) => c.balance < -0.01).length;
  int get depositsCount => customers.where((c) => c.balance > 0.01).length;
  int get vipCount => customers.where((c) => c.totalSpent >= 10000.0).length;

  CrmLoaded copyWith({
    List<Customer>? customers,
    String? searchQuery,
    String? activeFilter,
    Map<int, List<CustomerTransaction>>? transactionsCache,
    Map<int, List<BonusTransaction>>? bonusTransactionsCache,
    Map<int, List<Map<String, dynamic>>>? ordersCache,
    bool? isSubmitting,
  }) {
    return CrmLoaded(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      transactionsCache: transactionsCache ?? this.transactionsCache,
      bonusTransactionsCache: bonusTransactionsCache ?? this.bonusTransactionsCache,
      ordersCache: ordersCache ?? this.ordersCache,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        customers,
        searchQuery,
        activeFilter,
        transactionsCache,
        bonusTransactionsCache,
        ordersCache,
        isSubmitting,
      ];
}

class CrmError extends CrmState {
  final String message;

  const CrmError(this.message);

  @override
  List<Object?> get props => [message];
}
