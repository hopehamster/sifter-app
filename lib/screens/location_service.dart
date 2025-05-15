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
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    await _location.enableBackgroundMode(enable: true);
  }

  static Future<void> disableLocation() async {
    await _location.enableBackgroundMode(enable: false);
  }
}
