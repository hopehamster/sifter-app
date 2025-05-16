import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../services/points_service.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  final String currentUserId;

  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordProtected = false;
  bool _isPrivate = false;
  double _radius = 10.0; // Default radius in kilometers
  LocationData? _currentLocation;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = Location();
      final locationData = await location.getLocation();
      setState(() => _currentLocation = locationData);
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentLocation == null) {
      setState(() => _error = 'Location is required to create a group');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final pointsService = ref.read(pointsServiceProvider);

      final group = await chatService.createChatRoom(
        name: _nameController.text,
        memberIds: [widget.currentUserId],
        description: _descriptionController.text,
        isGroup: true,
        metadata: {
          'location': {
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
          },
          'radius': _radius,
          'isPrivate': _isPrivate,
          'isPasswordProtected': _isPasswordProtected,
          if (_isPasswordProtected) 'password': _passwordController.text,
        },
      );

      // Reward points for creating a group
      await pointsService.rewardForGroupCreation(widget.currentUserId);

      if (mounted) {
        Navigator.pop(context, group);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create group: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter a name for your group',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your group',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Password Protected'),
              subtitle: const Text('Require password to join'),
              value: _isPasswordProtected,
              onChanged: (value) => setState(() => _isPasswordProtected = value),
            ),
            if (_isPasswordProtected) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter group password',
                ),
                validator: (value) {
                  if (_isPasswordProtected && (value == null || value.isEmpty)) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Private Group'),
              subtitle: const Text('Only visible to members'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Group Radius'),
              subtitle: Text('${_radius.toStringAsFixed(1)} km'),
            ),
            Slider(
              value: _radius,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radius.toStringAsFixed(1)} km',
              onChanged: (value) => setState(() => _radius = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Group'),
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