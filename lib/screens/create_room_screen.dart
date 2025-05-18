import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/riverpod/auth_provider.dart';
import '../utils/validation.dart';
import '../services/points_service.dart';
import '../constants/ad_constants.dart';
import 'chat_screen.dart';
import 'chat_selection_screen.dart';
import '../services/room_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final double radius;

  const CreateRoomScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _roomNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rulesController = TextEditingController();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  bool _allowAnonymous = false;
  bool _isNsfw = false;
  bool _isLoading = false;
  RewardedAd? _rewardedAd;
  int _chatCreationCount = 0;
  double _radius = 0.2; // Default 200m radius
  Color _themeColor = Colors.blue; // Default theme color
  
  static const double MIN_RADIUS = 0.05; // 50 meters minimum
  static const double MAX_RADIUS = 0.5; // 500 meters maximum per SRS

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _fetchChatCreationCount();
    _radius = widget.radius.clamp(MIN_RADIUS, MAX_RADIUS);
    
    // Set default rules
    _rulesController.text = 'Be respectful to all users. No spam or advertising.';
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _rulesController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad: ${error.message}');
        },
      ),
    );
  }

  Future<void> _fetchChatCreationCount() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.value;
    if (user == null) return;

    try {
      final snapshot = await _db.child('users/${user.uid}/chatCreationCount').get();
      if (snapshot.exists) {
        setState(() {
          _chatCreationCount = snapshot.value as int;
        });
      }
    } catch (e) {
      print('Error fetching chat creation count: $e');
    }
  }
  
  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a theme color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _themeColor,
            onColorChanged: (color) {
              setState(() => _themeColor = color);
            },
            pickerAreaHeightPercent: 0.8,
            portraitOnly: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim();
    
    // Validate the room name
    final validationError = Validator.validateRoomName(roomName);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authState = ref.read(authNotifierProvider);
    final user = authState.value;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to create a room')),
      );
      return;
    }
    
    try {
      // Increment chat creation count
      final newCount = _chatCreationCount + 1;
      await _db.child('users/${user.uid}/chatCreationCount').set(newCount);
      setState(() {
        _chatCreationCount = newCount;
      });

      // Award points for creating a room
      final pointsService = ref.read(pointsServiceProvider);
      await pointsService.rewardForGroupCreation(
        user.uid, 
        isNsfw: _isNsfw, 
        isPasswordProtected: _passwordController.text.isNotEmpty
      );

      // Show rewarded ad every 5 chats
      if (_chatCreationCount % 5 == 0 && _rewardedAd != null) {
        await _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            // Award points for watching the ad
            pointsService.rewardForAd(user.uid);
          },
        );
      }

      // Validate password if provided
      if (_passwordController.text.isNotEmpty && _passwordController.text.length < 4) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 4 characters')),
        );
        return;
      }
      
      // Create the room with 24-hour expiration
      final roomId = _db.child('rooms').push().key!;
      await _db.child('rooms/$roomId').set({
        'name': roomName,
        'description': _descriptionController.text.trim(),
        'creatorId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'radius': _radius,
        'allowAnonymous': _allowAnonymous,
        'isNsfw': _isNsfw,
        'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
        'isActive': true,
        'participants': 1,
        'rules': _rulesController.text.trim(),
        'themeColor': _themeColor.value,
        // Add expiration timestamps
        'expiresAt': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
        'lastActivityAt': DateTime.now().toIso8601String(),
        'activityLog': {
          user.uid: {
            'joinedAt': DateTime.now().toIso8601String(),
            'lastActive': ServerValue.timestamp,
          }
        }
      });

      // Navigate to the chat screen
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Chat Room'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room Name
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
                  const SizedBox(height: 16),
                  
                  // Description
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
                  const SizedBox(height: 16),
                  
                  // Radius Slider
                  Text('Chat Radius: ${(_radius * 1000).toInt()} meters',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _radius,
                    min: MIN_RADIUS,
                    max: MAX_RADIUS,
                    divisions: 9, // 50m increments
                    label: '${(_radius * 1000).toInt()}m',
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Rules
                  TextField(
                    controller: _rulesController,
                    decoration: InputDecoration(
                      labelText: 'Room Rules',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Theme Color
                  Row(
                    children: [
                      const Text('Theme Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _openColorPicker,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _openColorPicker,
                        icon: const Icon(Icons.color_lens),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Settings Switches
                  SwitchListTile(
                    title: const Text('Allow Anonymous Users'),
                    subtitle: const Text('Let users join without an account'),
                    value: _allowAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _allowAnonymous = value;
                        // NSFW rooms can't allow anonymous users
                        if (_isNsfw && value) {
                          _allowAnonymous = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('NSFW rooms cannot allow anonymous users')),
                          );
                        }
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Mark as NSFW'),
                    subtitle: const Text('Content is for users 18+ only'),
                    value: _isNsfw,
                    onChanged: (value) {
                      setState(() {
                        _isNsfw = value;
                        // NSFW rooms can't allow anonymous users
                        if (value && _allowAnonymous) {
                          _allowAnonymous = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: 'Leave empty for public access',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  
                  // Create Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _createRoom,
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Create Chat Room'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notice about expiration
                  const Center(
                    child: Text(
                      'Rooms automatically expire after 24 hours of inactivity',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}