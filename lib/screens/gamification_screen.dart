import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:sifter/providers/auth_provider.dart' as s;

// import 'package:provider/provider.dart';
// import 'package:sifter/providers/auth_provider.dart';
class GamificationScreen extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<s.AuthProvider>(context).userId;
    return Scaffold(
      appBar: AppBar(title: Text('Gamification')),
      body: StreamBuilder(
        stream: _db.child('users/$userId').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final userData = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map? ?? {});
          final points = userData['points'] ?? 0;
          final badges = List<String>.from(userData['badges'] ?? []);
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Points: $points', style: TextStyle(fontSize: 20)),
                SizedBox(height: 20),
                Text('Badges', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: ListView.builder(
                    itemCount: badges.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(badges[index]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
