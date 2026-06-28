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
