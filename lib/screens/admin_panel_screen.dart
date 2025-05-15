import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminPanelScreen extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> _deleteUser(String userId) async {
    await _db.child('users/$userId').remove();
  }

  Future<void> _deleteChat(String roomId) async {
    await _db.child('rooms/$roomId').remove();
    await _db.child('messages/$roomId').remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Delete User'),
              onTap: () {
                // Placeholder for user deletion UI
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete User'),
                    content: Text('This feature is coming soon!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Delete Chat'),
              onTap: () {
                // Placeholder for chat deletion UI
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Chat'),
                    content: Text('This feature is coming soon!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}