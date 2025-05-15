import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sifter/screens/chat/create_room_screen.dart';
import '../services/location_service.dart';
// import 'create_room_screen.dart';

class SetRadiusScreen extends StatefulWidget {
  @override
  _SetRadiusScreenState createState() => _SetRadiusScreenState();
}

class _SetRadiusScreenState extends State<SetRadiusScreen> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  double _chatRadius = 200; // 200 meters (~2 city blocks)

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool locationEnabled = await LocationService.isLocationEnabled();
    if (!locationEnabled) {
      await LocationService.enableLocation();
    }
    final locationData = await LocationService().location.getLocation();
    setState(() {
      _currentPosition =
          LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRoomScreen(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radius: _chatRadius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Chat Radius')),
      body: Column(
        children: [
          // Map Section
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _currentPosition == null
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        markers: {
                          Marker(
                            markerId: MarkerId('user_location'),
                            position: _currentPosition!,
                            infoWindow: InfoWindow(title: 'Your Location'),
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: CircleId('chat_radius'),
                            center: _currentPosition!,
                            radius: _chatRadius,
                            fillColor: Color(0xFF2196F3).withOpacity(0.2),
                            strokeColor: Color(0xFF2196F3),
                            strokeWidth: 2,
                          ),
                        },
                        myLocationEnabled: true,
                      ),
              ),
            ),
          ),
          // Radius Slider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chat Radius: ${_chatRadius.toInt()} meters'),
                Slider(
                  value: _chatRadius,
                  min: 50,
                  max: 500,
                  divisions: 9,
                  label: '${_chatRadius.toInt()} m',
                  onChanged: (value) {
                    setState(() {
                      _chatRadius = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
