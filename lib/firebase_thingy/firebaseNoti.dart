import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fs/notification_storage.dart'; // Import the notification storage
import 'package:fs/screen/notiPage.dart';
import 'package:fs/main.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  notificationStorage.addNotification(message); // Add to notification storage
}

class FirebaseNoti {
  final _firebaseMessaging = FirebaseMessaging.instance;

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    notificationStorage.addNotification(message); // Add to notification storage

    navigatorKey.currentState?.pushNamed(
      NotificationsPage.route,
      arguments: message,
    );
  }

  Future initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/fsygnoti');
    const settings = InitializationSettings(android: android);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
        handleMessage(message);
      },
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      notificationStorage.addNotification(message); // Add to notification storage

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/fsygnoti',
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fCMToken');
    await initPushNotifications();
    await initLocalNotifications();
  }
}
