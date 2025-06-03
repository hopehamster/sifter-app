import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_creation_screen.dart';
import 'settings_screen.dart';
import '../services/location_service.dart';

class MainAppScreen extends ConsumerStatefulWidget {
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  Future<void> navigateToCreateChat() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatCreationScreen(),
      ),
    );

    // If chat creation was successful, refresh
    if (result == true && mounted) {
      // Could trigger a refresh here if needed
    }
  }

  void navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: ChatJoinContentOnly(
              onCreateChatPressed: navigateToCreateChat,
              onSettingsPressed: navigateToSettings,
            ),
          ),
          // Fixed advertisement banner at bottom
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '🎯 Advertisement Banner',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New widget that contains only the content without bottom navigation
class ChatJoinContentOnly extends ConsumerStatefulWidget {
  final VoidCallback? onCreateChatPressed;
  final VoidCallback? onSettingsPressed;

  const ChatJoinContentOnly({
    super.key,
    this.onCreateChatPressed,
    this.onSettingsPressed,
  });

  @override
  ConsumerState<ChatJoinContentOnly> createState() =>
      _ChatJoinContentOnlyState();
}

class _ChatJoinContentOnlyState extends ConsumerState<ChatJoinContentOnly> {
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final success = await locationService.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = success ? null : 'Location services not available';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize location: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sifter Chat'),
          automaticallyImplyLeading: false,
          actions: [
            // Settings gear icon
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: widget.onSettingsPressed,
              tooltip: 'Settings',
            ),
            // Create new chat plus icon
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: widget.onCreateChatPressed,
              tooltip: 'New Chat',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing location services...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sifter Chat'),
          automaticallyImplyLeading: false,
          actions: [
            // Settings gear icon
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: widget.onSettingsPressed,
              tooltip: 'Settings',
            ),
            // Create new chat plus icon
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: widget.onCreateChatPressed,
              tooltip: 'New Chat',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initializeLocation();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Add refresh functionality for eligible rooms
            },
            tooltip: 'Refresh',
          ),
          // Settings gear icon
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: widget.onSettingsPressed,
            tooltip: 'Settings',
          ),
          // Create new chat plus icon
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onCreateChatPressed,
            tooltip: 'New Chat',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chat rooms list placeholder
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Chat Rooms Nearby',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'There are no active chat rooms in your current location. Be the first to create one!',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                      maxLines: null, // Allow text wrapping
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onCreateChatPressed,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Chat Room'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
