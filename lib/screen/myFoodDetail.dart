import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'locationPicker.dart'; // Add this import for launching the call

class MyFoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  MyFoodDetailPage({required this.data});

  @override
  _MyFoodDetailPageState createState() => _MyFoodDetailPageState();
}

class _MyFoodDetailPageState extends State<MyFoodDetailPage> {
  bool isHoldButtonPressed = false;
  DocumentReference? holdReference; // Reference to the hold document
  List<Map<String, String>> holders = [];

  @override
  void initState() {
    super.initState();
    _getHolders();
  }

  Future<void> _getHolders() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('holds')
        .where('foodName', isEqualTo: widget.data['name'])
        .where('status', isEqualTo: 'held')
        .get();

    List<String> emails = querySnapshot.docs.map((doc) {
      return doc['holder'] as String? ?? 'Unknown';
    }).toList();

    List<Map<String, String>> fetchedHolders = [];

    for (String email in emails) {
      Map<String, String> holderInfo = await _getUserInfoByEmail(email);
      fetchedHolders.add(holderInfo);
    }

    setState(() {
      holders = fetchedHolders;
    });
  }

  Future<Map<String, String>> _getUserInfoByEmail(String email) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var userDoc = querySnapshot.docs.first;
      return {
        'username': userDoc['username'] ?? 'Unknown',
        'phone': userDoc['phone'] ?? 'Unknown',
      };
    } else {
      return {
        'username': 'Unknown',
        'phone': 'Unknown',
      };
    }
  }

  Future<void> _handleDeleteFood() async {
    try {
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.data['id']) // Assuming 'id' is a part of the data map
          .delete();

      Navigator.pop(context); // Return to the previous screen after deletion

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Food item deleted successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete food item: $e'),
      ));
    }
  }

  void _callPhoneNumber(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not launch phone call'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide default values or handle null values
    String name = widget.data['name'] ?? 'No name provided';
    String detail = widget.data['detail'] ?? 'No detail provided';
    String imageUrl = widget.data['image'] ?? 'https://example.com/default-image.jpg'; // Provide a default image URL if image is null

    // Handle GeoPoint for location
    double? lat;
    double? lng;
    String location;
    if (widget.data['location'] is GeoPoint) {
      GeoPoint geoPoint = widget.data['location'];
      lat = geoPoint.latitude;
      lng = geoPoint.longitude;
      location = 'Lat: ${geoPoint.latitude}, Lon: ${geoPoint.longitude}';
    } else {
      location = widget.data['location'] ?? 'No location provided';
    }

    // Handle expiry time
    DateTime? expiryTime;
    String expiryTimeStr = 'No expiry time provided';
    if (widget.data['expiry_time'] != null) {
      expiryTime = (widget.data['expiry_time'] as Timestamp).toDate();
      expiryTimeStr = '${expiryTime.toLocal()}'.split('.')[0]; // Format the expiry time
    }

    // Store quantity as String
    String quantityString = widget.data['quantity'] ?? '0';
    // Parse quantity as int, default to 0 if parsing fails
    int quantity = int.tryParse(quantityString) ?? 0;

    String username = widget.data['username'] ?? 'Unknown'; // Handle missing username

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail'),
        centerTitle: true,
        automaticallyImplyLeading: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'delete') {
                _handleDeleteFood();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            imageUrl.isNotEmpty ? Image.network(imageUrl) : Container(), // Handle empty image URL
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                Text(
                  'by $username',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
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
              'Coordinate: $location',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Best Before : $expiryTimeStr',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (lat != null && lng != null) {
                      // Navigate to LocationPicker with the destination coordinates
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LocationPicker(lat!, lng!, data: widget.data),
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
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Users holding this food:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: holders.length,
              itemBuilder: (context, index) {
                final holder = holders[index];
                return ListTile(
                  title: Text(holder['username'] ?? 'Unknown'),
                  subtitle: GestureDetector(
                    onTap: () {
                      if (holder['phone'] != 'Unknown') {
                        _callPhoneNumber(holder['phone']!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Phone number not available'),
                        ));
                      }
                    },
                    child: Text(
                      holder['phone'] ?? 'Unknown',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
