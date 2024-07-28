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
import '../widgets/form_container_widget.dart';

class FoodForm extends StatefulWidget {
  @override
  _FoodFormState createState() => _FoodFormState();
}

class _FoodFormState extends State<FoodForm> {
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController foodQuantityController = TextEditingController();
  final TextEditingController foodDetailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
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
    fetchUserPhoneNumber();

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
          googleMapApiKey: 'AIzaSyC-MnxKfWoxF925Ve8pHVRzNEq9HOIAh-E',
        );
        setState(() {
          _address = data.address;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> fetchUserPhoneNumber() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            phoneController.text = userDoc['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user phone number: $e');
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = pickedDate;
          selectedTime = pickedTime;
        });
      }
    }
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
          'phone': phoneController.text,
          'timestamp': FieldValue.serverTimestamp(), // Add timestamp here
        };

        // Store data in 'foods' collection
        await FirebaseFirestore.instance.collection('foods').add(data);

        // Store data in 'history' collection
        await FirebaseFirestore.instance.collection('history').add(data);

        // Store notification data in 'notifications' collection
        var notificationData = {
          'title': 'New Post',
          'body': '$username shared ${foodNameController.text}  ',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'foodId': data['foodId'],
        };

        await FirebaseFirestore.instance.collection('notifications').add(notificationData);

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
        phoneController.clear();
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

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedImage = await picker.pickImage(source: ImageSource.gallery);
                  _handlePickedImage(pickedImage);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedImage = await picker.pickImage(source: ImageSource.camera);
                  _handlePickedImage(pickedImage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePickedImage(XFile? pickedImage) async {
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
        title: Text('Add Food'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: curLocation == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormContainerWidget(
              controller: foodNameController,
              hintText: 'Food Name',
              labelText: 'Food Name',
            ),
            SizedBox(height: 10),
            FormContainerWidget(
              controller: foodQuantityController,
              hintText: 'Quantity',
              labelText: 'Quantity',
              inputType: TextInputType.number,
            ),
            SizedBox(height: 10),
            FormContainerWidget(
              controller: foodDetailController,
              hintText: 'Details',
              labelText: 'Details',
            ),
            SizedBox(height: 10),
            FormContainerWidget(
              controller: phoneController,
              hintText: 'Phone Number',
              labelText: 'Phone Number',
              inputType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Upload Image'),
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 200.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                      initialCameraPosition: CameraPosition(
                        target: curLocation!,
                        zoom: 16,
                      ),
                      onCameraMove: (CameraPosition position) {
                        setState(() {
                          selectedLocation = position.target;
                          getAddressFromLatLng();
                        });
                      },
                    ),
                    Center(
                      child: Icon(Icons.location_pin, size: 40, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            if (_address != null)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Selected Location: $_address',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text('Select Expiry Date & Time'),
              onPressed: () => _selectDateTime(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text('Submit'),
              onPressed: _uploadData,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
