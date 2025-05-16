import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetRadiusScreen extends ConsumerStatefulWidget {
  const SetRadiusScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SetRadiusScreen> createState() => _SetRadiusScreenState();
}

class _SetRadiusScreenState extends ConsumerState<SetRadiusScreen> {
  double _radius = 5.0; // Default 5km radius
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Search Radius'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Chat Search Radius',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adjust the radius to find chats around your current location.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_radius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _radius,
              min: 0.5,
              max: 20.0,
              divisions: 39,
              label: '${_radius.toStringAsFixed(1)} km',
              onChanged: (value) {
                setState(() {
                  _radius = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('0.5 km'),
                const Text('20 km'),
              ],
            ),
            const SizedBox(height: 48),
            const Text(
              'Location Based Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue),
              title: Text('Connect with people nearby'),
              subtitle: Text('Find location-based chat rooms'),
            ),
            const ListTile(
              leading: Icon(Icons.public, color: Colors.blue),
              title: Text('Discover local events'),
              subtitle: Text('Join discussions happening around you'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Handle the radius setting
                  Navigator.pop(context, _radius);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
