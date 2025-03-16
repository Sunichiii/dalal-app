import 'package:firebase_auth/firebase_auth.dart';
import 'package:groupie_v2/helper/helper_function.dart';
import 'package:groupie_v2/services/database_service.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  //Login with email and password
  // Register user with email and password
  Future<Object?> loginWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Store email after successful login
        await HelperFunctions.saveUserEmailSF(email);

        // Fetch full name from Firestore
        var userData = await DatabaseService(uid: user.uid).gettingUserData(email);
        if (userData.docs.isNotEmpty) {
          await HelperFunctions.saveUserNameSF(userData.docs[0]['fullName']);
        }

        return true;
      } else {
        return false; // User is null for some reason
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }


  // Register user with email and password
  Future<Object?> registerUserWithEmailAndPassword(
      String fullName,
      String email,
      String password,
      ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await DatabaseService(uid: user.uid).savingUserData(fullName, email);

        // Store email & full name in SharedPreferences
        await HelperFunctions.saveUserEmailSF(email);
        await HelperFunctions.saveUserNameSF(fullName);
        await HelperFunctions.saveUserLoggedInStatus(true);

        return true;
      } else {
        return false;
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
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
