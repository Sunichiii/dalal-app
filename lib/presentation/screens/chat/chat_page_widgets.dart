// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../../core/shared/constants.dart';
// import '../../widgets/mediaMessageTile.dart';
// import '../../widgets/message_tile.dart';
//
// import 'bloc/chat_bloc.dart';
// import 'bloc/chat_state.dart';
//
// Widget chatMessages(BuildContext context, ScrollController scrollController) {
//   return BlocBuilder<ChatBloc, ChatState>(
//     builder: (context, state) {
//       if (state is ChatLoading) {
//         return const Center(child: CircularProgressIndicator());
//       } else if (state is ChatLoaded) {
//         return StreamBuilder(
//           stream: state.chats,
//           builder: (context, AsyncSnapshot snapshot) {
//             if (!snapshot.hasData) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (scrollController.hasClients) {
//                 scrollController.jumpTo(
//                   scrollController.position.maxScrollExtent,
//                 );
//               }
//             });
//
//             final isUploadingPreview =
//                 state.isUploading && state.mediaPreview.isNotEmpty;
//             final totalItemCount =
//                 snapshot.data.docs.length + (isUploadingPreview ? 1 : 0);
//
//             return ListView.builder(
//               controller: scrollController,
//               itemCount: totalItemCount,
//               padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
//               itemBuilder: (context, index) {
//                 final actualIndex = index - (isUploadingPreview ? 1 : 0);
//
//                 // Show media preview during upload
//                 if (isUploadingPreview && index == snapshot.data.docs.length) {
//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(10),
//                           child: Image.file(
//                             File(state.mediaPreview),
//                             width: 250,
//                             height: 250,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       const Padding(
//                         padding: EdgeInsets.only(right: 12.0),
//                         child: Text("Sending...", style: TextStyle(color: Colors.grey)),
//                       )
//                     ],
//                   );
//                 }
//
//                 if (actualIndex < 0 || actualIndex >= snapshot.data.docs.length) {
//                   return const SizedBox.shrink();
//                 }
//
//                 var messageData = snapshot.data.docs[actualIndex];
//
//                 String sender = messageData['sender'];
//                 String uid = sender.contains('_') ? sender.split('_')[0] : sender;
//                 String displayName = state.anonMap[uid] ?? "Admin";
//                 String currentUserId = FirebaseAuth.instance.currentUser!.uid;
//                 bool sentByMe = sender.startsWith(currentUserId);
//
//                 DateTime messageDateTime;
//                 var rawTime = messageData['time'];
//
//                 if (rawTime == null) {
//                   messageDateTime = DateTime.now();
//                 } else if (rawTime is Timestamp) {
//                   messageDateTime = rawTime.toDate();
//                 } else if (rawTime is int) {
//                   messageDateTime =
//                       DateTime.fromMillisecondsSinceEpoch(rawTime);
//                 } else {
//                   messageDateTime = DateTime.now();
//                 }
//
//                 String formattedTime = DateFormat('hh:mm a').format(messageDateTime);
//                 String messageType = messageData['type'] ?? 'text';
//                 String message = messageData['message'];
//
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (messageType == 'media')
//                       MediaMessageTile(
//                         message: message,
//                         sentByMe: sentByMe,
//                       ),
//                     if (messageType == 'text')
//                       MessageTile(
//                         message: message,
//                         sender: displayName,
//                         sentByMe: sentByMe,
//                         time: formattedTime,
//                         messageType: messageType,
//                       ),
//                   ],
//                 );
//               },
//             );
//           },
//         );
//       } else if (state is ChatError) {
//         return Center(
//           child: Text(state.message, style: const TextStyle(color: Colors.red)),
//         );
//       }
//       return Container();
//     },
//   );
// }
//
//
// Widget emojiPicker({
//   required bool isEmojiVisible,
//   required TextEditingController controller,
//   required FocusNode focusNode,
// }) {
//   return isEmojiVisible
//       ? EmojiPicker(
//         onEmojiSelected: (category, emoji) {
//           controller.text += emoji.emoji;
//           focusNode.requestFocus();
//         },
//       )
//       : Container();
// }
//
// Widget uploadProgressIndicator(double progress) {
//   return Positioned(
//     bottom: 80,
//     left: 20,
//     right: 20,
//     child: Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.7),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children: [
//           LinearProgressIndicator(
//             value: progress,
//             backgroundColor: Colors.grey[300],
//             valueColor: AlwaysStoppedAnimation<Color>(Constants().accentColor),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Uploading... ${(progress * 100).toStringAsFixed(1)}%',
//             style: const TextStyle(color: Colors.white),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget messageInputField({
//   required TextEditingController messageController,
//   required FocusNode messageFocusNode,
//   required bool isEmojiVisible,
//   required VoidCallback onMediaTap,
//   required VoidCallback onEmojiTap,
//   required VoidCallback onSendTap,
//   required String mediaPreview,
//   required VoidCallback onRemoveMediaPreview,
//   required bool isUploading,
// }) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//     decoration: BoxDecoration(
//       color: Constants().primaryColor,
//       borderRadius: const BorderRadius.only(
//         topLeft: Radius.circular(20),
//         topRight: Radius.circular(20),
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black12,
//           blurRadius: 10,
//           spreadRadius: 2,
//           offset: const Offset(0, -2),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         IconButton(
//           icon: const Icon(Icons.attach_file),
//           onPressed: isUploading ? null : onMediaTap,
//           color: Constants().accentColor,
//           tooltip: 'Attach media',
//         ),
//         IconButton(
//           icon: const Icon(Icons.emoji_emotions),
//           onPressed: onEmojiTap,
//           color: Constants().accentColor,
//           tooltip: 'Emoji',
//         ),
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[700],
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: messageController,
//                     focusNode: messageFocusNode,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: const InputDecoration(
//                       hintText: "Type a message...",
//                       hintStyle: TextStyle(color: Colors.white54),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 15,
//                         vertical: 12,
//                       ),
//                       border: InputBorder.none,
//                     ),
//                     onTap: () {
//                       if (isEmojiVisible) {
//                         onEmojiTap();
//                       }
//                     },
//                   ),
//                 ),
//                 if (mediaPreview.isNotEmpty && !isUploading)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 8.0),
//                     child: GestureDetector(
//                       onTap: onRemoveMediaPreview,
//                       child: Stack(
//                         children: [
//                           Container(
//                             width: 40,
//                             height: 40,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               image: DecorationImage(
//                                 image: FileImage(File(mediaPreview)),
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             top: -5,
//                             right: -5,
//                             child: IconButton(
//                               icon: const Icon(Icons.close, size: 18),
//                               color: Colors.red,
//                               onPressed: onRemoveMediaPreview,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         GestureDetector(
//           onTap: onSendTap,
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color:
//                   messageController.text.isNotEmpty && !isUploading
//                       ? Constants().accentColor
//                       : Colors.grey,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.send, color: Colors.white, size: 22),
//           ),
//         ),
//       ],
//     ),
//   );
// }
