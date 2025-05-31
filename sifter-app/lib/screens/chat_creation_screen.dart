import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../services/chat_room_service.dart';
import '../services/auth_service.dart';
import '../services/password_service.dart';
import '../services/content_filter_service.dart';

class ChatCreationScreen extends ConsumerStatefulWidget {
  const ChatCreationScreen({super.key});

  @override
  ConsumerState<ChatCreationScreen> createState() => _ChatCreationScreenState();
}

class _ChatCreationScreenState extends ConsumerState<ChatCreationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Location Selection (Step 1)
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  double _selectedRadius = 100.0; // Default 100 meters
  Set<Circle> _circles = {};

  // Chat Configuration (Step 2)
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordProtected = false;
  bool _isNSFW = false;
  bool _allowAnonymous = true;
  int _maxMembers = 50;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndProceed();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationAndProceed() async {
    final authService = ref.read(authServiceProvider);

    // Check if user is anonymous (Entry Point #3)
    if (authService.isAnonymousUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateAccountDialog();
      });
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _showCreateAccountDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Required'),
        content: const Text(
          'You need to have an account in order to make chats. Creating an account unlocks the ability to create chat rooms and access all features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // Navigate to account creation (Settings screen)
      Navigator.of(context).pop(); // Close chat creation screen
      // The main app will handle navigation to settings for account creation
    } else {
      // User chose to go back
      Navigator.of(context).pop();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = locationService.currentPosition;

      if (position != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _updateCircle();
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 16.0),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to get current location: $e', isError: true);
      }
    }
  }

  void _updateCircle() {
    if (_selectedLocation == null) return;

    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('geofence'),
          center: _selectedLocation!,
          radius: _selectedRadius,
          fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          strokeColor: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _onRadiusChanged(double radius) {
    setState(() {
      _selectedRadius = radius;
      _updateCircle();
    });
  }

  Future<void> _proceedToConfiguration() async {
    if (_selectedLocation == null) {
      _showSnackBar('Current location not available', isError: true);
      return;
    }

    setState(() => _currentStep = 1);
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goBackToLocation() async {
    setState(() => _currentStep = 0);
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createChatRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showSnackBar('Current location not available', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final chatRoomService = ref.read(chatRoomServiceProvider);
      final contentFilterService = ref.read(contentFilterServiceProvider);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        _showSnackBar('You must be logged in to create a chat room',
            isError: true);
        return;
      }

      // ✅ Content Validation
      final roomName = _nameController.text.trim();
      final roomDescription = _descriptionController.text.trim();

      // Validate room name
      if (!contentFilterService.isRoomNameAppropriate(roomName)) {
        _showSnackBar(
            'Room name contains inappropriate content. Please choose a different name.',
            isError: true);
        return;
      }

      // Validate description if provided
      if (roomDescription.isNotEmpty) {
        final descriptionValidation = contentFilterService.validateMessage(
          roomDescription,
          isNSFWRoom: _isNSFW,
        );

        if (!descriptionValidation.isValid) {
          _showSnackBar('Room description: ${descriptionValidation.reason}',
              isError: true);
          return;
        }
      }

      // Check if user is of legal age for NSFW content
      if (_isNSFW) {
        final isOfAge = await authService.isUserOfLegalAge();
        if (!isOfAge) {
          _showSnackBar('You must be 18+ to create NSFW content',
              isError: true);
          return;
        }
      }

      final roomId = await chatRoomService.createChatRoom(
        name: roomName,
        description: roomDescription,
        creatorId: currentUser.uid,
        creatorName: currentUser.displayName ?? 'Anonymous',
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        radiusInMeters: _selectedRadius,
        isPasswordProtected: _isPasswordProtected,
        password: _isPasswordProtected ? _passwordController.text : null,
        isNsfw: _isNSFW,
        allowAnonymous: _allowAnonymous,
        maxMembers: _maxMembers,
      );

      if (roomId != null) {
        // Award points for creating a chat room
        final userProfile = await authService.getUserProfile();
        if (userProfile != null) {
          await authService.updateUserProfile();
          // Could implement point system here
        }

        _showSnackBar('Chat room created successfully!');
        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      } else {
        _showSnackBar('Failed to create chat room. Please try again.',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Error creating chat room: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Set Chat Radius' : 'Configure Chat'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_currentStep == 1)
            TextButton(
              onPressed: _goBackToLocation,
              child: const Text('Back'),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildLocationSelection(),
          _buildChatConfiguration(),
        ],
      ),
    );
  }

  Widget _buildLocationSelection() {
    return Column(
      children: [
        // Map
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (_selectedLocation != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_selectedLocation!, 16.0),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ??
                      const LatLng(37.7749, -122.4194), // Default to SF
                  zoom: 16.0,
                ),
                circles: _circles,
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('current_location'),
                          position: _selectedLocation!,
                          infoWindow: const InfoWindow(
                              title: 'Your Location (Chat Center)'),
                        ),
                      }
                    : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),

              // Location Info Overlay
              if (_selectedLocation != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your Current Location',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chat room center (fixed)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Radius Controls
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat Room Radius: ${_selectedRadius.round()} meters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _selectedRadius,
                min: 50.0,
                max: 500.0,
                divisions: 45,
                label: '${_selectedRadius.round()}m',
                onChanged: _onRadiusChanged,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('50m', style: Theme.of(context).textTheme.bodySmall),
                  Text('500m', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your chat room will be centered at your current location. Adjust the radius to determine how far from you people can join the conversation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedLocation != null
                      ? _proceedToConfiguration
                      : null,
                  child: const Text('Continue to Configuration'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatConfiguration() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Chat Room Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Chat Room Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a chat room name';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        if (value.trim().length > 50) {
                          return 'Name must be less than 50 characters';
                        }
                        return null;
                      },
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      validator: (value) {
                        if (value != null && value.trim().length > 200) {
                          return 'Description must be less than 200 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Room Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Maximum Members
                    Row(
                      children: [
                        const Icon(Icons.people_outline),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maximum Members: $_maxMembers',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: _maxMembers.toDouble(),
                                min: 2.0,
                                max: 100.0,
                                divisions: 98,
                                label: '$_maxMembers',
                                onChanged: (value) {
                                  setState(() {
                                    _maxMembers = value.round();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(),

                    // Password Protection
                    SwitchListTile(
                      title: const Text('Password Protected'),
                      subtitle: const Text('Require a password to join'),
                      value: _isPasswordProtected,
                      onChanged: (value) {
                        setState(() {
                          _isPasswordProtected = value;
                          if (!value) {
                            _passwordController.clear();
                          }
                        });
                      },
                      secondary: const Icon(Icons.lock_outline),
                    ),

                    if (_isPasswordProtected) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Room Password *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.key),
                          suffixIcon: _passwordController.text.isNotEmpty
                              ? _buildPasswordStrengthIcon()
                              : null,
                          helperText: _passwordController.text.isNotEmpty
                              ? _getPasswordStrengthMessage()
                              : 'Enter a secure password for your room',
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(
                              () {}); // Trigger rebuild for strength indicator
                        },
                        validator: (value) {
                          if (_isPasswordProtected &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter a password';
                          }
                          if (_isPasswordProtected && value != null) {
                            final strength =
                                PasswordService.validatePasswordStrength(value);
                            if (!strength.isValid) {
                              return strength.message;
                            }
                          }
                          return null;
                        },
                        maxLength: 50,
                      ),
                    ],

                    const Divider(),

                    // Anonymous Access
                    SwitchListTile(
                      title: const Text('Allow Anonymous Users'),
                      subtitle: const Text('Let users join without accounts'),
                      value: _allowAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _allowAnonymous = value;
                        });
                      },
                      secondary: const Icon(Icons.person_off_outlined),
                    ),

                    const Divider(),

                    // NSFW Content
                    SwitchListTile(
                      title: const Text('NSFW Content'),
                      subtitle: const Text('18+ only, not visible to minors'),
                      value: _isNSFW,
                      onChanged: (value) {
                        setState(() {
                          _isNSFW = value;
                        });
                      },
                      secondary: Icon(
                        Icons.warning_outlined,
                        color: _isNSFW
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),

                    if (_isNSFW)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'NSFW rooms are only visible to verified 18+ users',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _createChatRoom,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Chat Room'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIcon() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    final strength =
        PasswordService.validatePasswordStrength(_passwordController.text);

    switch (strength.strength) {
      case PasswordStrength.weak:
        return const Icon(Icons.security, color: Colors.red);
      case PasswordStrength.medium:
        return const Icon(Icons.security, color: Colors.orange);
      case PasswordStrength.strong:
        return const Icon(Icons.verified_user, color: Colors.green);
    }
  }

  String _getPasswordStrengthMessage() {
    if (_passwordController.text.isEmpty) return '';

    final strength =
        PasswordService.validatePasswordStrength(_passwordController.text);
    return strength.message;
  }
}
