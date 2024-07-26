import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoder2/geocoder2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FoodForm extends StatefulWidget {
  @override
  _FoodFormState createState() => _FoodFormState();
}

class _FoodFormState extends State<FoodForm> {
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController foodQuantityController = TextEditingController();
  final TextEditingController foodDetailController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();

  String imageUrl = '';
  LatLng? selectedLocation;
  loc.Location location = loc.Location();
  final Completer<GoogleMapController> _controller = Completer();
  String? _address;
  LatLng? curLocation;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    getCurrentLocation();

    FirebaseMessaging.instance.subscribeToTopic('new_post');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title!),
            content: Text(notification.body!),
          ),
        );
      }
    });
  }

  Future<void> getCurrentLocation() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    var _currentPosition = await location.getLocation();
    setState(() {
      curLocation = LatLng(_currentPosition.latitude!, _currentPosition.longitude!);
      selectedLocation = curLocation;
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: curLocation!, zoom: 16),
    ));
    getAddressFromLatLng();
  }

  Future<void> getAddressFromLatLng() async {
    try {
      if (curLocation != null) {
        GeoData data = await Geocoder2.getDataFromCoordinates(
          latitude: curLocation!.latitude,
          longitude: curLocation!.longitude,
          googleMapApiKey: 'AIzaSyBfOMormPiVpGpEp72CstQlYmiNomtwYU8',
        );
        setState(() {
          _address = data.address;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != selectedDate)
      setState(() {
        selectedDate = pickedDate;
      });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != selectedTime)
      setState(() {
        selectedTime = pickedTime;
      });
  }

  Future<void> _uploadData() async {
    if (imageUrl.isEmpty || selectedLocation == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please upload an image, select a location, date, and time'),
      ));
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? username;
        String email = user.email!;

        // Fetch the username from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          username = userDoc['username'];
        }

        DateTime expiryDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );

        var data = {
          'name': foodNameController.text,
          'quantity': foodQuantityController.text,
          'detail': foodDetailController.text,
          'expiry_time': expiryDateTime,
          'image': imageUrl,
          'location': GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude),
          'username': username,
          'email': email,
        };

        // Store data in 'foods' collection
        await FirebaseFirestore.instance.collection('foods').add(data);

        // Store data in 'history' collection
        await FirebaseFirestore.instance.collection('history').add(data);

        FirebaseMessaging.instance.subscribeToTopic('new_post');

        const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'high_importance_channel', 'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
        const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
            0, 'New Post', 'A new post has been added by $username', platformChannelSpecifics);

        foodNameController.clear();
        foodQuantityController.clear();
        foodDetailController.clear();
        latController.clear();
        lngController.clear();
        setState(() {
          selectedDate = null;
          selectedTime = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Food added successfully'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User not logged in'),
        ));
      }
    } catch (error) {
      print('Error uploading food data: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to upload food data'),
      ));
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage == null) return;

    try {
      final file = File(pickedImage.path);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final storageRef = FirebaseStorage.instance.ref().child('images/$fileName.jpg');

      final uploadTask = storageRef.putFile(file);

      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        this.imageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Image uploaded successfully'),
      ));
    } catch (error) {
      print('Error uploading image: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to upload image'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Food'),
        centerTitle: true, // Center the title
        automaticallyImplyLeading: false, // Remove back button

      ),
      body: curLocation == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: foodNameController,
              decoration: InputDecoration(labelText: 'Food Name'),
            ),
            TextField(
              controller: foodQuantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: foodDetailController,
              decoration: InputDecoration(labelText: 'Detail'),
              maxLines: null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Expiry Date'),
            ),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: Text('Select Expiry Time'),
            ),
            SizedBox(height: 20),
            Text(
              selectedDate == null ? 'No Date Chosen!' : 'Picked Date: ${selectedDate!.toLocal()}'.split(' ')[0],
            ),
            Text(
              selectedTime == null ? 'No Time Chosen!' : 'Picked Time: ${selectedTime!.format(context)}',
            ),
            SizedBox(height: 20),
            Text('Pick Location:'),
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    initialCameraPosition: CameraPosition(
                      target: curLocation!,
                      zoom: 16,
                    ),
                    onCameraMove: (CameraPosition position) {
                      if (selectedLocation != position.target) {
                        setState(() {
                          selectedLocation = position.target;
                          latController.text = selectedLocation!.latitude.toString();
                          lngController.text = selectedLocation!.longitude.toString();
                        });
                      }
                    },
                    onCameraIdle: () {
                      getAddressFromLatLng();
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 35.0),
                      child: Image.asset(
                        'images/redpick.png',
                        height: 35,
                        width: 35,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    left: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(10),
                      child: Text(
                        _address ?? 'Pick location',
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadData,
              child: Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}

