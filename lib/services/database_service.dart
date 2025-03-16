import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  // Reference for our collections
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection("users");
  final CollectionReference groupCollection = FirebaseFirestore.instance
      .collection("groups");

  // Updating the user data
  Future<void> savingUserData(String fullName, String email) async {
    try {
      // Ensure the user ID is not null
      if (uid != null) {
        // Update the user document using the provided uid
        await userCollection.doc(uid).set(
          {
            "fullName": fullName,
            "email": email,
            "groups": [], // Empty list for now
            "profilePic": "", // Empty string for now
            "userId": uid,
          },
          SetOptions(merge: true),
        ); // Merge ensures we don't overwrite other data
        print("User data updated successfully.");
      } else {
        print("User ID is null. Unable to update data.");
      }
    } catch (e) {
      print("Error updating user data: $e");
    }
  }

  //getting user data
  Future gettingUserData(String email) async {
    QuerySnapshot snapshot =
        await userCollection.where("email", isEqualTo: email).get();
    return snapshot;
  }
}
