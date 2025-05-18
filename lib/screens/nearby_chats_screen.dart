import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/chat_room.dart';
import '../services/location_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'create_room_screen.dart';
import 'dart:async';

class NearbyChatsScreen extends ConsumerStatefulWidget {
  const NearbyChatsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyChatsScreen> createState() => _NearbyChatsScreenState();
}

class _NearbyChatsScreenState extends ConsumerState<NearbyChatsScreen> {
  List<ChatRoom> _nearbyRooms = [];
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Default radius for fetching nearby rooms (maximum range of 500 meters per SRS)
  static const double MAX_RADIUS_KM = 0.5; // 500 meters
  
  // Timer for periodic updates
  Timer? _locationUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Set up periodic location updates every 30 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getCurrentLocation(silent: true);
    });
  }
  
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation({bool silent = false}) async {
    // Only show loading indicator for manual refreshes
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        _fetchNearbyChats(silent: silent);
      } else {
        // Only request permission for manual refreshes
        if (!silent) {
          // Request permission and try again
          final permissionGranted = await locationService.requestLocationPermission();
          
          if (permissionGranted) {
            final retryPosition = await locationService.getCurrentLocation();
            setState(() {
              _currentPosition = retryPosition;
              if (retryPosition == null) {
                _errorMessage = 'Could not get your location. Please enable location services.';
                _isLoading = false;
              }
            });
            
            if (retryPosition != null) {
              _fetchNearbyChats();
            }
          } else {
            setState(() {
              _errorMessage = 'Location permission denied. You need location access to see nearby chats.';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _errorMessage = 'Error accessing location: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _fetchNearbyChats({bool silent = false}) async {
    if (_currentPosition == null) return;
    
    try {
      final chatService = ref.read(chatServiceProvider);
      
      // Get all chat rooms within the maximum radius defined in the SRS (500m)
      final rooms = await chatService.getNearbyRooms(
        _currentPosition!.latitude, 
        _currentPosition!.longitude,
        MAX_RADIUS_KM
      );
      
      // Sort by distance (closest first)
      rooms.sort((a, b) {
        final distA = _getDistanceToChat(a);
        final distB = _getDistanceToChat(b);
        return distA.compareTo(distB);
      });
      
      setState(() {
        _nearbyRooms = rooms;
        if (!silent) {
          _isLoading = false;
        }
      });
    } catch (e) {
      if (!silent) {
        setState(() {
          _errorMessage = 'Failed to load nearby chats: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  double _getDistanceToChat(ChatRoom room) {
    if (_currentPosition == null) return double.infinity;
    
    final locationService = ref.read(locationServiceProvider);
    return locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      room.latitude,
      room.longitude
    ) * 1000; // Convert to meters
  }
  
  void _joinChat(ChatRoom room) {
    // Check if room requires password
    if (room.type == ChatRoomType.private) {
      _showPasswordDialog(room);
    } else {
      _navigateToChatScreen(room.id);
    }
  }
  
  void _showPasswordDialog(ChatRoom room) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password'),
        content: TextField(
          controller: passwordController,
          decoration: InputDecoration(
            hintText: 'Chat room password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would normally validate the password with Firebase
              // For now, we'll just navigate to the chat
              Navigator.pop(context);
              _navigateToChatScreen(room.id);
            },
            child: Text('Join'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToChatScreen(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(roomId: roomId),
      ),
    );
  }
  
  void _createChat() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available. Cannot create chat.')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radius: 0.2, // Default radius (200m)
        ),
      ),
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _getCurrentLocation(),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _nearbyRooms.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No chats found nearby',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a new chat or try again later',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _createChat,
                              child: const Text('Create a Chat'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _nearbyRooms.length,
                      itemBuilder: (context, index) {
                        final room = _nearbyRooms[index];
                        final distance = _getDistanceToChat(room);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(child: Text(room.name)),
                                if (room.isNsfw == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'NSFW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (room.description != null && room.description!.isNotEmpty)
                                  Text(room.description!),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.place, size: 14, color: Colors.grey[600]),
                                    Text(
                                      '${distance.toStringAsFixed(0)}m',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${room.participants}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            leading: CircleAvatar(
                              backgroundColor: room.type == ChatRoomType.private 
                                ? Colors.purple
                                : Theme.of(context).primaryColor,
                              child: Icon(
                                room.type == ChatRoomType.private 
                                  ? Icons.lock
                                  : Icons.chat_bubble,
                                color: Colors.white,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _joinChat(room),
                              child: const Text('Join'),
                            ),
                            onTap: () => _joinChat(room),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton(
              onPressed: _createChat,
              tooltip: 'Create a new chat',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 