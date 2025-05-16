import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoading = true;
  String? _error;
  bool _locationEnabled = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _showReadReceipts = true;
  bool _showProfileInSearch = true;
  bool _allowFriendRequests = true;
  bool _allowGroupInvites = true;
  bool _showActivityStatus = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
        _showOnlineStatus = prefs.getBool('show_online_status') ?? true;
        _showLastSeen = prefs.getBool('show_last_seen') ?? true;
        _showReadReceipts = prefs.getBool('show_read_receipts') ?? true;
        _showProfileInSearch = prefs.getBool('show_profile_in_search') ?? true;
        _allowFriendRequests = prefs.getBool('allow_friend_requests') ?? true;
        _allowGroupInvites = prefs.getBool('allow_group_invites') ?? true;
        _showActivityStatus = prefs.getBool('show_activity_status') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_enabled', _locationEnabled);
      await prefs.setBool('show_online_status', _showOnlineStatus);
      await prefs.setBool('show_last_seen', _showLastSeen);
      await prefs.setBool('show_read_receipts', _showReadReceipts);
      await prefs.setBool('show_profile_in_search', _showProfileInSearch);
      await prefs.setBool('allow_friend_requests', _allowFriendRequests);
      await prefs.setBool('allow_group_invites', _allowGroupInvites);
      await prefs.setBool('show_activity_status', _showActivityStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to save settings: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Location Services'),
                      subtitle: const Text('Share your location with nearby groups'),
                      value: _locationEnabled,
                      onChanged: (value) {
                        setState(() => _locationEnabled = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Profile Visibility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Online Status'),
                      subtitle: const Text('Show when you are online'),
                      value: _showOnlineStatus,
                      onChanged: (value) {
                        setState(() => _showOnlineStatus = value);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Last Seen'),
                      subtitle: const Text('Show when you were last active'),
                      value: _showLastSeen,
                      onChanged: (value) {
                        setState(() => _showLastSeen = value);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Read Receipts'),
                      subtitle: const Text('Show when you have read messages'),
                      value: _showReadReceipts,
                      onChanged: (value) {
                        setState(() => _showReadReceipts = value);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Profile in Search'),
                      subtitle: const Text('Show your profile in search results'),
                      value: _showProfileInSearch,
                      onChanged: (value) {
                        setState(() => _showProfileInSearch = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Interactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Friend Requests'),
                      subtitle: const Text('Allow others to send you friend requests'),
                      value: _allowFriendRequests,
                      onChanged: (value) {
                        setState(() => _allowFriendRequests = value);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Group Invites'),
                      subtitle: const Text('Allow others to invite you to groups'),
                      value: _allowGroupInvites,
                      onChanged: (value) {
                        setState(() => _allowGroupInvites = value);
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Activity Status'),
                      subtitle: const Text('Show your activity in groups'),
                      value: _showActivityStatus,
                      onChanged: (value) {
                        setState(() => _showActivityStatus = value);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
    );
  }
} 