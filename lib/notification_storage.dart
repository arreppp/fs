import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationStorage {
  final List<RemoteMessage> _notifications = [];

  void addNotification(RemoteMessage message) {
    _notifications.add(message);
  }

  List<RemoteMessage> get notifications => List.unmodifiable(_notifications);
}

final notificationStorage = NotificationStorage();
