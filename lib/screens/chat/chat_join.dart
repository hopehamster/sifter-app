import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:sifter/screens/auth/login_screen.dart';
import 'chat_screen.dart';
import 'package:sifter/providers/auth_provider.dart' as s;

class ChatDetailsScreen extends StatefulWidget {
  final String roomId;

  ChatDetailsScreen({required this.roomId});

  @override
  _ChatDetailsScreenState createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final _passwordController = TextEditingController();
  Map<String, dynamic>? _roomData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoomData();
  }

  Future<void> _fetchRoomData() async {
    final snapshot = await _db.child('rooms/${widget.roomId}').get();
    if (snapshot.exists) {
      setState(() {
        _roomData = Map<String, dynamic>.from(snapshot.value as Map);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Room not found';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinChat() async {
    final authProvider = Provider.of<s.AuthProvider>(context, listen: false);
    final bool allowAnonymous = _roomData?['allowAnonymous'] ?? false;
    final String? roomPassword = _roomData?['password'];
    final enteredPassword = _passwordController.text;
    final bool isActive = _roomData?['isActive'] ?? false;

    if (!isActive) {
      setState(() {
        _error = 'This chat room is closed.';
      });
      return;
    }

    // Check if anonymous users are allowed
    if (authProvider.user == null && !allowAnonymous) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sign In Required'),
          content: Text(
              'This chat does not allow anonymous users. Please sign in to join.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    // Check password if required
    if (roomPassword != null && roomPassword.isNotEmpty) {
      if (enteredPassword != roomPassword) {
        setState(() {
          _error = 'Incorrect password';
        });
        return;
      }
    }

    // Proceed to chat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(roomId: widget.roomId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    final bool allowAnonymous = _roomData?['allowAnonymous'] ?? false;
    final bool isNsfw = _roomData?['isNsfw'] ?? false;
    final String? password = _roomData?['password'];

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(_roomData!['description'] ?? 'No description provided'),
            SizedBox(height: 16),
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text('NSFW: ${isNsfw ? 'Yes' : 'No'}'),
            Text('Anonymous Users Allowed: ${allowAnonymous ? 'Yes' : 'No'}'),
            if (password != null && password.isNotEmpty) ...[
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Enter Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                obscureText: true,
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _joinChat,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Join Chat', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
