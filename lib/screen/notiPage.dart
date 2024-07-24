import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fs/notification_storage.dart'; // Import the notification storage

class NotificationsPage extends StatelessWidget {
  static const route = '/notification';

  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort the notifications by timestamp in descending order
    final sortedNotifications = List.from(notificationStorage.notifications)
      ..sort((a, b) => b.sentTime!.compareTo(a.sentTime!));

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: sortedNotifications.length,
        itemBuilder: (context, index) {
          final message = sortedNotifications[index];
          final timeAgo = timeago.format(message.sentTime!);

          return ListTile(
            title: Text(message.notification?.title ?? 'No Title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification?.body ?? 'No Body'),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailPage(message: message),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  final RemoteMessage? message;

  const NotificationDetailPage({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Detail'),
        centerTitle: true,
      ),
      body: Center(
        child: message != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Title: ${message?.notification?.title ?? 'No Title'}'),
            SizedBox(height: 10),
            Text('Body: ${message?.notification?.body ?? 'No Body'}'),
            SizedBox(height: 10),
            Text(
              'Received: ${timeago.format(message!.sentTime!)}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        )
            : Text('No notification available'),
      ),
    );
  }
}
