import 'package:flutter/material.dart';

class MapViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map View'),
        centerTitle: true, // Center the title
        automaticallyImplyLeading: false, // Remove back button

      ),
      body: Center(
        child: Text('Map View Content'),
      ),
    );
  }
}
