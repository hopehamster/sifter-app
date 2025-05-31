import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../models/chat_room.dart';
import '../services/chat_room_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import 'chat_creation_screen.dart';
import 'settings_screen.dart';
import 'chat_preview_screen.dart';

class ChatJoinScreen extends ConsumerStatefulWidget {
  const ChatJoinScreen({super.key});

  @override
  ConsumerState<ChatJoinScreen> createState() => _ChatJoinScreenState();
}

class _ChatJoinScreenState extends ConsumerState<ChatJoinScreen> {
  bool _isInitializing = true;
  String? _errorMessage;
  int _currentIndex = 1; // Start with Chat Selection/Join tab (middle)

  // Video Ad Timer System (Task 1.4)
  Timer? _adTimer;
  int _adCountdown = 300; // 5 minutes in seconds
  bool _showVideoAd = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startAdTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final settingsService = ref.read(settingsServiceProvider);
        final eligibleRoomsAsync = ref.read(eligibleChatRoomsProvider);

        // Check if video ads are enabled in settings
        if (!settingsService.videoAdsEnabled) {
          return;
        }

        // Only count down when there are no eligible rooms AND user is on chat selection tab
        final hasRooms = eligibleRoomsAsync.value?.isNotEmpty ?? false;
        if (hasRooms || _currentIndex != 1) {
          // Reset timer when rooms become available or user switches tabs
          setState(() {
            _adCountdown = 300;
            _showVideoAd = false;
          });
          return;
        }

        setState(() {
          _adCountdown--;
        });

        if (_adCountdown <= 0) {
          setState(() {
            _showVideoAd = true;
            _adCountdown = 300; // Reset for next ad
          });
        }
      }
    });
  }

  void _resetAdTimer() {
    setState(() {
      _adCountdown = 300; // Reset to 5 minutes
      _showVideoAd = false;
    });
  }

  void _onUserInteraction() {
    _resetAdTimer();
  }

  Future<void> _initializeLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final success = await locationService.initialize();

      if (!mounted) return;

      if (!success) {
        setState(() {
          _errorMessage = 'Location access is required to find chat rooms';
          _isInitializing = false;
        });
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize location services';
          _isInitializing = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _onUserInteraction(); // Reset ad timer on tab switch
  }

  Future<void> _navigateToCreateChat() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatCreationScreen(),
      ),
    );

    // If chat creation was successful, refresh the list and switch to selection tab
    if (result == true && mounted) {
      // ignore: unused_result
      ref.refresh(eligibleChatRoomsProvider);
      setState(() {
        _currentIndex = 1; // Switch back to Chat Selection/Join
      });
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0: // Chat Creation
        return _buildChatCreationTab();
      case 1: // Chat Selection/Join
        return _buildChatSelectionTab();
      case 2: // Settings
        return const SettingsScreen();
      default:
        return _buildChatSelectionTab();
    }
  }

  Widget _buildChatCreationTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Chat Room'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Create a New Chat Room',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Set up a location-based chat room for people in your area to join and connect.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _navigateToCreateChat,
                icon: const Icon(Icons.add),
                label: const Text('Start Creating'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1; // Switch to Chat Selection/Join
                  });
                },
                icon: const Icon(Icons.search),
                label: const Text('Find Existing Rooms'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatSelectionTab() {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sifter Chat'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing location services...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sifter Chat'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initializeLocation();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ignore: unused_result
              ref.refresh(eligibleChatRoomsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ad banner placeholder
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Ad Banner',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // Chat rooms list
          Expanded(
            child: _buildChatRoomsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateChat,
        tooltip: 'Create Chat Room',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Chat Creation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat Selection/Join',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomsList() {
    final eligibleRoomsAsync = ref.watch(eligibleChatRoomsProvider);

    return eligibleRoomsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding chat rooms in your area...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading chat rooms'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(eligibleChatRoomsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (rooms) => _buildRoomsList(rooms),
    );
  }

  Widget _buildRoomsList(List<ChatRoom> rooms) {
    if (rooms.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(eligibleChatRoomsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(ChatRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showChatPreview(room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildRoomBadges(room),
                ],
              ),
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  room.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.participantIds.length}/${room.maxMembers}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getDistanceText(room),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(room.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomBadges(ChatRoom room) {
    final badges = <Widget>[];

    if (room.isPasswordProtected) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 12,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 2),
              Text(
                'Protected',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (room.isNsfw) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                size: 12,
                color: Colors.red[700],
              ),
              const SizedBox(width: 2),
              Text(
                'NSFW',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      children: badges,
    );
  }

  String _getDistanceText(ChatRoom room) {
    final locationService = ref.read(locationServiceProvider);
    final distance = locationService.getDistanceTo(
      targetLat: room.latitude,
      targetLng: room.longitude,
    );

    if (distance == null) return 'Unknown';

    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showChatPreview(ChatRoom room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatPreviewScreen(room: room),
    );
  }

  Widget _buildEmptyState() {
    final settingsService = ref.read(settingsServiceProvider);
    final videoAdsEnabled = settingsService.videoAdsEnabled;

    return GestureDetector(
      onTap: _onUserInteraction,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_searching,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'No Chat Rooms Nearby',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'There are no active chat rooms in your current location. Be the first to create one!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  _onUserInteraction();
                  _navigateToCreateChat();
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Chat Room'),
              ),
              const SizedBox(height: 32),

              // Video ad system (Task 1.4)
              if (videoAdsEnabled) ...[
                if (_showVideoAd) ...[
                  // Show video ad
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow,
                                  size: 64, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'Video Advertisement',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              Text(
                                'Tap to skip or watch to support the app',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _showVideoAd = false;
                                _adCountdown = 300; // Reset timer
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Show countdown timer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Video content in ${_formatAdCountdown(_adCountdown)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (300 - _adCountdown) / 300,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ads help support free access to Sifter Chat',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatAdCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
