import 'package:firebase_auth/firebase_auth.dart';
import 'package:groupie_v2/helper/helper_function.dart';
import 'package:groupie_v2/services/database_service.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // Register user with email and password
  Future<Object?> registerUserWithEmailAndPassword(String fullName, String email, String password) async {
    try {
      // Create user
      UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = userCredential.user!;

      if (user != null) {
        await DatabaseService(uid: user.uid).updateUserData(fullName, email);
        return true;

      } else {
        return false; // User is null for some reason
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuthException errors
      return e.message;
    } catch (e) {
      // Handle any other errors
      print('Unexpected error: $e');
      return false;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await HelperFunctions.saveUserLoggedInStatus(false);
      await HelperFunctions.saveUserEmailSF("");
      await HelperFunctions.saveUserNameSF("");
      await firebaseAuth.signOut();
      print("User signed out successfully.");
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
