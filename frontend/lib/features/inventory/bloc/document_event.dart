import 'package:equatable/equatable.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  final String? type;

  const LoadDocuments({this.type});

  @override
  List<Object?> get props => [type];
}

class LoadSuppliers extends DocumentEvent {}

class CreateDocument extends DocumentEvent {
  final Map<String, dynamic> data;

  const CreateDocument(this.data);

  @override
  List<Object?> get props => [data];
}

class CompleteDocument extends DocumentEvent {
  final int documentId;

  const CompleteDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class CreateSupplier extends DocumentEvent {
  final String name;
  final String? contactInfo;

  const CreateSupplier(this.name, {this.contactInfo});

  @override
  List<Object?> get props => [name, contactInfo];
}

class UpdateSupplier extends DocumentEvent {
  final int id;
  final String name;
  final String? contactInfo;
  final bool? isActive;

  const UpdateSupplier(this.id, {required this.name, this.contactInfo, this.isActive});

  @override
  List<Object?> get props => [id, name, contactInfo, isActive];
}

class DeleteSupplier extends DocumentEvent {
  final int id;

  const DeleteSupplier(this.id);

  @override
  List<Object?> get props => [id];
}
