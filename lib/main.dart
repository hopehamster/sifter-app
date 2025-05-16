import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sifter/firebase_options.dart';
import 'package:sifter/providers/riverpod/auth_provider.dart';
import 'package:sifter/screens/bottomNav/bottom_nav.dart';
import 'package:sifter/screens/chat/chat_screen.dart';
import 'package:sifter/screens/auth/login_screen.dart';
import 'package:sifter/screens/profile_screen.dart';
import 'package:sifter/screens/settings_screen.dart';
import 'package:sifter/screens/admin_panel_screen.dart';
import 'package:sifter/screens/chat/create_room_screen.dart';
import 'package:sifter/screens/splash/splash_screen.dart';
import 'package:sifter/services/location_service.dart';
import 'package:sifter/services/notification_service.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/encryption_service.dart';
import 'package:sifter/services/background_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sifter/utils/error_handler.dart';
import 'package:sifter/utils/security.dart';

// Provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Provider for theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  await NotificationService().handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();
  
  // Initialize Firebase Realtime Database
  final firebaseApp = Firebase.app();
  final rtdb = FirebaseDatabase.instanceFor(
      app: firebaseApp,
      databaseURL: 'https://sifter-v20-default-rtdb.firebaseio.com/');
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  // Initialize Firebase Cloud Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize services
  await NotificationService().init();
  await AnalyticsService().init();
  await EncryptionService().init();
  await BackgroundService().init();
  
  // Store support contact information securely
  await _storeSupportContactInfo();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    ),
  );
}

// Store support contact information securely
Future<void> _storeSupportContactInfo() async {
  try {
    // Check if the support WhatsApp number is already stored
    final hasWhatsApp = await SecurityUtils.hasSecureData('support_whatsapp');
    
    if (!hasWhatsApp) {
      // Get your WhatsApp number from environment variables or a secure config file
      // to avoid hardcoding it in the source code
      final whatsappNumber = dotenv.env['SUPPORT_WHATSAPP_NUMBER'] ?? '';
      
      if (whatsappNumber.isNotEmpty) {
        // Store the number securely
        await SecurityUtils.saveSecureData('support_whatsapp', whatsappNumber);
      }
    }
  } catch (e) {
    debugPrint('Error storing support contact info: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'Sifter',
      theme: ThemeData.light().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    
    return authState.when(
      data: (user) => user == null ? const LoginScreen() : const BottomNavScreen(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorScreen(
        message: error.toString(),
        onRetry: () => ref.refresh(authStateChangesProvider),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'An error occurred',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(BuildContext, Object, StackTrace) onError;

  const ErrorBoundary({
    required this.child,
    required this.onError,
    super.key,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear error state when dependencies change
    if (_error != null) {
      setState(() {
        _error = null;
        _stack = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.onError(context, _error!, _stack!);
    }

    return ErrorWidget.builder = (FlutterErrorDetails details) {
      // Capture the error
      _error = details.exception;
      _stack = details.stack;
      
      // Return error screen
      return widget.onError(context, _error!, _stack!);
    };
  }
}
