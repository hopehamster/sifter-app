import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class GroupSettingsDialog extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const GroupSettingsDialog({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
  });

  @override
  ConsumerState<GroupSettingsDialog> createState() => _GroupSettingsDialogState();
}

class _GroupSettingsDialogState extends ConsumerState<GroupSettingsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _passwordController;
  late bool _isPrivate;
  late bool _isPasswordProtected;
  late int _maxMembers;
  List<User> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chatRoom.name);
    _descriptionController = TextEditingController(text: widget.chatRoom.description);
    _passwordController = TextEditingController(text: widget.chatRoom.password);
    _isPrivate = widget.chatRoom.isPrivate;
    _isPasswordProtected = widget.chatRoom.isPasswordProtected;
    _maxMembers = widget.chatRoom.maxMembers;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final userService = ref.read(userServiceProvider);
      final members = await Future.wait(
        widget.chatRoom.memberIds.map((id) => userService.getUser(id))
      );
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final updatedRoom = widget.chatRoom.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        isPrivate: _isPrivate,
        isPasswordProtected: _isPasswordProtected,
        password: _isPasswordProtected ? _passwordController.text : null,
        maxMembers: _maxMembers,
      );
      await chatService.updateChatRoom(updatedRoom);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  Future<void> _promoteToAdmin(String userId) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final updatedRoom = widget.chatRoom.copyWith(
        admins: [...widget.chatRoom.admins, userId],
        memberRoles: {
          ...widget.chatRoom.memberRoles,
          userId: ChatRoomRole.admin,
        },
      );
      await chatService.updateChatRoom(updatedRoom);
      await _loadMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to promote user: $e')),
        );
      }
    }
  }

  Future<void> _demoteAdmin(String userId) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final updatedRoom = widget.chatRoom.copyWith(
        admins: widget.chatRoom.admins.where((id) => id != userId).toList(),
        memberRoles: {
          ...widget.chatRoom.memberRoles,
          userId: ChatRoomRole.member,
        },
      );
      await chatService.updateChatRoom(updatedRoom);
      await _loadMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to demote admin: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.removeMember(widget.chatRoom.id, userId);
      await _loadMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }

  Future<void> _banUser(String userId) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final updatedRoom = widget.chatRoom.copyWith(
        bannedUsers: [...widget.chatRoom.bannedUsers, userId],
      );
      await chatService.updateChatRoom(updatedRoom);
      await _removeMember(userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ban user: $e')),
        );
      }
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
                  'Group Settings',
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.chatRoom.canEditGroupInfo(widget.currentUserId)) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Private Group'),
                        subtitle: const Text('Only admins can add members'),
                        value: _isPrivate,
                        onChanged: (value) => setState(() => _isPrivate = value),
                      ),
                      SwitchListTile(
                        title: const Text('Password Protected'),
                        subtitle: const Text('Users need a password to join'),
                        value: _isPasswordProtected,
                        onChanged: (value) => setState(() => _isPasswordProtected = value),
                      ),
                      if (_isPasswordProtected) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Group Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Max Members: '),
                          Expanded(
                            child: Slider(
                              value: _maxMembers.toDouble(),
                              min: 2,
                              max: 1000,
                              divisions: 99,
                              label: _maxMembers.toString(),
                              onChanged: (value) => setState(() => _maxMembers = value.toInt()),
                            ),
                          ),
                          Text(_maxMembers.toString()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                      const Divider(),
                    ],
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final isAdmin = widget.chatRoom.isAdmin(member.id);
                          final isOwner = widget.chatRoom.isOwner(member.id);
                          final canManage = widget.chatRoom.canBanUser(
                            widget.currentUserId,
                            member.id,
                          );

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: member.photoUrl != null
                                  ? NetworkImage(member.photoUrl!)
                                  : null,
                              child: member.photoUrl == null
                                  ? Text(member.initials)
                                  : null,
                            ),
                            title: Text(member.displayName),
                            subtitle: Text(
                              isOwner
                                  ? 'Owner'
                                  : isAdmin
                                      ? 'Admin'
                                      : 'Member',
                            ),
                            trailing: canManage
                                ? PopupMenuButton(
                                    itemBuilder: (context) => [
                                      if (!isAdmin && widget.chatRoom.canPromoteToAdmin(widget.currentUserId))
                                        PopupMenuItem(
                                          child: const Text('Promote to Admin'),
                                          onTap: () => _promoteToAdmin(member.id),
                                        ),
                                      if (isAdmin && widget.chatRoom.canDemoteAdmin(widget.currentUserId, member.id))
                                        PopupMenuItem(
                                          child: const Text('Demote Admin'),
                                          onTap: () => _demoteAdmin(member.id),
                                        ),
                                      if (canManage)
                                        PopupMenuItem(
                                          child: const Text('Remove from Group'),
                                          onTap: () => _removeMember(member.id),
                                        ),
                                      if (widget.chatRoom.canBanUser(widget.currentUserId, member.id))
                                        PopupMenuItem(
                                          child: const Text('Ban User'),
                                          onTap: () => _banUser(member.id),
                                        ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 