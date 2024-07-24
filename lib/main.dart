import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

final navigatorKey = GlobalKey<NavigatorState>();

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
  await FirebaseNoti().initNotifications();
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
