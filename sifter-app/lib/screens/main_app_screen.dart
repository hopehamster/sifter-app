import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_creation_screen.dart';
import 'chat_join_screen.dart';
import 'settings_screen.dart';

class MainAppScreen extends ConsumerStatefulWidget {
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  int _currentIndex = 1; // Start with Chat Selection/Join tab (middle)

  final List<Widget> _screens = const [
    ChatCreationTabScreen(),
    ChatJoinTabScreen(),
    SettingsScreen(),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _navigateToCreateChat() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatCreationScreen(),
      ),
    );

    // If chat creation was successful, refresh and switch to selection tab
    if (result == true && mounted) {
      setState(() {
        _currentIndex = 1; // Switch to Chat Selection/Join
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Chat Creation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat Selection/Join',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateChat,
        tooltip: 'Create Chat Room',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Tab screen wrapper for Chat Creation
class ChatCreationTabScreen extends StatelessWidget {
  const ChatCreationTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Chat Room'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Create a New Chat Room',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Set up a location-based chat room for people in your area to join and connect.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatCreationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Start Creating'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tab screen wrapper for Chat Join - simplified version without its own bottom nav
class ChatJoinTabScreen extends ConsumerStatefulWidget {
  const ChatJoinTabScreen({super.key});

  @override
  ConsumerState<ChatJoinTabScreen> createState() => _ChatJoinTabScreenState();
}

class _ChatJoinTabScreenState extends ConsumerState<ChatJoinTabScreen> {
  // This will use the same logic as ChatJoinScreen but without bottom navigation
  // For now, let's use the existing ChatJoinScreen but we'll need to modify it
  @override
  Widget build(BuildContext context) {
    // Temporarily return the existing ChatJoinScreen
    // We'll need to extract its content without the bottom nav
    return const ChatJoinScreen();
  }
}
