import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = true;
  String? _error;
  bool _pushEnabled = true;
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _mentionNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _quietHoursEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushEnabled = prefs.getBool('notifications_enabled') ?? true;
        _messageNotifications = prefs.getBool('message_notifications') ?? true;
        _groupNotifications = prefs.getBool('group_notifications') ?? true;
        _mentionNotifications = prefs.getBool('mention_notifications') ?? true;
        _soundEnabled = prefs.getBool('notification_sound') ?? true;
        _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
        _quietHoursStart = prefs.getString('quiet_hours_start') ?? '22:00';
        _quietHoursEnd = prefs.getString('quiet_hours_end') ?? '08:00';
        _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
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
      await prefs.setBool('notifications_enabled', _pushEnabled);
      await prefs.setBool('message_notifications', _messageNotifications);
      await prefs.setBool('group_notifications', _groupNotifications);
      await prefs.setBool('mention_notifications', _mentionNotifications);
      await prefs.setBool('notification_sound', _soundEnabled);
      await prefs.setBool('notification_vibration', _vibrationEnabled);
      await prefs.setString('quiet_hours_start', _quietHoursStart);
      await prefs.setString('quiet_hours_end', _quietHoursEnd);
      await prefs.setBool('quiet_hours_enabled', _quietHoursEnabled);

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

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(isStart ? _quietHoursStart : _quietHoursEnd).split(':')[0],
        minute: int.parse(isStart ? _quietHoursStart : _quietHoursEnd).split(':')[1],
      ),
    );

    if (picked != null) {
      setState(() {
        final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _quietHoursStart = time;
        } else {
          _quietHoursEnd = time;
        }
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
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
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Enable all notifications'),
                      value: _pushEnabled,
                      onChanged: (value) {
                        setState(() => _pushEnabled = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(),
                    if (_pushEnabled) ...[
                      SwitchListTile(
                        title: const Text('Message Notifications'),
                        subtitle: const Text('Notify when receiving messages'),
                        value: _messageNotifications,
                        onChanged: (value) {
                          setState(() => _messageNotifications = value);
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Group Notifications'),
                        subtitle: const Text('Notify about group activities'),
                        value: _groupNotifications,
                        onChanged: (value) {
                          setState(() => _groupNotifications = value);
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Mention Notifications'),
                        subtitle: const Text('Notify when mentioned'),
                        value: _mentionNotifications,
                        onChanged: (value) {
                          setState(() => _mentionNotifications = value);
                          _saveSettings();
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Sound'),
                        subtitle: const Text('Play sound for notifications'),
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() => _soundEnabled = value);
                          _saveSettings();
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Vibration'),
                        subtitle: const Text('Vibrate for notifications'),
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() => _vibrationEnabled = value);
                          _saveSettings();
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Quiet Hours'),
                        subtitle: const Text('Mute notifications during quiet hours'),
                        value: _quietHoursEnabled,
                        onChanged: (value) {
                          setState(() => _quietHoursEnabled = value);
                          _saveSettings();
                        },
                      ),
                      if (_quietHoursEnabled) ...[
                        ListTile(
                          title: const Text('Quiet Hours Start'),
                          subtitle: Text(_quietHoursStart),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, true),
                        ),
                        ListTile(
                          title: const Text('Quiet Hours End'),
                          subtitle: Text(_quietHoursEnd),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, false),
                        ),
                      ],
                    ],
                  ],
                ),
    );
  }
} 