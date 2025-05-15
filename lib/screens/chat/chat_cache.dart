import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class ChatCache {
  static Database? _db;

  static Future<void> init() async {
    _db = await openDatabase('sifter_cache.db', version: 1,
        onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE messages (roomId TEXT, messageId TEXT, content TEXT, timestamp INTEGER)');
    });
  }

  static Future<void> cacheMessage(
      String roomId, Map<String, dynamic> message) async {
    await _db!.insert('messages', {
      'roomId': roomId,
      'messageId': message['id'],
      'content': jsonEncode(message),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _db!.delete('messages', where: 'timestamp < ?', whereArgs: [
      DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch
    ]);
  }

  static Future<List> getCachedMessages(String roomId) async {
    final result = await _db!
        .query('messages', where: 'roomId = ?', whereArgs: [roomId], limit: 50);
    return result.map((e) => jsonDecode(e['content'] as String)).toList();
  }
}
