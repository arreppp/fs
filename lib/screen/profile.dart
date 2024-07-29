import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SettingPage.dart';
import 'foodDetail.dart';
import 'myFoodDetail.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String email;

  ProfilePage({required this.userId, required this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "";
  String email = "";
  String phone = ""; // Add phone variable

  bool isLoading = true;
  List<Map<String, dynamic>> previousSharedFood = [];
  List<Map<String, dynamic>> previousHolds = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchPreviousSharedFood();
    fetchPreviousHolds();
  }

  Future<void> fetchUserData() async {
    if (widget.userId.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'];
          email = userDoc['email'];
          phone = userDoc['phone'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        showProfileToast(message: "User data not found.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showProfileToast(message: "Error fetching user data: $e");
    }
  }

  Future<void> fetchPreviousSharedFood() async {
    try {
      QuerySnapshot foodSnapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('email', isEqualTo: widget.email)
          .get();

      if (foodSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> foodList = foodSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Sort in descending order to have the newest at the top
        foodList.sort((a, b) {
          Timestamp timeA = a['timestamp'] as Timestamp;
          Timestamp timeB = b['timestamp'] as Timestamp;
          return timeB.compareTo(timeA);
        });

        setState(() {
          previousSharedFood = foodList;
        });
      }
    } catch (e) {
      showProfileToast(message: "Error fetching previous shared food: $e");
    }
  }

  Future<void> fetchPreviousHolds() async {
    try {
      QuerySnapshot holdSnapshot = await FirebaseFirestore.instance
          .collection('holds')
          .where('holder', isEqualTo: widget.email)
          .where('status', isEqualTo: 'held')
          .get();

      if (holdSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> holdList = holdSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        List<Map<String, dynamic>> filteredHoldList = [];

        for (var hold in holdList) {
          QuerySnapshot foodSnapshot = await FirebaseFirestore.instance
              .collection('foods')
              .where('name', isEqualTo: hold['foodName'])
              .get();

          if (foodSnapshot.docs.isNotEmpty) {
            filteredHoldList.add(hold);
          }
        }

        // Sort in ascending order to have the newest at the bottom
        filteredHoldList.sort((a, b) {
          Timestamp timeA = a['timestamp'] as Timestamp;
          Timestamp timeB = b['timestamp'] as Timestamp;
          return timeA.compareTo(timeB);
        });

        setState(() {
          previousHolds = filteredHoldList;
        });
      }
    } catch (e) {
      showProfileToast(message: "Error fetching previous holds: $e");
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Assuming you have a named route for the login page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Color(0xFF758467))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    userId: widget.userId,
                    currentUsername: username,
                    currentEmail: email,
                    currentPhoneNumber: phone, // Pass phone number to SettingsPage
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  fetchUserData();
                }
              });
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFdfe6da),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF819171),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$username',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$email',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$phone',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'My Previous Shared',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: previousSharedFood.length,
                itemBuilder: (context, index) {
                  final food = previousSharedFood[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(food['name']),
                      subtitle: Text(food['detail']),
                      trailing: Text('Qty: ${food['quantity']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyFoodDetailPage(data: food),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'My Holds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: previousHolds.length,
                itemBuilder: (context, index) {
                  final hold = previousHolds[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(hold['foodName']),
                      subtitle: Text(
                          'Held at: ${hold['timestamp'] != null ? (hold['timestamp'] as Timestamp).toDate().toString() : 'Unknown time'}'),
                      onTap: () async {
                        QuerySnapshot foodSnapshot = await FirebaseFirestore
                            .instance
                            .collection('foods')
                            .where('name',
                            isEqualTo: hold['foodName'])
                            .get();

                        if (foodSnapshot.docs.isNotEmpty) {
                          Map<String, dynamic> foodData =
                          foodSnapshot.docs.first.data()
                          as Map<String, dynamic>;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FoodDetailPage(data: foodData),
                            ),
                          );
                        } else {
                          showProfileToast(
                              message: "Food details not found.");
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showProfileToast({required String message}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
