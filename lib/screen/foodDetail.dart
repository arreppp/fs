import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'locationPicker.dart';

class FoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  FoodDetailPage({required this.data});

  @override
  _FoodDetailPageState createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  bool isHoldButtonPressed = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DocumentReference? holdReference;
  String? phoneNumber;
  List<Map<String, String>> holders = [];


  @override
  void initState() {
    super.initState();
    _checkHoldStatus();
    _fetchPhoneNumber();
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
      } else {
        setState(() {
          isHoldButtonPressed = false;
          holdReference = null;
        });
      }
    }
  }

  Future<void> _fetchPhoneNumber() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('name', isEqualTo: widget.data['name'])
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        phoneNumber = querySnapshot.docs.first.get('phone');
      });
    }
  }

  Future<void> _getHolders() async {
    int quantity = int.tryParse(widget.data['quantity'] ?? '0') ?? 0;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('holds')
        .where('foodName', isEqualTo: widget.data['name'])
        .where('status', isEqualTo: 'held')
        .limit(quantity)
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



  Future<void> _handleHoldButton() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String email = user.email ?? 'No email provided';
      DateTime now = DateTime.now();

      if (isHoldButtonPressed) {
        if (holdReference != null) {
          await holdReference!.delete();
          holdReference = null;
        }
      } else {
        DocumentReference docRef = await FirebaseFirestore.instance.collection('holds').add({
          'foodName': widget.data['name'],
          'timestamp': now,
          'holder': email,
          'status': 'held',
        });
        holdReference = docRef;
      }

      setState(() {
        isHoldButtonPressed = !isHoldButtonPressed;
      });

      _getHolders(); // Update holders list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User not logged in'),
      ));
    }
  }
  Future<void> _reportFood() async {
    User? user = _auth.currentUser;
    if (user != null) {
      TextEditingController _reasonController = TextEditingController();

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Report Food'),
            content: TextField(
              controller: _reasonController,
              decoration: InputDecoration(hintText: "Enter reason for reporting"),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  String reason = _reasonController.text;
                  if (reason.isNotEmpty) {
                    DateTime now = DateTime.now();
                    await FirebaseFirestore.instance.collection('reports').add({
                      'reporter': user.email ?? 'Unknown',
                      'reason': reason,
                      'time': now,
                      'foodName': widget.data['name'],
                      'username': widget.data['username'] ?? 'Unknown',
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Report submitted'),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Reason cannot be empty'),
                    ));
                  }
                },
                child: Text('Submit'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User not logged in'),
      ));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.data['name'] ?? 'No name provided';
    String detail = widget.data['detail'] ?? 'No detail provided';
    String imageUrl = widget.data['image'] ?? 'https://example.com/default-image.jpg';

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

    DateTime? expiryTime;
    String expiryTimeStr = 'No expiry time provided';
    if (widget.data['expiry_time'] != null) {
      expiryTime = (widget.data['expiry_time'] as Timestamp).toDate();
      expiryTimeStr = '${expiryTime.toLocal()}'.split('.')[0];
    }

    String quantityString = widget.data['quantity'] ?? '0';
    int quantity = int.tryParse(quantityString) ?? 0;
    String username = widget.data['username'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail', style: TextStyle(color: Color(0xFF758467))),
        centerTitle: true,
        automaticallyImplyLeading: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Report') {
                _reportFood();
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Report'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFdfe6da),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: double.infinity, // Make the image take the full width
              height: 200, // Set a fixed height for all images
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover, // Ensure the image covers the box while maintaining aspect ratio
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text('Image not available')); // Placeholder in case of an error
                },
              ),
            ),
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
              'Location: $location',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Best Before : $expiryTimeStr',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            //if (phoneNumber != null)
            // GestureDetector(
            //   onTap: () => _makePhoneCall(phoneNumber!),
            //   child: Text(
            //     'Phone: $phoneNumber',
            //     style: TextStyle(
            //       fontSize: 16,
            //       color: Colors.blue,
            //       decoration: TextDecoration.underline,
            //     ),
            //   ),
            // ),
            SizedBox(height: 20),
            Column(
              children: [
                if (phoneNumber != null)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _makePhoneCall(phoneNumber!),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Call'),
                    ),
                  ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: _handleHoldButton,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: isHoldButtonPressed ? Colors.red : Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isHoldButtonPressed ? 'Release' : 'Hold'),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (lat != null && lng != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPicker(lat!, lng!, data: widget.data),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Location data is not available'),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Navigate'),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Current Holders:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                for (var holder in holders)
                  ListTile(
                    title: Text(holder['username'] ?? 'Unknown'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

