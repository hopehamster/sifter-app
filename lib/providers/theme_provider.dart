import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }
  
  ThemeData get lightTheme => ThemeData(
    primaryColor: Color(0xFF2196F3),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
    ),
    iconTheme: IconThemeData(color: Color(0xFF2196F3)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF64B5F6),
      surface: Colors.white,
      background: Colors.white,
      error: Colors.red,
    ),
  );
  
  ThemeData get darkTheme => ThemeData(
    primaryColor: Color(0xFF2196F3),
    scaffoldBackgroundColor: Color(0xFF121212),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
    ),
    iconTheme: IconThemeData(color: Color(0xFF2196F3)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF64B5F6),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Colors.red,
    ),
  );
} 