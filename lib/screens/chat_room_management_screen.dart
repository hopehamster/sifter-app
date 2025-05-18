import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../providers/riverpod/auth_provider.dart';

class ChatRoomManagementScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomManagementScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<ChatRoomManagementScreen> createState() => _ChatRoomManagementScreenState();
}

class _ChatRoomManagementScreenState extends ConsumerState<ChatRoomManagementScreen> {
  ChatRoom? _chatRoom;
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _allowAnonymous = false;
  bool _isNsfw = false;
  bool _isSaving = false;
  
  double _radius = 0.2; // Default to 200m
  static const double MAX_RADIUS = 0.2; // 200 meters max
  
  @override
  void initState() {
    super.initState();
    _fetchChatRoomDetails();
  }
  
  Future<void> _fetchChatRoomDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatService = ref.read(chatServiceProvider);
      final room = await chatService.getRoomDetails(widget.roomId);
      
      if (room != null) {
        setState(() {
          _chatRoom = room;
          _nameController.text = room.name;
          _descriptionController.text = room.description ?? '';
          _allowAnonymous = room.allowAnonymous ?? false;
          _isNsfw = room.isNsfw ?? false;
          _radius = room.radius;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat room not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat room: $e')),
      );
    }
  }
  
  Future<void> _updateChatRoom() async {
    if (_chatRoom == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;
      
      if (user == null || user.uid != _chatRoom!.creatorId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only the creator can update this chat room')),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }
      
      final updatedRoom = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'allowAnonymous': _allowAnonymous,
        'isNsfw': _isNsfw,
        'radius': _radius,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await ref.read(chatServiceProvider)
          .updateChatRoomSettings(widget.roomId, updatedRoom);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat room updated successfully')),
      );
      
      Navigator.pop(context, true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update chat room: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _deleteChatRoom() async {
    if (_chatRoom == null) return;
    
    final authState = ref.read(authNotifierProvider);
    final user = authState.value;
    
    if (user == null || user.uid != _chatRoom!.creatorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the creator can delete this chat room')),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat Room'),
        content: const Text(
          'Are you sure you want to delete this chat room? '
          'This action cannot be undone and all messages will be lost.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await ref.read(chatServiceProvider).deactivateChatRoom(widget.roomId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat room deleted successfully')),
        );
        
        // Pop twice to go back to the nearby chats screen
        Navigator.pop(context);
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat room: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;
    final bool isCreator = _chatRoom != null && user != null && 
                           user.uid == _chatRoom!.creatorId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Chat Room'),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteChatRoom,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCreator)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        color: Colors.amber,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Only the chat room creator can modify these settings.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Room Name',
                              border: OutlineInputBorder(),
                            ),
                            enabled: isCreator,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            enabled: isCreator,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SwitchListTile(
                            title: const Text('Allow Anonymous Users'),
                            value: _allowAnonymous,
                            onChanged: isCreator 
                                ? (value) => setState(() => _allowAnonymous = value)
                                : null,
                          ),
                          SwitchListTile(
                            title: const Text('Mark as NSFW'),
                            value: _isNsfw,
                            onChanged: isCreator 
                                ? (value) => setState(() => _isNsfw = value)
                                : null,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Chat Radius: ${(_radius * 1000).toStringAsFixed(0)} meters',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            min: 0.05, // 50 meters minimum
                            max: MAX_RADIUS,
                            value: _radius,
                            divisions: 3,
                            label: '${(_radius * 1000).toStringAsFixed(0)}m',
                            onChanged: isCreator
                                ? (value) => setState(() => _radius = value)
                                : null,
                          ),
                          Text(
                            'Maximum radius is ${(MAX_RADIUS * 1000).toStringAsFixed(0)} meters (about 2 city blocks)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8.0),
                          ListTile(
                            title: const Text('Current Participants'),
                            trailing: Text(
                              '${_chatRoom?.participants ?? 0}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            title: const Text('Created'),
                            trailing: Text(
                              _chatRoom != null
                                  ? '${_chatRoom!.createdAt.day}/${_chatRoom!.createdAt.month}/${_chatRoom!.createdAt.year}'
                                  : 'Unknown',
                            ),
                          ),
                          if (_chatRoom?.expiresAt != null)
                            ListTile(
                              title: const Text('Expires'),
                              trailing: Text(
                                '${_chatRoom!.expiresAt!.day}/${_chatRoom!.expiresAt!.month}/${_chatRoom!.expiresAt!.year}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: isCreator
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateChatRoom,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
                ),
              ),
            )
          : null,
    );
  }
} 