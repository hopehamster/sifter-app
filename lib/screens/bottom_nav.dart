import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'set_radius_screen.dart';
import 'chat_selection_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'admin_panel_screen.dart';
import 'login_screen.dart';

class BottomNav extends StatefulWidget {
  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  bool _navigateToAdmin = false;

  final List<Widget> _screens = [
    ChatSelectionScreen(),
    ChatScreen(roomId: 'default_room'), // Placeholder roomId
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (index == 0) {
      // Check if user is anonymous
      if (authProvider.user?.isAnonymous ?? true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Create an Account'),
            content: Text('You need to create an account to start a chat. Would you like to sign in or sign up now?'),
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
                child: Text('Sign In / Sign Up'),
              ),
            ],
          ),
        );
        return;
      }
      // Navigate to chat creation flow for authenticated users
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
    final authProvider = Provider.of<AuthProvider>(context);

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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF2196F3),
        unselectedItemColor: Color(0xFFB0BEC5),
        onTap: _onItemTapped,
      ).animate().scale(duration: 200.ms),
    );
  }
}