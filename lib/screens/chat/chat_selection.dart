import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/providers/riverpod/room_provider.dart';
import 'package:sifter/screens/chat/chat_screen.dart';
import 'package:sifter/models/chat_room.dart';
import 'package:sifter/utils/error_handler.dart';

class ChatSelectionScreen extends ConsumerWidget {
  const ChatSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(roomNotifierProvider.notifier).refreshRooms();
            },
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No chats available. Create one!'),
            );
          }
          
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomItem(context, room);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading chats: ${ErrorHandler.getErrorMessage(error)}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(roomNotifierProvider.notifier).refreshRooms();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create chat screen
          // Navigator.push(context, MaterialPageRoute(builder: (_) => CreateRoomScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomItem(BuildContext context, ChatRoom room) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            room.name.isNotEmpty 
              ? room.name.substring(0, 1).toUpperCase() 
              : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(room.name),
        subtitle: Text(
          room.description.isNotEmpty 
            ? room.description 
            : 'No description',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(roomId: room.id),
            ),
          );
        },
      ),
    );
  }
}
