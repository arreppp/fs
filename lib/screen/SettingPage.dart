import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        automaticallyImplyLeading: true, // Show back button
      ),
      body: Center(
        child: Text('Settings Page'),
      ),
    );
  }
}
