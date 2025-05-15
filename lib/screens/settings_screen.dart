import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart' as d;
// import 'package:sifter/providers/auth_provider.dart' as ad;
import 'package:sifter/providers/auth_provider.dart' as e;

import '../services/location_service.dart';

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
    setState(() async =>
        _locationEnabled = await LocationService.isLocationEnabled());
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
