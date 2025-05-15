import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sifter/screens/admin_panel_screen.dart';
import 'package:sifter/screens/auth/login_screen.dart';
import 'package:sifter/screens/chat/chat_screen.dart';
import 'package:sifter/screens/chat/chat_selection.dart';
import 'package:sifter/screens/profile_screen.dart';
import 'package:sifter/providers/auth_provider.dart' as s;
import 'package:sifter/widgets/setradius.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _navigateToAdmin = false;

  final List<Widget> _screens = [
    ChatSelectionScreen(),
    ChatScreen(roomId: 'default_room'), // Placeholder roomId
    ProfileScreen(),
  ];
  void _onItemTapped(int index) {
    final authProvider = Provider.of<s.AuthProvider>(context, listen: false);

    if (index == 0 && authProvider.user == null) {
      // Prompt for sign-in when trying to create a chat
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sign In Required'),
          content: Text(
              'You need to sign in to create a chat. Would you like to sign in now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    if (index == 0 && authProvider.user != null) {
      // Navigate to chat creation flow
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SetRadiusScreen()),
      );
      return;
    }

    if (index == 2) {
      // Long-press on Profile tab to access admin panel
      _navigateToAdmin = true;
    } else {
      setState(() {
        _selectedIndex = index;
        _navigateToAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<s.AuthProvider>(context);

    if (_navigateToAdmin && authProvider.isAdmin) {
      _navigateToAdmin = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminPanelScreen()),
        );
      });
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF2196F3),
        unselectedItemColor: Color(0xFFB0BEC5),
        onTap: _onItemTapped,
      ).animate().scale(duration: 200.ms),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Your existing LoginScreen and other screens would go here
