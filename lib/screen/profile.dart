import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SettingPage.dart';
import 'foodDetail.dart';

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
      print("Fetching data for userId: ${widget.userId}");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        print("User data: ${userDoc.data()}");

        setState(() {
          username = userDoc['username'];
          email = userDoc['email'];
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
      print("Error fetching user data: $e");
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

        setState(() {
          previousSharedFood = foodList;
        });
      } else {
        showProfileToast(message: "No previous shared food found.");
      }
    } catch (e) {
      print("Error fetching previous shared food: $e");
      showProfileToast(message: "Error fetching previous shared food: $e");
    }
  }

  Future<void> fetchPreviousHolds() async {
    try {
      QuerySnapshot holdSnapshot = await FirebaseFirestore.instance
          .collection('holds')
          .where('user', isEqualTo: widget.email)
          .where('status', isEqualTo: 'held')
          .get();

      if (holdSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> holdList = holdSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        setState(() {
          previousHolds = holdList;
        });
      }
    } catch (e) {
      print("Error fetching previous holds: $e");
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
        title: Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to the settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
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
                            builder: (context) => FoodDetailPage(data: food),
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
                      subtitle: Text('Held at: ${hold['time'].toDate()}'),
                      //trailing: Text('Status: ${hold['status']}'),
                      onTap: () async {
                        // Fetch detailed data for the food item based on its name
                        QuerySnapshot foodSnapshot = await FirebaseFirestore.instance
                            .collection('history')
                            .where('name', isEqualTo: hold['foodName'])
                            .get();

                        if (foodSnapshot.docs.isNotEmpty) {
                          // Assuming the first document is the relevant one
                          Map<String, dynamic> foodData = foodSnapshot.docs.first.data() as Map<String, dynamic>;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailPage(data: foodData),
                            ),
                          );
                        } else {
                          showProfileToast(message: "Food details not found.");
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
                  foregroundColor: Colors.white, backgroundColor: Colors.red,
                ),
                child: Text('Sign Out'),

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
