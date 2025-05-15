import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sifter/admin/admin_screen.dart';
import 'package:sifter/screens/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
// import '../widgets/logout_dialog.dart';
import 'settings_screen.dart';
import 'package:sifter/providers/auth_provider.dart' as s;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _displayNameController.text = user?.displayName ?? '';
  }

  Future<void> _updateDisplayName() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }
    await _db
        .child('users/$userId/displayName')
        .set(_displayNameController.text);
    await Provider.of<AuthProvider>(context, listen: false)
        .user
        ?.updateDisplayName(_displayNameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2196F3)),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final authProvider =
                    Provider.of<s.AuthProvider>(context, listen: false);
                setState(() {
                  authProvider.isAdmin = true;
                });
                if (authProvider.isAdmin) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminPanelScreen()),
                    );
                  });
                }
              },
              child: Text('Become Admin'),
            ),
            ElevatedButton(
              onPressed: _updateDisplayName,
              child: Text('Update Name'),
            ),
            SizedBox(height: 10),
            Text('Email: ${authProvider.user?.email ?? 'Anonymous'}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              ),
              child: Text('Settings'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => LogoutDialog(),
              ),
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log Out'),
      content: Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('No', style: TextStyle(color: Color(0xFF2196F3))),
        ).animate().shake(duration: 300.ms),
        TextButton(
          onPressed: () async {
            await Provider.of<s.AuthProvider>(context, listen: false)
                .logout(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => SplashScreen()),
            );
            await Future.delayed(Duration(seconds: 2));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('See You Soon!').animate().fadeIn(),
                backgroundColor: Color(0xFF2196F3),
              ),
            );
          },
          child: Text('Yes', style: TextStyle(color: Color(0xFF2196F3))),
        ),
      ],
    );
  }
}
