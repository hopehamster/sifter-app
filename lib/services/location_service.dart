import 'package:location/location.dart';

class LocationService {
  static final Location _location = Location();

  static Future<bool> isLocationEnabled() async {
    return await _location.serviceEnabled();
  }

  static Future<void> enableLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        throw Exception('Location permissions are denied.');
      }
    }
  }

  static Future<void> disableLocation() async {
    // Placeholder for disabling location; typically handled by user settings
  }
}