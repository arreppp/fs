import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

import 'locationPicker.dart';

class LocationDrop extends StatefulWidget {
  @override
  State<LocationDrop> createState() => _LocationDropState();
}

class _LocationDropState extends State<LocationDrop> {
  LatLng destLocation = LatLng(23.0525, 72.5667);
  loc.Location location = loc.Location();
  loc.LocationData? _currentPosition;
  final Completer<GoogleMapController> _controller = Completer();
  String? _address;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drop Point'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.navigate_next),
        onPressed: () {
          // Navigator.of(context).pushAndRemoveUntil(
          //   MaterialPageRoute(
          //     builder: (context) => LocationPicker(
          //         destLocation.latitude, destLocation.longitude),
          //   ),
          //       (route) => false,
          // );
        },
      ),
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: destLocation,
              zoom: 16,
            ),
            onCameraMove: (CameraPosition position) {
              if (destLocation != position.target) {
                setState(() {
                  destLocation = position.target;
                });
              }
            },
            onCameraIdle: () {
              getAddressFromLatLng();
            },
            onTap: (latLng) {
              print(latLng);
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
                'images/pick.png',
                height: 45,
                width: 45,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.white,
              ),
              padding: EdgeInsets.all(20),
              child: Text(
                _address ?? 'Pick the drop point',
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
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

    _currentPosition = await location.getLocation();
    setState(() {
      destLocation = LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!);
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: destLocation, zoom: 16),
    ));
    getAddressFromLatLng();
  }

  Future<void> getAddressFromLatLng() async {
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
        latitude: destLocation.latitude,
        longitude: destLocation.longitude,
        googleMapApiKey: 'AIzaSyBfOMormPiVpGpEp72CstQlYmiNomtwYU8',
      );
      setState(() {
        _address = data.address;
      });
    } catch (e) {
      print(e);
    }
  }
}
