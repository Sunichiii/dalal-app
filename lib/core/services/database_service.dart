import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  // Firebase collections
  final CollectionReference userCollection = FirebaseFirestore.instance.collection("users");
  final CollectionReference groupCollection = FirebaseFirestore.instance.collection("groups");

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

  // Create a new group and add creator to it
  Future<void> createGroup(String userName, String id, String groupName) async {
    DocumentReference groupRef = await groupCollection.add({
      "groupName": groupName,
      "groupIcon": "",
      "admin": "${id}_$userName",
      "members": [],
      "groupId": "",
      "recentMessage": "",
      "recentMessageSender": "",
      "groupRequests": [], //  initialized empty for safety
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
        .orderBy("time")
        .snapshots();
  }

  // Get group admin's full string (uid_name)
  Future<String> getGroupAdmin(String groupId) async {
    DocumentSnapshot snapshot = await groupCollection.doc(groupId).get();
    return snapshot['admin'];
  }

  // Listen to members and metadata of a group
  Stream<DocumentSnapshot> getGroupMembers(String groupId) {
    return groupCollection.doc(groupId).snapshots();
  }

  // Search for group by name
  Future<QuerySnapshot> searchByName(String groupName) {
    return groupCollection.where("groupName", isEqualTo: groupName).get();
  }

  // Check if user is already a member of the group
  Future<bool> isUserJoined(String groupName, String groupId, String userName) async {
    DocumentSnapshot snapshot = await userCollection.doc(uid).get();
    List<dynamic> groups = snapshot['groups'];
    return groups.contains("${groupId}_$groupName");
  }

  // Toggle join/leave a group (only used after approval)
  Future<void> toggleGroupJoin(String groupId, String userName, String groupName) async {
    DocumentReference userRef = userCollection.doc(uid);
    DocumentReference groupRef = groupCollection.doc(groupId);

    DocumentSnapshot userSnapshot = await userRef.get();
    List<dynamic> groups = userSnapshot['groups'];

    if (groups.contains("${groupId}_$groupName")) {
      // Leave group
      await userRef.update({
        "groups": FieldValue.arrayRemove(["${groupId}_$groupName"]),
      });
      await groupRef.update({
        "members": FieldValue.arrayRemove(["${uid}_$userName"]),
      });
    } else {
      // Join group
      await userRef.update({
        "groups": FieldValue.arrayUnion(["${groupId}_$groupName"]),
      });
      await groupRef.update({
        "members": FieldValue.arrayUnion(["${uid}_$userName"]),
      });
    }
  }

  // Send a chat message in a group
  Future<void> sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    await groupCollection.doc(groupId).collection("messages").add(chatMessageData);
    await groupCollection.doc(groupId).update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString(),
    });
  }

  // Send join request (only adds if not already requested)
  Future<void> sendJoinRequest(String groupId, String userName, String userId) async {
    final groupRef = groupCollection.doc(groupId);
    final groupDoc = await groupRef.get();

    final data = groupDoc.data() as Map<String, dynamic>?;
    List<dynamic> currentRequests = [];

    if (data != null && data.containsKey('groupRequests')) {
      currentRequests = List.from(data['groupRequests']);
    }

    String requestId = "${userId}_$userName";

    if (!currentRequests.contains(requestId)) {
      await groupRef.update({
        "groupRequests": FieldValue.arrayUnion([requestId])
      });
    }
  }

  //  Admin approves join request
  Future<void> approveJoinRequest(String groupId, String userId, String userName) async {
    final userRef = userCollection.doc(userId);
    final groupRef = groupCollection.doc(groupId);

    final groupDoc = await groupRef.get();
    final groupName = groupDoc['groupName'];
    final fullId = "${userId}_$userName";

    // Add user to group and remove request
    await groupRef.update({
      "members": FieldValue.arrayUnion([fullId]),
      "groupRequests": FieldValue.arrayRemove([fullId]),
    });

    // Add group to user's joined list
    await userRef.update({
      "groups": FieldValue.arrayUnion(["${groupId}_$groupName"]),
    });
  }
}
