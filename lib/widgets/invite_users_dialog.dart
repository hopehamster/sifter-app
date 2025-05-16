import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class InviteUsersDialog extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const InviteUsersDialog({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
  });

  @override
  ConsumerState<InviteUsersDialog> createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends ConsumerState<InviteUsersDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  List<String> _selectedUserIds = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _onSearchChanged() async {
    if (_searchController.text.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final results = await userService.searchUsers(_searchController.text);
      
      // Filter out users who are already members or banned
      final filteredResults = results.where((user) =>
        !widget.chatRoom.memberIds.contains(user.id) &&
        !widget.chatRoom.bannedUsers.contains(user.id)
      ).toList();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _inviteUsers() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      
      // If approval is required, add users to pending invites
      if (widget.chatRoom.requireApproval) {
        final updatedRoom = widget.chatRoom.copyWith(
          metadata: {
            ...widget.chatRoom.metadata,
            'pendingInvites': [
              ...(widget.chatRoom.metadata['pendingInvites'] as List<dynamic>? ?? []),
              ..._selectedUserIds,
            ],
          },
        );
        await chatService.updateChatRoom(updatedRoom);
      } else {
        // Otherwise, add users directly
        for (final userId in _selectedUserIds) {
          await chatService.addMember(widget.chatRoom.id, userId);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to invite users: $e';
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
                  'Invite Users',
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
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
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
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isSelected = _selectedUserIds.contains(user.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                            });
                          },
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          secondary: CircleAvatar(
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(user.initials)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedUserIds.length} users selected'),
                ElevatedButton(
                  onPressed: _selectedUserIds.isEmpty || _isLoading
                      ? null
                      : _inviteUsers,
                  child: const Text('Invite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 