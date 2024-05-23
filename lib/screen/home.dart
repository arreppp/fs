import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'food_form.dart';
import 'foodDetail.dart';
import 'login.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key) {
    _stream = _reference.snapshots();
  }

  CollectionReference _reference = FirebaseFirestore.instance.collection('foods');
  late Stream<QuerySnapshot> _stream;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('FoodShare'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Stack(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user?.displayName ?? 'No username'),
                  accountEmail: Text(user?.email ?? 'No email'),
                  // currentAccountPicture: CircleAvatar(
                  //   child: Icon(Icons.account_circle, size: 50),
                  // ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                  ),
                ),
                Positioned(
                  bottom: 25,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => SettingsPage()),
                      // );
                    },
                  ),
                ),
              ],
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Map View'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.share_outlined),
              title: Text('Your Shared'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.fastfood_sharp),
              title: Text('Add Food'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FoodForm()),
                );
              },
            ),
            Column(
              children: <Widget>[
                Divider(),
                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Sign Out'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // Check error
          if (snapshot.hasError) {
            return Center(child: Text('Some error occurred ${snapshot.error}'));
          }

          // Check if data arrived
          if (snapshot.hasData) {
            // Get the data
            QuerySnapshot querySnapshot = snapshot.data;
            List<QueryDocumentSnapshot> documents = querySnapshot.docs;

            // Convert the documents to Maps
            List<Map> items = documents.map((e) => e.data() as Map).toList();

            // Display the list
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                // Get the item at this index
                Map thisItem = items[index];

                return FoodCard(data: thisItem, docId: documents[index].id);
              },
            );
          }

          // Show loader
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FoodForm()),
          );
        },
        child: const Icon(Icons.add),
        shape: CircleBorder(),
      ),
    );
  }
}

class FoodCard extends StatefulWidget {
  final Map data;
  final String docId;

  FoodCard({required this.data, required this.docId});

  @override
  _FoodCardState createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  late DateTime expiryTime;
  late Duration remainingTime;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    // Retrieve and set the expiry time
    Timestamp timestamp = widget.data['expiry_time'];
    expiryTime = timestamp.toDate();

    // Calculate the remaining time
    remainingTime = expiryTime.difference(DateTime.now());

    // Start the countdown timer
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        remainingTime = expiryTime.difference(DateTime.now());
        if (remainingTime.isNegative) {
          // Remove the item from Firestore
          FirebaseFirestore.instance.collection('foods').doc(widget.docId).delete();
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.data['name'] ?? 'No name provided';
    String quantity = widget.data['quantity'] ?? 'No quantity provided';
    String detail = widget.data['detail'] ?? 'No detail provided';
    String imageUrl = widget.data['image'] ?? 'https://example.com/default-image.jpg';
    String username = widget.data['username'] ?? 'Anonymous';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : AssetImage('assets/no_image.png') as ImageProvider,
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'by $username',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 5),
                CountdownTimer(duration: remainingTime),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailPage(
                    data: widget.data.map((key, value) => MapEntry(key.toString(), value ?? '')),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CountdownTimer extends StatelessWidget {
  final Duration duration;

  CountdownTimer({required this.duration});

  @override
  Widget build(BuildContext context) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Text(
        'Expires in: ${hours}h ${minutes}m ${seconds}s',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
    );
  }
}
