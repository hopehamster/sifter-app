import 'package:flutter/material.dart';
import 'package:sifter/screens/chat/moderate_chats_screen.dart';
import 'package:sifter/screens/manage_users_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ManageUsersScreen()),
              ),
              child: Text('Manage Users'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ModerateChatsScreen()),
              ),
              child: Text('Moderate Chats'),
            ),
          ],
        ),
      ),
    );
  }
}
