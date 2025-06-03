import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/analytics_service.dart';

void main() async {
  print('🚀 App starting...');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('💥 Firebase initialization failed: $e');
    print('📚 Stack trace: $stackTrace');
  }

  // Enable verbose logging in debug mode
  if (kDebugMode) {
    print('🔍 Debug mode enabled - verbose logging active');
  }

  // Initialize Firebase Chat Core
  FirebaseChatCore.instance.setConfig(
    const FirebaseChatCoreConfig(
      null, // We'll provide user dynamically
      'rooms', // Collection name for rooms
      'users', // Collection name for users
    ),
  );

  print('🎯 Launching app...');
  runApp(
    const ProviderScope(
      child: SifterApp(),
    ),
  );
}

class SifterApp extends ConsumerStatefulWidget {
  const SifterApp({super.key});

  @override
  ConsumerState<SifterApp> createState() => _SifterAppState();
}

class _SifterAppState extends ConsumerState<SifterApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize();
      ref.read(settingsServiceProvider).initialize();
      ref.read(analyticsServiceProvider).initialize();

      // Track app open
      ref.read(analyticsServiceProvider).trackAppOpen();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final analytics = ref.read(analyticsServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        analytics.trackAppStateChange('resumed');
        break;
      case AppLifecycleState.paused:
        analytics.trackAppStateChange('paused');
        break;
      case AppLifecycleState.detached:
        analytics.trackAppClosed();
        break;
      case AppLifecycleState.inactive:
        analytics.trackAppStateChange('inactive');
        break;
      case AppLifecycleState.hidden:
        analytics.trackAppStateChange('hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Sifter Chat',
      scaffoldMessengerKey: GlobalScaffoldKey.key,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Global key for scaffold messenger (for snackbars)
class GlobalScaffoldKey {
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();
}
