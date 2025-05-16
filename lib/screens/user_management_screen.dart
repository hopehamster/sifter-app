import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/models/user.dart';
import 'package:sifter/providers/app_providers.dart';
import 'package:sifter/services/user_service.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  
  List<String> _blockedUserIds = [];
  List<Map<String, dynamic>> _mutedUsers = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserLists();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserLists() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = ref.read(userProvider).value;
      if (currentUser != null) {
        final blockedUsers = await _userService.getBlockedUsers(currentUser.id);
        final mutedUsers = await _userService.getMutedUsers(currentUser.id);
        
        setState(() {
          _blockedUserIds = blockedUsers;
          _mutedUsers = mutedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user lists: $e')),
      );
    }
  }
  
  Future<void> _unblockUser(String userId) async {
    try {
      final currentUser = ref.read(userProvider).value;
      if (currentUser != null) {
        await _userService.unblockUser(currentUser.id, userId);
        setState(() {
          _blockedUserIds.remove(userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unblocking user: $e')),
      );
    }
  }
  
  Future<void> _unmuteUser(String userId) async {
    try {
      final currentUser = ref.read(userProvider).value;
      if (currentUser != null) {
        await _userService.unmuteUser(currentUser.id, userId);
        setState(() {
          _mutedUsers.removeWhere((user) => user['userId'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unmuted')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unmuting user: $e')),
      );
    }
  }
  
  String _formatMuteExpiration(int? timestamp) {
    if (timestamp == null) {
      return 'Muted indefinitely';
    }
    
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    if (expirationDate.isBefore(now)) {
      return 'Mute expired';
    }
    
    final difference = expirationDate.difference(now);
    
    if (difference.inDays > 0) {
      return 'Muted for ${difference.inDays} more days';
    } else if (difference.inHours > 0) {
      return 'Muted for ${difference.inHours} more hours';
    } else {
      return 'Muted for ${difference.inMinutes} more minutes';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Blocked Users'),
            Tab(text: 'Muted Users'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBlockedUsersTab(),
                _buildMutedUsersTab(),
              ],
            ),
    );
  }
  
  Widget _buildBlockedUsersTab() {
    if (_blockedUserIds.isEmpty) {
      return const Center(
        child: Text('You haven\'t blocked any users yet'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadUserLists,
      child: ListView.builder(
        itemCount: _blockedUserIds.length,
        itemBuilder: (context, index) {
          final userId = _blockedUserIds[index];
          
          return FutureBuilder<AppUser?>(
            future: _userService.getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Loading user...'),
                );
              }
              
              final user = snapshot.data;
              final displayName = user?.displayName ?? 'Unknown User';
              
              return ListTile(
                leading: user?.photoUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(user!.photoUrl!))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(displayName),
                subtitle: const Text('Blocked'),
                trailing: TextButton(
                  onPressed: () => _unblockUser(userId),
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildMutedUsersTab() {
    if (_mutedUsers.isEmpty) {
      return const Center(
        child: Text('You haven\'t muted any users yet'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadUserLists,
      child: ListView.builder(
        itemCount: _mutedUsers.length,
        itemBuilder: (context, index) {
          final mutedUser = _mutedUsers[index];
          final userId = mutedUser['userId'] as String;
          final mutedUntil = mutedUser['mutedUntil'] as int?;
          
          return FutureBuilder<AppUser?>(
            future: _userService.getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Loading user...'),
                );
              }
              
              final user = snapshot.data;
              final displayName = user?.displayName ?? 'Unknown User';
              
              return ListTile(
                leading: user?.photoUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(user!.photoUrl!))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(displayName),
                subtitle: Text(_formatMuteExpiration(mutedUntil)),
                trailing: TextButton(
                  onPressed: () => _unmuteUser(userId),
                  child: const Text('Unmute'),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 