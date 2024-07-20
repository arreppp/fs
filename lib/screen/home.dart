import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fs/screen/mapView.dart';
import 'package:fs/screen/notiPage.dart';
import 'package:fs/screen/profile.dart';
import 'food_form.dart';
import 'foodDetail.dart';
import 'login.dart';
import 'bottomNav.dart';  // Import the bottom navigation bar

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _stream;
  final CollectionReference _reference = FirebaseFirestore.instance.collection('foods');

  @override
  void initState() {
    super.initState();
    _stream = _reference.snapshots();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return Scaffold(); // Or some appropriate widget to display while navigating
    }

    final List<Widget> _pages = [
      StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Some error occurred ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            QuerySnapshot querySnapshot = snapshot.data;
            List<QueryDocumentSnapshot> documents = querySnapshot.docs;
            List<Map> items = documents.map((e) => e.data() as Map).toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                        Map thisItem = items[index];
                        return FoodCard(data: thisItem, docId: documents[index].id);
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
      MapViewPage(),
      FoodForm(),
      NotificationsPage(),
      ProfilePage(userId: user.uid, email: user.email!), // Pass the userId here
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: Text(
          'FoodShare',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // Center the title
        automaticallyImplyLeading: false, // Remove back button
      )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
  Timer? timer;

  @override
  void initState() {
    super.initState();
    Timestamp timestamp = widget.data['expiry_time'];
    expiryTime = timestamp.toDate();
    remainingTime = expiryTime.difference(DateTime.now());

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        remainingTime = expiryTime.difference(DateTime.now());
        if (remainingTime.isNegative) {
          FirebaseFirestore.instance.collection('foods').doc(widget.docId).delete();
          timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
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
                      fontSize: 16),
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
    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Text(
        'Expires in: ${days}d ${hours}h ${minutes}m ${seconds}s',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
    );
  }
}
