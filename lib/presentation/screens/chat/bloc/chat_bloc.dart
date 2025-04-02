import 'dart:io';

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

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
    final fullSender = "${userId}_${event.userName}";

    // Check if the message is media (image/video) based on the file extension
    String messageType = event.message.contains(RegExp(r'\.(jpg|jpeg|png|gif|mp4)$')) ? 'media' : 'text';

    if (event.message.isNotEmpty) {
      // If it's a media message, upload to Firebase Storage and get the media URL
      if (messageType == 'media') {
        try {
          // Check if it's an image or video (determine this when sending the media)
          File mediaFile = File(event.message);  // Assuming event.message holds the file path
          String mediaUrl = await DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid)
              .uploadMedia(mediaFile); // Upload media and get the URL

          // Send message with media URL and type 'media'
          await databaseService.sendMessage(event.groupId, {
            "message": mediaUrl,  // Store the URL of the media
            "sender": fullSender,
            "time": DateTime.now().millisecondsSinceEpoch,
            "type": 'media',  // Mark this as media
          });
        } catch (e) {
          print("Error uploading media: $e");
        }
      } else {
        // Send a text message
        await databaseService.sendMessage(event.groupId, {
          "message": event.message,
          "sender": fullSender,
          "time": DateTime.now().millisecondsSinceEpoch,
          "type": 'text',  // Mark this as text
        });
      }
    }
  }

}
