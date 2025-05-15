import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:sifter/providers/auth_provider.dart';

class ModerateChatsScreen extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> _deleteMessage(String roomId, String messageId) async {
    await _db.child('messages/$roomId/$messageId').remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moderate Chats')),
      body: StreamBuilder(
        stream: _db.child('rooms').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final rooms = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map? ?? {});
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomId = rooms.keys.elementAt(index);
              return ExpansionTile(
                title: Text(rooms[roomId]['name']),
                children: [
                  StreamBuilder(
                    stream: _db.child('messages/$roomId').onValue,
                    builder:
                        (context, AsyncSnapshot<DatabaseEvent> msgSnapshot) {
                      if (!msgSnapshot.hasData)
                        return CircularProgressIndicator();
                      final messages = Map<String, dynamic>.from(
                          msgSnapshot.data!.snapshot.value as Map? ?? {});
                      return Column(
                        children: messages.entries.map((e) {
                          return ListTile(
                            title: Text(e.value['content'] ?? 'Media'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMessage(roomId, e.key),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
