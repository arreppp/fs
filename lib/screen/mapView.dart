import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'foodDetail.dart';
import 'myFoodDetail.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapViewPage(),
    );
  }
}

class MapViewPage extends StatefulWidget {
  @override
  _MapViewPageState createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late GoogleMapController _mapController;
  Location _location = Location();
  LatLng _initialPosition = LatLng(37.7749, -122.4194); // Default to San Francisco
  Set<Marker> _markers = {};
  bool _mapLoaded = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _fetchFoodLocations();
  }

  Future<void> _getLocationPermission() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData _locationData = await _location.getLocation();
    setState(() {
      _initialPosition = LatLng(_locationData.latitude!, _locationData.longitude!);
      _mapLoaded = true;
    });

    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_mapLoaded) {
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
          ),
        );
      }
    });
  }

  Future<void> _fetchFoodLocations() async {
    FirebaseFirestore.instance.collection('foods').get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as GeoPoint;
        final lat = location.latitude;
        final lng = location.longitude;
        final markerId = doc.id;

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(markerId),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: data['name'] ?? 'Food Location',
                snippet: 'Quantity: ${data['quantity']}',
                onTap: () async {
                  User? user = _auth.currentUser;
                  if (user != null) {
                    String email = user.email ?? '';
                    String username = user.displayName ?? '';

                    if (email == data['email'] && username == data['username']) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyFoodDetailPage(data: data),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodDetailPage(data: data),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map View'),
        centerTitle: true,
        backgroundColor: Color(0xFFc9cfcc),

      ),

      body: _mapLoaded
          ? GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12, // Adjusted zoom level to 12 for a better map view
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      )
          : Center(child: CircularProgressIndicator()), // Show loading indicator until map is loaded
    );
  }
}
