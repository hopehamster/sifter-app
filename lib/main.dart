import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sifter/firebase_options.dart';
import 'package:sifter/providers/auth_provider.dart';
import 'package:sifter/providers/auth_provider.dart' as d;
import 'package:sifter/screens/bottomNav/bottom_nav.dart';
import 'package:sifter/screens/chat/chat_screen.dart';
import 'package:sifter/screens/auth/login_screen.dart';
import 'package:sifter/screens/profile_screen.dart';
import 'package:sifter/screens/settings_screen.dart';
import 'package:sifter/screens/admin_panel_screen.dart';
import 'package:sifter/screens/chat/create_room_screen.dart';
import 'package:sifter/screens/splash/splash_screen.dart';
import 'package:sifter/services/location_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  // await dotenv.load(fileName: ".env");
  final firebaseApp = Firebase.app();
  final rtdb = FirebaseDatabase.instanceFor(
      app: firebaseApp,
      databaseURL: 'https://sifter-v20-default-rtdb.firebaseio.com/');

  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => d.AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeData sifterTheme = ThemeData(
    primaryColor: Color(0xFF2196F3), // Sifter blue
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
      titleLarge:
          TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
    ),
    iconTheme: IconThemeData(color: Color(0xFF2196F3)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Sifter', theme: sifterTheme, home: SplashScreen()
        // home: const AuthWrapper(),

        // routes: {
        //   '/': (context) => SplashScreen(),
        //   '/login': (context) => const LoginScreen(),
        //   '/chat': (context) => ChatScreen(),
        //   '/profile': (context) => ProfileScreen(),
        //   '/settings': (context) => SettingsScreen(),
        //   '/admin': (context) => AdminPanelScreen(),
        //   '/create_room': (context) => CreateRoomScreen(),
        // },
        );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<d.AuthProvider>(context);
    final auths = FirebaseAuth.instance; // Directly use FirebaseAuth

    return StreamBuilder<User?>(
      stream: auths.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user == null ? const LoginScreen() : MainScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
