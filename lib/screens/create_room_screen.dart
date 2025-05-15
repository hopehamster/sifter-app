import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'chat_selection_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radius;

  CreateRoomScreen({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _roomNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  bool _allowAnonymous = false;
  bool _isNsfw = false;
  RewardedAd? _rewardedAd;
  int _chatCreationCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _fetchChatCreationCount();
  }

  Future<void> _fetchChatCreationCount() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final snapshot = await _db.child('users/${authProvider.userId}/chatCreationCount').get();
    if (snapshot.exists) {
      setState(() {
        _chatCreationCount = snapshot.value as int;
      });
    } else {
      await _db.child('users/${authProvider.userId}/chatCreationCount').set(0);
      setState(() {
        _chatCreationCount = 0;
      });
    }
  }

  Future<void> _loadRewardedAd() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await RewardedAd.load(
        adUnitId: 'YOUR_REWARDED_AD_UNIT_ID',
        request: AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedAd = null;
                _loadRewardedAd(); // Reload for next use
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _rewardedAd = null;
                _loadRewardedAd();
              },
            );
            setState(() {
              _isLoading = false;
            });
          },
          onAdFailedToLoad: (error) {
            print('Rewarded ad failed to load: $error');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createRoom() async {
    final roomName = _roomNameController.text;
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room name cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Increment chat creation count
      final newCount = _chatCreationCount + 1;
      await _db.child('users/${authProvider.userId}/chatCreationCount').set(newCount);
      setState(() {
        _chatCreationCount = newCount;
      });

      // Show rewarded ad every 5 chats
      if (_chatCreationCount % 5 == 0 && _rewardedAd != null) {
        await _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            // Award 10 points for watching the ad
            _db.child('users/${authProvider.userId}/points').set(ServerValue.increment(10));
          },
        );
      }

      final roomId = _db.child('rooms').push().key!;
      await _db.child('rooms/$roomId').set({
        'name': roomName,
        'description': _descriptionController.text,
        'creatorId': authProvider.userId,
        'createdAt': DateTime.now().toIso8601String(),
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'radius': widget.radius,
        'allowAnonymous': _allowAnonymous,
        'isNsfw': _isNsfw,
        'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
        'isActive': true, // Track if the chat is active
        'participants': 1, // Initialize participants count
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(roomId: roomId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create chat: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create a New Room')),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  TextField(
                    controller: _roomNameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Allow Anonymous Users'),
                    value: _allowAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _allowAnonymous = value;
                      });
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  SwitchListTile(
                    title: Text('Mark as NSFW'),
                    value: _isNsfw,
                    onChanged: (value) {
                      setState(() {
                        _isNsfw = value;
                      });
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Create Chat', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}