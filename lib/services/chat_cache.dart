import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatCache {
  static Database? _database;

  static Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'chat_cache.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages(roomId TEXT, messageId TEXT, content TEXT, audioUrl TEXT, userId TEXT, createdAt TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> cacheMessage(String roomId, Map<String, dynamic> message) async {
    if (_database == null) await init();
    await _database!.insert(
      'messages',
      {
        'roomId': roomId,
        'messageId': message['id'] ?? '',
        'content': message['content'],
        'audioUrl': message['audioUrl'],
        'userId': message['userId'],
        'createdAt': message['createdAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedMessages(String roomId) async {
    if (_database == null) await init();
    final List<Map<String, dynamic>> maps = await _database!.query(
      'messages',
      where: 'roomId = ?',
      whereArgs: [roomId],
    );
    return maps;
  }
}