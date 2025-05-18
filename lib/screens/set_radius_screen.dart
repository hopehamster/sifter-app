import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import 'create_room_screen.dart';

class SetRadiusScreen extends StatefulWidget {
  const SetRadiusScreen({super.key});

  @override
  State<SetRadiusScreen> createState() => _SetRadiusScreenState();
}

class _SetRadiusScreenState extends State<SetRadiusScreen> {
  LatLng? _currentPosition;
  double _chatRadius = 200; // 200 meters (~2 city blocks)
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final locationService = LocationService.instance;
    if (!locationService.isEnabled) {
      await locationService.requestLocationPermission();
    }
    
    final position = await locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } else {
      setState(() {
        _mapError = 'Failed to get location. Please enable location services.';
      });
    }
  }

  void _next() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load location. Please try again.')),
      );
      return;
    }
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
      appBar: AppBar(title: const Text('Set Chat Radius')),
      body: Column(
        children: [
          // Map Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6, // Responsive height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(50),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          // Controller is available if needed in the future
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('user_location'),
                            position: _currentPosition!,
                            infoWindow: const InfoWindow(title: 'Your Location'),
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: const CircleId('chat_radius'),
                            center: _currentPosition!,
                            radius: _chatRadius,
                            fillColor: const Color(0xFF2196F3).withAlpha(50),
                            strokeColor: const Color(0xFF2196F3),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          if (_mapError != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _mapError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}