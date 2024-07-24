// notification_storage.dart

import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationStorage {
  static final NotificationStorage _instance = NotificationStorage._internal();

  factory NotificationStorage() {
    return _instance;
  }

  NotificationStorage._internal();

  final List<RemoteMessage> _notifications = [];

  List<RemoteMessage> get notifications => List.unmodifiable(_notifications);

  void addNotification(RemoteMessage message) {
    if (!_notifications.any((msg) => msg.messageId == message.messageId)) {
      _notifications.add(message);
    }
  }
}

final notificationStorage = NotificationStorage();
