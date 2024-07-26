import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fs/firebase_thingy/firebaseNoti.dart';
import 'package:fs/screen/food_form.dart';
import 'package:fs/screen/home.dart';
import 'package:fs/screen/login.dart';
import 'package:fs/screen/mapView.dart';
import 'package:fs/screen/notiPage.dart';
import 'package:fs/screen/profile.dart';
import 'package:fs/screen/signUp.dart';
import 'package:fs/screen/splash.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_service.dart'; // Import the new FCM service

final navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC-MnxKfWoxF925Ve8pHVRzNEq9HOIAh-E",
      appId: "1:844490310796:android:b9f2c3fc75546427a1a7a9",
      messagingSenderId: "844490310796",
      projectId: "fshare-e20a4",
      storageBucket: "gs://fshare-e20a4.appspot.com",
    ),
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseNoti().initNotifications();

  // Initialize FCMService
  await FCMService().initFCM();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(
          child: LoginPage(),
        ),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/addForm': (context) => FoodForm(),
        '/map': (context) => MapViewPage(),
        NotificationsPage.route: (context) => NotificationsPage(),
        //'/profile': (context) => ProfilePage(),
      },
      // Optionally provide a builder for a global loading indicator
      builder: (context, child) {
        return FutureBuilder(
          future: Firebase.initializeApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return child!;
            }
            return Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  showNotification(message);
}

Future<void> showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
      'high_importance_channel', 'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false);
  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0, message.notification?.title, message.notification?.body, platformChannelSpecifics,
      payload: 'item x');
}
