import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'foodDetail.dart';

class NotificationsPage extends StatelessWidget {
  static const route = '/notification';

  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Color(0xFF758467))),
        centerTitle: true,

      ),
      backgroundColor: Color(0xFFdfe6da),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications available'));
          }

          final notifications = snapshot.data!.docs;
          notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final title = notification['title'] ?? 'No Title';
              final body = notification['body'] ?? 'No Body';
              final timestamp = (notification['timestamp'] as Timestamp).toDate();
              final timeAgo = timeago.format(timestamp);

              return ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body),
                    Text(
                      timeAgo,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => FoodDetailPage(
                //         title: title,
                //         body: body,
                //         timestamp: timestamp,
                //       ),
                //     ),
                //   );
                // },
              );
            },
          );
        },
      ),
    );
  }
}
