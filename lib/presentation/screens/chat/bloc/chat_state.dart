import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';


abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final Stream<QuerySnapshot> chats;
  final Map<String, String> anonMap;

  ChatLoaded({required this.anonMap,required this.chats});

  @override
  List<Object?> get props => [chats, anonMap];
}

class ChatError extends ChatState {
  final String message;
  ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
