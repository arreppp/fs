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
                  currentAccountPicture: CircleAvatar(
                    child: Icon(Icons.account_circle, size: 50),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                  ),
                ),
                Positioned(
                  top: 6,
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
                // Return the widget for the list items
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
                            image: thisItem.containsKey('image') && thisItem['image'] != null && thisItem['image'].isNotEmpty
                                ? NetworkImage('${thisItem['image']}')
                                : AssetImage('assets/no_image.png') as ImageProvider,
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Row(
                          children: [
                            Text(
                              '${thisItem['name']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(width: 8), // Add some space between the name and username
                            Text(
                              'by ${thisItem['username']}',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        subtitle: Text(
                          'Quantity: ${thisItem['quantity']}',
                          style: TextStyle(fontSize: 16),
                        ),

                        trailing: Icon(Icons.arrow_forward_ios, size: 20),
                        onTap: () {
                          Map<String, dynamic> convertedData = thisItem.map((key, value) => MapEntry(key.toString(), value));
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FoodDetailPage(
                                data: thisItem.map((key, value) => MapEntry(key.toString(), value ?? '')),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
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
