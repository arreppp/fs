import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true, // Center the title
        automaticallyImplyLeading: false, // Remove back button

      ),
      body: Center(
        child: Text('Notifications Content'),
      ),
    );
  }
}
