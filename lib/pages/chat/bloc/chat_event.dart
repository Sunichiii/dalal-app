import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadChats extends ChatEvent {
  final String groupId;
  LoadChats({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class SendMessage extends ChatEvent {
  final String groupId;
  final String userName;
  final String message;

  SendMessage({required this.groupId, required this.userName, required this.message});

  @override
  List<Object?> get props => [groupId, userName, message];
}
