import 'package:flutter/material.dart';
import 'package:sifter/models/user.dart';

enum UserActionType {
  block,
  mute,
}

class UserActionDialog extends StatefulWidget {
  final AppUser targetUser;
  
  const UserActionDialog({
    Key? key,
    required this.targetUser,
  }) : super(key: key);

  @override
  State<UserActionDialog> createState() => _UserActionDialogState();
}

class _UserActionDialogState extends State<UserActionDialog> {
  UserActionType _selectedAction = UserActionType.block;
  Duration? _muteDuration;
  
  final List<Map<String, dynamic>> _muteDurations = [
    {'label': '1 hour', 'duration': const Duration(hours: 1)},
    {'label': '8 hours', 'duration': const Duration(hours: 8)},
    {'label': '1 day', 'duration': const Duration(days: 1)},
    {'label': '1 week', 'duration': const Duration(days: 7)},
    {'label': '1 month', 'duration': const Duration(days: 30)},
    {'label': 'Forever', 'duration': null},
  ];
  
  @override
  void initState() {
    super.initState();
    _muteDuration = _muteDurations.first['duration'];
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('User Actions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: (widget.targetUser.photoUrl != null && widget.targetUser.photoUrl!.isNotEmpty)
                  ? CircleAvatar(backgroundImage: NetworkImage(widget.targetUser.photoUrl!))
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(widget.targetUser.displayName),
            ),
            const Divider(),
            const Text('What would you like to do?'),
            RadioListTile<UserActionType>(
              title: const Text('Block User'),
              subtitle: const Text('You won\'t see any messages from this user'),
              value: UserActionType.block,
              groupValue: _selectedAction,
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
            ),
            RadioListTile<UserActionType>(
              title: const Text('Mute User'),
              subtitle: const Text('You won\'t receive notifications from this user'),
              value: UserActionType.mute,
              groupValue: _selectedAction,
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
            ),
            if (_selectedAction == UserActionType.mute) ...[
              const SizedBox(height: 8),
              const Text('Mute duration:'),
              DropdownButton<Duration?>(
                isExpanded: true,
                value: _muteDuration,
                items: _muteDurations.map((option) {
                  return DropdownMenuItem<Duration?>(
                    value: option['duration'],
                    child: Text(option['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _muteDuration = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'action': _selectedAction,
              'duration': _muteDuration,
            });
          },
          child: Text(_selectedAction == UserActionType.block ? 'Block' : 'Mute'),
        ),
      ],
    );
  }
} 