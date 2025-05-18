import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_room.dart';
import '../services/room_service.dart';
import 'chat_screen.dart';

class MapDiscoveryScreen extends ConsumerStatefulWidget {
  const MapDiscoveryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends ConsumerState<MapDiscoveryScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<ChatRoom> _rooms = [];
  bool _isLoading = true;
  Position? _currentPosition;
  
  // Default position (San Francisco)
  final CameraPosition _defaultPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _checkMapEnabled();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkMapEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final mapEnabled = prefs.getBool('map_view_enabled') ?? false;
    if (!mapEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Map view is disabled. Enable it in Settings.')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
        );
      }
      
      await _fetchNearbyRooms(position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
      
      // Log error (removed Sentry)
      print('Error getting location: $e');
      
      // Use default position and try to get rooms anyway
      await _fetchNearbyRooms(null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyRooms(Position? position) async {
    try {
      final roomService = ref.read(roomServiceProvider);
      
      // Use current position or default if unavailable
      final latitude = position?.latitude ?? 37.7749;
      final longitude = position?.longitude ?? -122.4194;
      
      // Get rooms within 5km (we'll filter to 500m in the UI)
      final nearbyRooms = await roomService.getNearbyRooms(latitude, longitude, 5.0);
      
      setState(() {
        _rooms = nearbyRooms;
        _updateMarkers();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rooms: $e')),
      );
      
      // Log error (removed Sentry)
      print('Error fetching rooms: $e');
    }
  }

  void _updateMarkers() {
    // Clear existing markers
    setState(() {
      _markers.clear();
      _circles.clear();
      
      // Add marker for current position
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      }
      
      // Add markers for each room
      for (final room in _rooms) {
        final markerColor = room.isNsfw 
            ? BitmapDescriptor.hueRed
            : (room.isPasswordProtected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueGreen);
            
        _markers.add(
          Marker(
            markerId: MarkerId(room.id),
            position: LatLng(room.latitude, room.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            infoWindow: InfoWindow(
              title: room.name,
              snippet: room.description ?? 'Tap to join this chat',
              onTap: () => _openRoomDetails(room),
            ),
          ),
        );
        
        // Visual representation of room radius
        _circles.add(
          Circle(
            circleId: CircleId('circle_${room.id}'),
            center: LatLng(room.latitude, room.longitude),
            radius: room.radius * 1000, // Convert km to meters
            strokeColor: Colors.green.withOpacity(0.8),
            strokeWidth: 2,
            fillColor: Colors.green.withOpacity(0.2),
          ),
        );
      }
    });
  }

  void _openRoomDetails(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(roomId: room.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _getCurrentLocation(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            markers: _markers,
            circles: _circles,
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
              
              // Move camera to current position if available
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  ),
                );
              }
              
              _updateMarkers();
            },
          ),
          if (_isLoading)
            const Center(
              child: Card(
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nearby Chats: ${_rooms.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _markerLegendItem(
                          color: Colors.green, 
                          label: 'Public Rooms',
                        ),
                        _markerLegendItem(
                          color: Colors.purple, 
                          label: 'Password Protected',
                        ),
                        _markerLegendItem(
                          color: Colors.red, 
                          label: 'NSFW Content',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
        tooltip: 'Find nearby chats',
      ),
    );
  }
  
  Widget _markerLegendItem({required Color color, required String label}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 