import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fs/screen/mapView.dart';
import 'package:fs/screen/notiPage.dart';
import 'package:fs/screen/profile.dart';
import 'food_form.dart';
import 'foodDetail.dart';
import 'myFoodDetail.dart';
import 'login.dart';
import 'bottomNav.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _stream;
  final CollectionReference _reference = FirebaseFirestore.instance.collection('foods');
  String? currentUserUsername;
  String _sortOption = 'Newest';

  @override
  void initState() {
    super.initState();
    _stream = _reference.snapshots();
    _getCurrentUserUsername();
  }

  Future<void> _getCurrentUserUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        currentUserUsername = userDoc['username'];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSortOptionChanged(String? value) {
    setState(() {
      _sortOption = value!;
    });
  }

  List<Map> _sortItems(List<Map> items) {
    if (_sortOption == 'Newest') {
      items.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    } else if (_sortOption == 'Earliest Expiry') {
      items.sort((a, b) => (a['expiry_time'] as Timestamp).compareTo(b['expiry_time'] as Timestamp));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return Scaffold();
    }

    final List<Widget> _pages = [
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: _sortOption,
                onChanged: _onSortOptionChanged,
                items: [
                  DropdownMenuItem(
                    value: 'Newest',
                    child: Text('Newest'),
                  ),
                  DropdownMenuItem(
                    value: 'Earliest Expiry',
                    child: Text('Earliest Expiry'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Some error occurred ${snapshot.error}'));
                }

                if (snapshot.hasData) {
                  QuerySnapshot querySnapshot = snapshot.data;
                  List<QueryDocumentSnapshot> documents = querySnapshot.docs;
                  List<Map> items = documents.map((e) => e.data() as Map).toList();
                  items = _sortItems(items);

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                              Map thisItem = items[index];
                              return FoodCard(data: thisItem, docId: documents[index].id, currentUserUsername: currentUserUsername);
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
          ),
        ],
      ),
      MapViewPage(),
      FoodForm(),
      NotificationsPage(),
      ProfilePage(userId: user.uid, email: user.email!),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: Text(
          'FoodShare',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
  final String? currentUserUsername;

  FoodCard({required this.data, required this.docId, this.currentUserUsername});

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

    return InkWell(
      onTap: () {
        if (widget.currentUserUsername == username) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyFoodDetailPage(
                data: widget.data.map((key, value) => MapEntry(key.toString(), value ?? '')),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetailPage(
                data: widget.data.map((key, value) => MapEntry(key.toString(), value ?? '')),
              ),
            ),
          );
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        elevation: 3,
        child: Row(
          children: [
            Container(
              height: 100,
              width: 100,
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
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
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
              ),
            ),
          ],
        ),
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
        '${days}d ${hours}h ${minutes}m ${seconds}s',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
    );
  }
}
