import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  // Firebase collections
  final CollectionReference userCollection = FirebaseFirestore.instance.collection("users");
  final CollectionReference groupCollection = FirebaseFirestore.instance.collection("groups");
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Method to upload image/videos
  Future<String> uploadMedia(File mediaFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child("chat_media/$fileName");

      UploadTask uploadTask = storageRef.putFile(mediaFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String mediaUrl = await taskSnapshot.ref.getDownloadURL();

      return mediaUrl;
    } catch (e) {
      throw Exception("Failed to upload media: $e");
    }
  }

  // Method to send a text message
  Future<void> sendTextMessage(String groupId, String message, String sender) async {
    await sendMessage(groupId, {
      'message': message,
      'sender': sender,
      'time': FieldValue.serverTimestamp(),
      'type': 'text', // Always set the type as 'text' for text messages
    });
  }

  // Method to send a media message (image/video) ********************changes made here
  Future<void> sendMediaMessage(
      String groupId,
      String mediaUrl, // This is now the GET endpoint URL
      String userName,
      String mediaType,
      ) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'message': mediaUrl, // Store the GET endpoint URL
      'type': 'media',
      'mediaType': mediaType,
      'sender': '${FirebaseAuth.instance.currentUser!.uid}_$userName',
      'time': DateTime.now().millisecondsSinceEpoch,
    });
  }


  Future<void> sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    // Ensure required fields are present
    final messageData = {
      'message': chatMessageData['message'] ?? '',
      'sender': chatMessageData['sender'] ?? 'unknown',
      'time': chatMessageData['time'] ?? FieldValue.serverTimestamp(),
      'type': chatMessageData['type'] ?? 'text',
    };

    await groupCollection.doc(groupId).collection("messages").add(messageData);
    await groupCollection.doc(groupId).update({
      "recentMessage": messageData['message'],
      "recentMessageSender": messageData['sender'],
      "recentMessageTime": messageData['time'].toString(),
    });

    await fixBrokenMessages(groupId);

  }

  // Save user data when account is created
  Future<void> savingUserData(String fullName, String email) async {
    await userCollection.doc(uid).set({
      "fullName": fullName,
      "email": email,
      "groups": [],
      "profilePic": "",
      "uid": uid,
    });
  }

  // Get user data by email
  Future<QuerySnapshot> gettingUserData(String email) async {
    return await userCollection.where("email", isEqualTo: email).get();
  }

  // Listen to user's groups
  Stream<DocumentSnapshot> getUserGroups() {
    return userCollection.doc(uid).snapshots();
  }

  // Create a new group
  Future<void> createGroup(String userName, String id, String groupName) async {
    DocumentReference groupRef = await groupCollection.add({
      "groupName": groupName,
      "groupIcon": "",
      "admin": "${id}_$userName",
      "members": [],
      "groupId": "",
      "recentMessage": "",
      "recentMessageSender": "",
      "groupRequests": [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    await groupRef.update({
      "members": FieldValue.arrayUnion(["${uid}_$userName"]),
      "groupId": groupRef.id,
    });

    await userCollection.doc(uid).update({
      "groups": FieldValue.arrayUnion(["${groupRef.id}_$groupName"]),
    });
  }

  // Stream of chat messages for a group
  Stream<QuerySnapshot> getChats(String groupId) {
    return groupCollection
        .doc(groupId)
        .collection("messages")
        .orderBy("time", descending: true)
        .snapshots();
  }

  // Get group admin
  Future<String> getGroupAdmin(String groupId) async {
    DocumentSnapshot snapshot = await groupCollection.doc(groupId).get();
    return snapshot['admin'];
  }

  // Get group members stream
  Stream<DocumentSnapshot> getGroupMembers(String groupId) {
    return groupCollection.doc(groupId).snapshots();
  }

  // Search for group by name
  Future<QuerySnapshot> searchByName(String groupName) {
    return groupCollection
        .where("groupName", isEqualTo: groupName)
        .get();
  }

  // Check if user is joined
  Future<bool> isUserJoined(String groupName, String groupId, String userName) async {
    DocumentSnapshot snapshot = await userCollection.doc(uid).get();
    List<dynamic> groups = snapshot['groups'];
    return groups.contains("${groupId}_$groupName");
  }

  // Join group (after approval)
  Future<void> joinGroup(String groupId, String groupName) async {
    DocumentSnapshot userDoc = await userCollection.doc(uid).get();
    String userName = userDoc['fullName'] ?? '';
    String fullUserString = "${uid}_$userName";

    await groupCollection.doc(groupId).update({
      "members": FieldValue.arrayUnion([fullUserString]),
    });

    await userCollection.doc(uid).update({
      "groups": FieldValue.arrayUnion(["${groupId}_$groupName"]),
    });
  }

  // Leave group with all safety checks
  Future<void> leaveGroup(String groupId, String groupName) async {
    final userDoc = await userCollection.doc(uid).get();
    final userName = userDoc['fullName'] ?? '';
    final fullUserString = "${uid}_$userName";

    final groupDoc = await groupCollection.doc(groupId).get();
    final admin = groupDoc['admin'] as String;
    final isAdmin = admin == fullUserString;
    final members = List.from(groupDoc['members'] ?? []);
    final isLastMember = members.length == 1 && members.contains(fullUserString);

    if (isLastMember) {
      await _deleteEntireGroup(groupId, groupName);
    } else if (isAdmin) {
      throw Exception("Cannot leave as admin. Transfer admin rights first.");
    } else {
      await groupCollection.doc(groupId).update({
        "members": FieldValue.arrayRemove([fullUserString]),
      });
    }

    await userCollection.doc(uid).update({
      "groups": FieldValue.arrayRemove(["${groupId}_$groupName"]),
    });
  }

  // Delete entire group and clean up
  Future<void> _deleteEntireGroup(String groupId, String groupName) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    batch.delete(groupCollection.doc(groupId));

    final messages = await groupCollection.doc(groupId).collection("messages").get();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Transfer admin rights
  Future<void> transferAdminRights({
    required String groupId,
    required String newAdminId,
    required String newAdminName,
  }) async {
    final newAdminString = "${newAdminId}_$newAdminName";

    await groupCollection.doc(groupId).update({
      "admin": newAdminString,
      "members": FieldValue.arrayUnion([newAdminString]),
    });
  }

  // Handle join requests
  Future<void> sendJoinRequest(String groupId, String userName, String userId) async {
    final requestId = "${userId}_$userName";
    await groupCollection.doc(groupId).update({
      "groupRequests": FieldValue.arrayUnion([requestId])
    });
  }

  // Approve join request
  Future<void> approveJoinRequest({
    required String groupId,
    required String groupName,
    required String userId,
    required String userName,
    required String assignedName,
  }) async {
    final fullId = "${userId}_$userName";

    await groupCollection.doc(groupId).update({
      "members": FieldValue.arrayUnion([fullId]),
      "groupRequests": FieldValue.arrayRemove([fullId]),
      "groupAnonNames": {userId: assignedName},
    });

    await userCollection.doc(userId).update({
      "groups": FieldValue.arrayUnion(["${groupId}_$groupName"]),
    });
  }

  // Remove member
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String groupName,
    required String memberId,
    required String memberName,
    required String fullMemberString,
  }) async {
    await groupCollection.doc(groupId).update({
      "members": FieldValue.arrayRemove([fullMemberString])
    });

    await userCollection.doc(memberId).update({
      "groups": FieldValue.arrayRemove(["${groupId}_$groupName"])
    });
  }

  //updating old messages
  Future<void> updateOldMessages(String groupId) async {
    try {
      // Fetch messages without 'type' field
      FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          if (!doc.data().containsKey('type')) {
            doc.reference.update({'type': 'text'});  // Default 'type' to 'text' for old messages
          }
        });
      });
    } catch (e) {
      print('Error updating old messages: $e');
    }
  }
  //helping function
  Future<void> fixBrokenMessages(String groupId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        bool needsUpdate = false;
        Map<String, dynamic> updateData = {};

        if (!data.containsKey('time') || data['time'] == null) {
          print('🛠 Fixing missing time for doc ${doc.id}');
          updateData['time'] = FieldValue.serverTimestamp();
          needsUpdate = true;
        }

        if (!data.containsKey('type') || data['type'] == null) {
          print('🛠 Fixing missing type for doc ${doc.id}');
          updateData['type'] = 'text'; // Default type
          needsUpdate = true;
        }

        if (needsUpdate) {
          await doc.reference.update(updateData);
          print('✅ Updated doc ${doc.id}');
        }
      }

      print('🎉 Fix complete!');
    } catch (e) {
      print('❌ Error while fixing messages: $e');
    }
  }

}
