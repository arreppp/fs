import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'locationPicker.dart'; // Import this if you're using Firestore

class FoodDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  FoodDetailPage({required this.data});

  @override
  Widget build(BuildContext context) {
    // Provide default values or handle null values
    String name = data['name'] ?? 'No name provided';
    String quantity = data['quantity'] ?? 'No quantity provided';
    String detail = data['detail'] ?? 'No detail provided';
    String imageUrl = data['image'] ?? 'https://example.com/default-image.jpg'; // Provide a default image URL if image is null

    // Handle GeoPoint for location
    double? lat;
    double? lng;
    String location;
    if (data['location'] is GeoPoint) {
      GeoPoint geoPoint = data['location'];
      lat = geoPoint.latitude;
      lng = geoPoint.longitude;
      location = 'Lat: ${geoPoint.latitude}, Lon: ${geoPoint.longitude}';
    } else {
      location = data['location'] ?? 'No location provided';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('FoodShare'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
          },
        ),
      ),
      body: SingleChildScrollView( // Wrap the body with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(fontSize: 20),
            ),
            imageUrl.isNotEmpty ? Image.network(imageUrl) : Container(), // Handle empty image URL

            SizedBox(height: 10),
            Text(
              'Quantity: $quantity',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              detail,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              location,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20), // Add some space before the button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (lat != null && lng != null) {
                    // Navigate to LocationPicker with the destination coordinates
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPicker(lat!, lng!, data: data),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Location data is not available'),
                    ));
                  }
                },
                child: Text('Navigate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
