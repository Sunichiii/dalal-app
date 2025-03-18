import 'package:bloc/bloc.dart';
import '../../../services/database_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final DatabaseService databaseService;

  ChatBloc({required this.databaseService}) : super(ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<SendMessage>(_onSendMessage);
  }

  void _onLoadChats(LoadChats event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());
      final chatStream = await databaseService.getChats(event.groupId);
      emit(ChatLoaded(chats: chatStream));
    } catch (e) {
      emit(ChatError(message: "Failed to load chats"));
    }
  }

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) {
    if (event.message.isNotEmpty) {
      databaseService.sendMessage(event.groupId, {
        "message": event.message,
        "sender": event.userName,
        "time": DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
