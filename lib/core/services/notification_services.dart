// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
//   // For local notifications
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   Future<void> initializeNotifications() async {
//     // Initialize Flutter local notifications plugin
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('app_icon');
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//
//     // Request permissions for iOS
//     await _firebaseMessaging.requestPermission();
//
//     // Get the FCM token for the device
//     String? token = await _firebaseMessaging.getToken();
//     print("FCM Token: $token");
//
//     // Configure background message handling
//     FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
//
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('Received message: ${message.notification?.title}');
//       if (message.notification != null) {
//         showNotification(message.notification!);
//       }
//     });
//
//     // Handle message when the app is in the background
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('Message clicked!');
//     });
//   }
//
//   // Show local notification
//   Future<void> showNotification(RemoteNotification notification) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'channel_id',
//       'channel_name',
//       channelDescription: 'Your channel description',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: false,
//     );
//
//     const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
//
//     await flutterLocalNotificationsPlugin.show(
//       0,
//       notification.title,
//       notification.body,
//       platformDetails,
//     );
//   }
//
//   // Handle background messages
//   static Future<void> backgroundMessageHandler(RemoteMessage message) async {
//     print('Handling background message: ${message.notification?.title}');
//     // Handle background message (e.g., show local notification)
//   }
// }
