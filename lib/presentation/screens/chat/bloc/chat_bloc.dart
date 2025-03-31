import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/database_service.dart';
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

      final chatStream = databaseService.getChats(event.groupId);

      // Fetch group doc and get anonymous names
      final groupSnapshot = await databaseService.groupCollection.doc(event.groupId).get();
      final data = groupSnapshot.data() as Map<String, dynamic>;

      Map<String, String> anonMap = {};
      if (data.containsKey("groupAnonNames")) {
        anonMap = Map<String, String>.from(data["groupAnonNames"]);
      }

      emit(ChatLoaded(chats: chatStream, anonMap: anonMap));
    } catch (e) {
      emit(ChatError(message: "Failed to load chats"));
    }
  }


  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
    final fullSender = "${userId}_${event.userName}";

    if (event.message.isNotEmpty) {
      databaseService.sendMessage(event.groupId, {
        "message": event.message,
        "sender": fullSender,
        "time": DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
