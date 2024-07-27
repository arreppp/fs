import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'locationPicker.dart'; // Import this if you're using Firestore

class MyFoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  MyFoodDetailPage({required this.data});

  @override
  _MyFoodDetailPageState createState() => _MyFoodDetailPageState();
}

class _MyFoodDetailPageState extends State<MyFoodDetailPage> {
  bool isHoldButtonPressed = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DocumentReference? holdReference; // Reference to the hold document
  List<String> holders = [];

  @override
  void initState() {
    super.initState();
    _checkHoldStatus();
    _getHolders();
  }

  Future<void> _checkHoldStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String email = user.email ?? 'No email provided';

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('holds')
          .where('foodName', isEqualTo: widget.data['name'])
          .where('holder', isEqualTo: email)
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

  Future<void> _getHolders() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('holds')
        .where('foodName', isEqualTo: widget.data['name'])
        .where('status', isEqualTo: 'held')
        .get();

    List<String> emails = querySnapshot.docs.map((doc) {
      return doc['holder'] as String? ?? 'Unknown';
    }).toList();

    List<String> fetchedHolders = [];

    for (String email in emails) {
      String username = await _getUsernameByEmail(email);
      fetchedHolders.add(username);
    }

    setState(() {
      holders = fetchedHolders;
    });
  }

  Future<String> _getUsernameByEmail(String email) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first['username'] ?? 'Unknown';
    } else {
      return 'Unknown';
    }
  }

  Future<void> _handleHoldButton() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String email = user.email ?? 'No email provided';
      String username = await _getUsernameByEmail(email);
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
          'holder': email,
          'status': 'held',
        });
        holdReference = docRef;
      }

      setState(() {
        isHoldButtonPressed = !isHoldButtonPressed;
      });

      _getHolders(); // Update the list of holders
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User not logged in'),
      ));
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
                return ListTile(
                  title: Text(holders[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
