import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions {
  // Keys for saving data
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";  // Changed to a unique key
  static String userEmailKey = "USEREMAILKEY";  // Changed to a unique key

  // Saving data to SharedPreferences
  static Future<bool> saveUserLoggedInStatus(bool isUserLoggedIn) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(userLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserNameSF(String userName) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userNameKey, userName);  // Changed setBool to setString
  }

  static Future<bool> saveUserEmailSF(String userEmail) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    bool isSaved = await sf.setString(userEmailKey, userEmail);
    return isSaved;
  }


  // Getting data from SharedPreferences
  static Future<bool?> getUserLoggedInStatus() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(userLoggedInKey);
  }

  static Future<String?> getUserNameSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userNameKey);  // Fetching the user name
  }

  static Future<String?> getUserEmailSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    String? email = sf.getString(userEmailKey);
    print("Retrieved email: $email");
    return email;
  }

  //onboarding screen ko lagi
  static Future<bool> isOnboardingCompleted() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed')?? false;
  }
  static Future<void> setOnboardingCompleted() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

}
