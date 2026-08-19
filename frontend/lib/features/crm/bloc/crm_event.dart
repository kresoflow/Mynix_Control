import 'package:equatable/equatable.dart';

abstract class CrmEvent extends Equatable {
  const CrmEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CrmEvent {
  final String? query;
  final String? filterType;

  const LoadCustomers({this.query, this.filterType});

  @override
  List<Object?> get props => [query, filterType];
}

class CreateCustomerEvent extends CrmEvent {
  final Map<String, dynamic> data;

  const CreateCustomerEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateCustomerEvent extends CrmEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateCustomerEvent(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteCustomerEvent extends CrmEvent {
  final int id;

  const DeleteCustomerEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCustomerTransactionsEvent extends CrmEvent {
  final int customerId;

  const LoadCustomerTransactionsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class CreateCustomerTransactionEvent extends CrmEvent {
  final int customerId;
  final Map<String, dynamic> data;

  const CreateCustomerTransactionEvent(this.customerId, this.data);

  @override
  List<Object?> get props => [customerId, data];
}

class LoadCustomerBonusTransactionsEvent extends CrmEvent {
  final int customerId;

  const LoadCustomerBonusTransactionsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class CreateCustomerBonusTransactionEvent extends CrmEvent {
  final int customerId;
  final Map<String, dynamic> data;

  const CreateCustomerBonusTransactionEvent(this.customerId, this.data);

  @override
  List<Object?> get props => [customerId, data];
}
