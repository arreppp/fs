import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true, // Center the title
        automaticallyImplyLeading: false, // Remove back button

      ),
      body: Center(
        child: Text('Profile Content'),
      ),
    );
  }
}
