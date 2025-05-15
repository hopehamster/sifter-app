import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../widgets/logout_dialog.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    setState(() => _locationEnabled = await LocationService.isLocationEnabled());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Enable Location Sharing'),
            activeColor: Color(0xFF2196F3),
            value: _locationEnabled,
            onChanged: (value) async {
              setState(() => _locationEnabled = value);
              if (value) {
                await LocationService.enableLocation();
              } else {
                await LocationService.disableLocation();
              }
            },
          ),
          if (authProvider.user?.isAnonymous ?? true) // Show for anonymous users
            ListTile(
              title: Text('Create Account'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              ),
            ),
          if (!(authProvider.user?.isAnonymous ?? true)) // Show Log Out for non-anonymous users
            ListTile(
              title: Text('Log Out'),
              onTap: () => showDialog(
                context: context,
                builder: (_) => LogoutDialog(),
              ),
            ),
        ],
      ),
    );
  }
}