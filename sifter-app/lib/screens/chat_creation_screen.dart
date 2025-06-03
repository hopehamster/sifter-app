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
  double? _latitude;
  double? _longitude;
  double _selectedRadius = 100.0; // Default 100 meters
  bool _isLoadingLocation = false;
  bool _locationInitialized = false;
  String? _locationError;

  // Google Maps
  GoogleMapController? _mapController;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  bool _mapError = false;
  bool _showMap = true; // Make map standard - always visible
  bool _useSimpleView = false; // Fallback to simple view if map fails

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
    print('🔍 ChatCreationScreen: initState() called');

    // Set default location immediately - San Francisco
    _latitude = 37.7749;
    _longitude = -122.4194;

    // Check authentication without any location stuff
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
      _updateMapElements();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _pageController.dispose();

    // Dispose map controller to free memory
    _mapController?.dispose();

    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    print('🔍 ChatCreationScreen: _checkAuthentication() started');

    try {
      final authService = ref.read(authServiceProvider);
      print('🔍 ChatCreationScreen: AuthService obtained');

      if (authService.isAnonymousUser) {
        print(
            '🔍 ChatCreationScreen: User is anonymous, showing account creation dialog');
        if (mounted) {
          _showCreateAccountDialog();
        }
      } else {
        print(
            '🔍 ChatCreationScreen: User is authenticated, ready to create chat');
        // User is authenticated, interface is ready to use
      }
    } catch (e) {
      print('💥 ChatCreationScreen: Exception in _checkAuthentication: $e');
      if (mounted) {
        _showSnackBar('Authentication check failed: $e', isError: true);
      }
    }
  }

  Future<void> _useMyLocation() async {
    print('🔍 ChatCreationScreen: _useMyLocation() called');

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);

      // Try initialization with 3-second timeout
      final success = await Future.any([
        locationService.initialize(),
        Future.delayed(const Duration(seconds: 3), () => false)
      ]);

      if (!success) {
        throw Exception('Location service initialization timed out');
      }

      // Try to get position with 2-second timeout
      final position = await Future.any([
        Future(() => locationService.currentPosition),
        Future.delayed(const Duration(seconds: 2), () => null)
      ]);

      if (position != null && mounted) {
        print(
            '🔍 ChatCreationScreen: Got user location: ${position.latitude}, ${position.longitude}');
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingLocation = false;
          _locationInitialized = true;
        });

        _updateMapElements();
        _showSnackBar('Location updated to your current position!');
      } else {
        throw Exception('Could not get your current location');
      }
    } catch (e) {
      print('🔍 ChatCreationScreen: Failed to get user location: $e');

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Failed to get your location: $e';
        });

        _showSnackBar('Could not get your location. Using default location.',
            isError: true);
      }
    }
  }

  Future<void> _showCreateAccountDialog() async {
    print('🔍 ChatCreationScreen: _showCreateAccountDialog() started');

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          print('🔍 ChatCreationScreen: Dialog builder called');
          return AlertDialog(
            title: const Text('Account Required'),
            content: const Text(
              'You need to have an account in order to make chats. Creating an account unlocks the ability to create chat rooms and access all features.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🔍 ChatCreationScreen: User tapped Back in dialog');
                  Navigator.of(context).pop(false);
                },
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () {
                  print(
                      '🔍 ChatCreationScreen: User tapped Create Account in dialog');
                  Navigator.of(context).pop(true);
                },
                child: const Text('Create Account'),
              ),
            ],
          );
        },
      );

      print('🔍 ChatCreationScreen: Dialog closed with result: $result');

      if (!mounted) {
        print('🔍 ChatCreationScreen: Widget not mounted, returning');
        return;
      }

      if (result == true) {
        print(
            '🔍 ChatCreationScreen: User chose to create account, navigating back');
        // Navigate to account creation (Settings screen)
        Navigator.of(context).pop(); // Close chat creation screen
        // The main app will handle navigation to settings for account creation
      } else {
        print('🔍 ChatCreationScreen: User chose to go back, navigating back');
        // User chose to go back
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      print('💥 ChatCreationScreen: Exception in _showCreateAccountDialog: $e');
      print('📚 ChatCreationScreen: Stack trace: $stackTrace');
    }
  }

  void _updateMapElements() {
    if (_latitude == null || _longitude == null || !mounted) return;

    try {
      final center = LatLng(_latitude!, _longitude!);

      // Only update if we have a significant change to prevent excessive updates
      if (_markers.isNotEmpty) {
        final existingMarker = _markers.first;
        final distance = _calculateDistance(
          existingMarker.position.latitude,
          existingMarker.position.longitude,
          center.latitude,
          center.longitude,
        );
        if (distance < 10) return; // Skip update if less than 10 meters change
      }

      setState(() {
        // Update marker for center point (simplified)
        _markers = {
          Marker(
            markerId: const MarkerId('center'),
            position: center,
            infoWindow: const InfoWindow(title: 'Chat Center'),
          ),
        };

        // Update circle for radius (simplified)
        _circles = {
          Circle(
            circleId: const CircleId('radius'),
            center: center,
            radius: _selectedRadius,
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            strokeColor: Theme.of(context).colorScheme.primary,
            strokeWidth: 1,
          ),
        };
      });
    } catch (e) {
      print('🔍 Error in _updateMapElements: $e');
      // Don't crash if map elements can't be updated
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = (lat2 - lat1) * (3.14159 / 180);
    double dLon = (lon2 - lon1) * (3.14159 / 180);
    double a = (dLat / 2).abs() + (dLon / 2).abs();
    return earthRadius * 2 * a;
  }

  void _onRadiusChanged(double radius) {
    setState(() {
      _selectedRadius = radius;
    });
    _updateMapElements();
  }

  Future<void> _proceedToConfiguration() async {
    if (_latitude == null || _longitude == null) {
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
    if (_latitude == null || _longitude == null) {
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
        latitude: _latitude!,
        longitude: _longitude!,
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
    try {
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
    } catch (e, stackTrace) {
      print('🔍 Error in ChatCreationScreen build: $e');
      print('📚 Stack trace: $stackTrace');

      // Return error screen instead of crashing
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat Creation'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to load the chat creation screen',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLocationSelection() {
    return Column(
      children: [
        // Location Info Card
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _locationInitialized
                                  ? Icons.location_on
                                  : Icons.location_city,
                              color: _locationInitialized
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.secondary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locationInitialized
                                        ? 'Your Location'
                                        : 'Default Location',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    _locationInitialized
                                        ? 'Chat center set to your current position'
                                        : 'San Francisco, CA (Default)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_locationError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
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
                                    _locationError!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Coordinates',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text('Latitude: '),
                                  Text(
                                    _latitude?.toStringAsFixed(6) ?? 'N/A',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Longitude: '),
                                  Text(
                                    _longitude?.toStringAsFixed(6) ?? 'N/A',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                _isLoadingLocation ? null : _useMyLocation,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(_isLoadingLocation
                                ? 'Getting Location...'
                                : 'Use My Current Location'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You can use the default location or get your current position. Your chat room will be centered at this location.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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

        // Map View
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: _buildMapWidget(),
            ),
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
                'People can join your chat when they are within this radius of the center location.',
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
                  onPressed: _latitude != null &&
                          _longitude != null &&
                          !_isLoadingLocation
                      ? _proceedToConfiguration
                      : null,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue to Configuration'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapWidget() {
    if (_latitude == null || _longitude == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_mapError || _useSimpleView) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _mapError ? 'Map failed to load' : 'Simple Location View',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Radius: ${_selectedRadius.round()}m',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            if (_mapError) ...[
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _mapError = false;
                  });
                },
                child: const Text('Retry Map'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _useSimpleView = !_useSimpleView;
                  if (_useSimpleView) {
                    _mapError = false;
                  }
                });
              },
              child: Text(_useSimpleView ? 'Show Map' : 'Use Simple View'),
            ),
          ],
        ),
      );
    }

    // Wrap GoogleMap in multiple layers of error handling
    return SafeArea(
      child: Builder(
        builder: (context) {
          try {
            return GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                try {
                  _mapController = controller;
                  // Use a delay to ensure map is ready before updating elements
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _updateMapElements();
                    }
                  });
                } catch (e) {
                  print('🔍 Error in onMapCreated: $e');
                  if (mounted) {
                    setState(() {
                      _mapError = true;
                      _useSimpleView = true; // Auto-fallback to simple view
                    });
                  }
                }
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(_latitude!, _longitude!),
                zoom: 15.0, // Reduced zoom for better performance
              ),
              markers: _markers,
              circles: _circles,
              // Memory optimization settings
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              buildingsEnabled: false,
              trafficEnabled: false,
              indoorViewEnabled: false,
              mapType: MapType.normal,
              onTap: (LatLng position) {
                // Allow user to tap on map to change location
                try {
                  setState(() {
                    _latitude = position.latitude;
                    _longitude = position.longitude;
                  });
                  _updateMapElements();
                } catch (e) {
                  print('🔍 Error in onTap: $e');
                }
              },
            );
          } catch (e) {
            print('🔍 Error creating GoogleMap: $e');
            // If map creation fails, automatically switch to simple view
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _mapError = true;
                  _useSimpleView = true;
                });
              }
            });
            return Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(
                child: Text('Switching to simple view...'),
              ),
            );
          }
        },
      ),
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
