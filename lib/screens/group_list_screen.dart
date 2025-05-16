import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:location/location.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/points_service.dart';
import '../widgets/join_group_dialog.dart';
import 'create_group_screen.dart';
import 'dart:math' as math;

class GroupListScreen extends ConsumerStatefulWidget {
  final String currentUserId;

  const GroupListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  List<ChatRoom> _groups = [];
  bool _isLoading = true;
  String? _error;
  LocationData? _currentLocation;
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _getCurrentLocation();
    _loadAds();
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    try {
      final pointsService = ref.read(pointsServiceProvider);
      final points = await pointsService.getUserPoints(widget.currentUserId);
      setState(() => _userPoints = points);
    } catch (e) {
      print('Failed to load user points: $e');
    }
  }

  Future<void> _loadAds() async {
    // Load banner ad
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4410913273665896/4892470653',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    await _bannerAd?.load();

    // Load rewarded ad
    await RewardedAd.load(
      adUnitId: 'ca-app-pub-4410913273665896/5426823122',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() {});
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad: $error');
        },
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = Location();
      final locationData = await location.getLocation();
      setState(() => _currentLocation = locationData);
    } catch (e) {
      print('Failed to get location: $e');
    }
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final groups = await chatService.getPublicGroups();
      
      // Filter groups based on location and membership
      final availableGroups = groups.where((group) {
        if (group.memberIds.contains(widget.currentUserId) ||
            group.bannedUsers.contains(widget.currentUserId)) {
          return false;
        }

        // If location is available, check if group is within range
        if (_currentLocation != null && group.metadata['location'] != null) {
          final groupLocation = group.metadata['location'] as Map<String, dynamic>;
          final distance = _calculateDistance(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
            groupLocation['latitude'] as double,
            groupLocation['longitude'] as double,
          );
          return distance <= (group.metadata['radius'] as double? ?? 10.0);
        }

        return true;
      }).toList();

      setState(() {
        _groups = availableGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load groups: $e';
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula to calculate distance between two points
    const R = 6371.0; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  Future<void> _showRewardedAd() async {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet. Please try again later.')),
      );
      return;
    }

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) async {
        try {
          final pointsService = ref.read(pointsServiceProvider);
          await pointsService.rewardForAd(widget.currentUserId);
          await _loadUserPoints();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You earned 10 points!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to reward points: $e')),
            );
          }
        }
      },
    );
  }

  void _navigateToCreateGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (result != null) {
      // Refresh the list after creating a group
      await _loadGroups();
    }
  }

  Future<void> _showJoinDialog(ChatRoom group) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => JoinGroupDialog(
        chatRoom: group,
        currentUserId: widget.currentUserId,
      ),
    );

    if (result == true) {
      await _loadGroups();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No groups available in your area',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch a video to earn points or create your own group!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showRewardedAd,
                icon: const Icon(Icons.play_circle),
                label: const Text('Watch Ad'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _navigateToCreateGroup,
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your Points: $_userPoints',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadGroups,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _groups.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _groups.length,
                            itemBuilder: (context, index) {
                              final group = _groups[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: group.photoUrl != null
                                        ? NetworkImage(group.photoUrl!)
                                        : null,
                                    child: group.photoUrl == null
                                        ? Text(group.name[0].toUpperCase())
                                        : null,
                                  ),
                                  title: Text(group.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (group.description != null)
                                        Text(
                                          group.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        '${group.memberIds.length} members',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: group.isPasswordProtected
                                      ? const Icon(Icons.lock)
                                      : null,
                                  onTap: () => _showJoinDialog(group),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
} 