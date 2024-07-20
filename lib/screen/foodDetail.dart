import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'locationPicker.dart'; // Import this if you're using Firestore

class FoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  FoodDetailPage({required this.data});

  @override
  _FoodDetailPageState createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  bool isHoldButtonPressed = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DocumentReference? holdReference; // Reference to the hold document

  @override
  void initState() {
    super.initState();
    _checkHoldStatus();
  }

  Future<void> _checkHoldStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String email = user.email ?? 'No email provided';

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('holds')
          .where('foodName', isEqualTo: widget.data['name'])
          .where('user', isEqualTo: email)
          .where('status', isEqualTo: 'held')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          isHoldButtonPressed = true;
          holdReference = querySnapshot.docs.first.reference;
        });
      }
    }
  }

  Future<void> _handleHoldButton() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String email = user.email ?? 'No email provided';
      DateTime now = DateTime.now();

      if (isHoldButtonPressed) {
        // If the button is already pressed, release the hold and delete the document
        if (holdReference != null) {
          await holdReference!.delete();
          holdReference = null;
        }
      } else {
        // If the button is not pressed, hold the food and add a new document
        DocumentReference docRef = await FirebaseFirestore.instance.collection('holds').add({
          'foodName': widget.data['name'],
          'time': now,
          'user': email,
          'status': 'held',
        });
        holdReference = docRef;
      }

      setState(() {
        isHoldButtonPressed = !isHoldButtonPressed;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User not logged in'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
          },
        ),
      ),
      body: SingleChildScrollView(
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
              'Location: $location',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Expiry Time: $expiryTimeStr',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleHoldButton,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        isHoldButtonPressed ? Colors.red : Colors.green),
                  ),
                  child: Text(
                    isHoldButtonPressed ? 'Release' : 'Hold',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 20),
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
          ],
        ),
      ),
    );
  }
}
