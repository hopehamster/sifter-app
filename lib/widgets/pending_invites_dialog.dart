import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class PendingInvitesDialog extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const PendingInvitesDialog({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
  });

  @override
  ConsumerState<PendingInvitesDialog> createState() => _PendingInvitesDialogState();
}

class _PendingInvitesDialogState extends ConsumerState<PendingInvitesDialog> {
  List<User> _pendingUsers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final pendingInvites = widget.chatRoom.metadata['pendingInvites'] as List<dynamic>? ?? [];
      
      final users = await Future.wait(
        pendingInvites.map((userId) => userService.getUser(userId.toString())),
      );

      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pending users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInvite(String userId, bool approved) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      
      if (approved) {
        await chatService.addMember(widget.chatRoom.id, userId);
      }

      // Remove from pending invites
      final updatedRoom = widget.chatRoom.copyWith(
        metadata: {
          ...widget.chatRoom.metadata,
          'pendingInvites': (widget.chatRoom.metadata['pendingInvites'] as List<dynamic>? ?? [])
              .where((id) => id.toString() != userId)
              .toList(),
        },
      );
      await chatService.updateChatRoom(updatedRoom);

      // Refresh the list
      await _loadPendingUsers();
    } catch (e) {
      setState(() {
        _error = 'Failed to handle invite: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Invites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingUsers.isEmpty
                      ? const Center(
                          child: Text('No pending invites'),
                        )
                      : ListView.builder(
                          itemCount: _pendingUsers.length,
                          itemBuilder: (context, index) {
                            final user = _pendingUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? Text(user.initials)
                                    : null,
                              ),
                              title: Text(user.displayName),
                              subtitle: Text(user.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _handleInvite(user.id, true),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _handleInvite(user.id, false),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 