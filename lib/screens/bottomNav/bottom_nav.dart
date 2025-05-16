import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/providers/riverpod/auth_provider.dart';
import 'package:sifter/screens/admin_panel_screen.dart';
import 'package:sifter/screens/auth/login_screen.dart';
import 'package:sifter/screens/chat/chat_screen.dart';
import 'package:sifter/screens/chat/chat_selection.dart';
import 'package:sifter/screens/profile_screen.dart';
import 'package:sifter/widgets/setradius.dart';

class BottomNavScreen extends ConsumerStatefulWidget {
  const BottomNavScreen({super.key});

  @override
  ConsumerState<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends ConsumerState<BottomNavScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _navigateToAdmin = false;

  final List<Widget> _screens = [
    const ChatSelectionScreen(),
    const ChatScreen(roomId: 'default_room'), // Placeholder roomId
    const ProfileScreen(),
  ];
  
  void _onItemTapped(int index) {
    final authState = ref.watch(authNotifierProvider);

    if (index == 0 && authState.value == null) {
      // Prompt for sign-in when trying to create a chat
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign In Required'),
          content: const Text(
              'You need to sign in to create a chat. Would you like to sign in now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    if (index == 0 && authState.value != null) {
      // Navigate to chat creation flow
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SetRadiusScreen()),
      );
      return;
    }

    if (index == 2) {
      // Long-press on Profile tab to access admin panel if user is admin
      _checkAdminStatus();
    } else {
      setState(() {
        _selectedIndex = index;
        _pageController.jumpToPage(index);
        _navigateToAdmin = false;
      });
    }
  }

  void _checkAdminStatus() {
    // This would need to be implemented based on your admin status logic
    // For now, we'll just navigate to the profile page
    setState(() {
      _selectedIndex = 2;
      _pageController.jumpToPage(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: const Color(0xFFB0BEC5),
        onTap: _onItemTapped,
      ).animate().scale(duration: const Duration(milliseconds: 200)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Your existing LoginScreen and other screens would go here
