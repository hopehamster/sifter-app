import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageUsersScreen extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> _banUser(String userId) async {
    await _db.child('banned_users/$userId').set(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Users')),
      body: StreamBuilder(
        stream: _db.child('users').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final users = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map? ?? {});
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userId = users.keys.elementAt(index);
              final user = users[userId];
              return ListTile(
                title: Text(user['email'] ?? 'Anonymous'),
                trailing: IconButton(
                  icon: Icon(Icons.block, color: Colors.red),
                  onPressed: () => _banUser(userId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
