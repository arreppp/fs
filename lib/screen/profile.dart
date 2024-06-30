import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchPreviousSharedFood();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
