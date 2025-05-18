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
import 'package:sifter/screens/map_discovery_screen.dart';
import 'package:sifter/screens/nearby_chats_screen.dart';
import 'package:sifter/screens/onboarding_screen.dart';
import 'package:sifter/services/location_service.dart';
import 'package:sifter/services/notification_service.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sifter/utils/error_handler.dart';
import 'package:sifter/utils/security.dart';
import 'package:sifter/utils/optimization_manager.dart';
import 'package:sifter/utils/performance_monitor.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'screens/home_screen.dart';

// Provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Provider for theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

// Provider for optimization manager - for internal use only 
final optimizationManagerProvider = Provider<OptimizationManager>((ref) {
  return OptimizationManager.instance;
});

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  await NotificationService().handleBackgroundMessage(message);
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Check for nearby chats
      if (task == 'checkNearbyChats') {
        final locationService = LocationService(null);
        await locationService.checkNearbyChatsAndNotify();
      }
      
      return true;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}

Future<void> main() async {
  // Catch top-level errors for better crash handling
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await _initializeFirebase();
    
    // Initialize services in parallel where possible
    await Future.wait([
      dotenv.load(fileName: ".env").catchError(_handleInitError('env file')),
      EasyLocalization.ensureInitialized().catchError(_handleInitError('localization')),
    ]);
    
    // Initialize critical services that depend on Firebase
    await _initializeCriticalServices();
    
    // Initialize optimization framework with fallbacks
    await _initializeOptimization();
    
    // Store support contact information securely 
    await _storeSupportContactInfo();
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Initialize Workmanager for background tasks
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Register periodic task to check for nearby chats
    await Workmanager().registerPeriodicTask(
      'checkNearbyChats',
      'checkNearbyChats',
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
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
  }, (error, stack) {
    // Handle uncaught asynchronous errors
    debugPrint('Unhandled error in main: $error');
    debugPrint(stack.toString());
    // Could report to crash reporting service here
  });
}

// Initialize Firebase with error handling
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
    
    // Initialize Firebase Realtime Database with retry
    await _initializeFirebaseDB();
    
    // Initialize Firebase Cloud Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue despite Firebase errors - the app might still work with reduced functionality
  }
}

// Initialize Firebase DB with retry
Future<void> _initializeFirebaseDB() async {
  // Use retry pattern for initialization
  int retries = 3;
  while (retries > 0) {
    try {
      final firebaseApp = Firebase.app();
      final rtdb = FirebaseDatabase.instanceFor(
          app: firebaseApp,
          databaseURL: 'https://sifter-v20-default-rtdb.firebaseio.com/');
      
      // Fixed void function usage
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      break; // Successful, exit retry loop
    } catch (e) {
      retries--;
      if (retries == 0) {
        debugPrint('Failed to initialize Firebase Realtime Database after all retries: $e');
        // Continue with app launch, but some features may not work
      } else {
        debugPrint('Error initializing Firebase Realtime Database, retrying... ($retries left): $e');
        await Future.delayed(Duration(seconds: 1)); // Wait before retry
      }
    }
  }
}

// Initialize critical services
Future<void> _initializeCriticalServices() async {
  // Initialize services with parallel execution and error handling
  final services = await Future.wait([
    NotificationService().handleInitialization().catchError(_handleInitError('notifications')),
    AnalyticsService().logAppStart().catchError(_handleInitError('analytics')),
  ]);
}

// Generic error handler for initialization 
Function _handleInitError(String serviceName) {
  return (error) {
    debugPrint('Error initializing $serviceName: $error');
    // Return null to allow Future.wait to continue despite errors
    return null;
  };
}

// Initialize the app optimization system with appropriate defaults
Future<void> _initializeOptimization() async {
  // Setup watchdog for initialization - ensure it doesn't hang
  var isInitCompleted = false;
  Timer? watchdog = Timer(Duration(seconds: 10), () {
    if (!isInitCompleted) {
      debugPrint('Optimization initialization watchdog timeout - using defaults');
      // Initialize with safe defaults if it hangs
      _applyDefaultOptimizations();
    }
  });
  
  try {
    // First check device RAM to determine if we need more aggressive optimizations
    final isLowMemoryDevice = await _isLowMemoryDevice();
    final isLowEndDevice = await _isLowEndDevice();
    
    // First ensure performance monitoring is enabled
    await _initializePerformanceMonitor();
    
    // Initialize optimization manager with retry support
    await _initializeOptimizationManager();
    
    // Always enable optimization and adaptive mode
    try {
      await OptimizationManager.instance.setEnabled(true);
      await OptimizationManager.instance.setAdaptiveMode(true);
    } catch (e) {
      debugPrint('Error enabling optimization settings: $e');
      // Continue anyway
    }
    
    // Calculate and apply optimal preset for this device
    final optimalPreset = await _determineOptimalPreset(isLowMemoryDevice, isLowEndDevice);
    
    try {
      await OptimizationManager.instance.applyPreset(optimalPreset);
      debugPrint('Optimization system initialized with ${optimalPreset.name} preset');
    } catch (e) {
      debugPrint('Error applying optimization preset: $e');
      // Try to apply a simpler preset
      try {
        await OptimizationManager.instance.applyPreset(OptimizationPreset.balanced);
      } catch (_) {
        // If everything fails, the defaults from initialization will be used
      }
    }
  } catch (e) {
    debugPrint('Error initializing optimization system: $e');
    // Fall back to defaults if there's an error
    _applyDefaultOptimizations();
  } finally {
    isInitCompleted = true;
    watchdog?.cancel();
  }
}

// Initialize performance monitor with retry
Future<void> _initializePerformanceMonitor() async {
  int retries = 2;
  while (retries >= 0) {
    try {
      final performanceMonitor = PerformanceMonitor.instance;
      await performanceMonitor.initialize();
      await performanceMonitor.enableMonitoring(true);
      break; // Success!
    } catch (e) {
      retries--;
      if (retries < 0) {
        debugPrint('Failed to initialize performance monitor after all retries: $e');
      } else {
        debugPrint('Error initializing performance monitor, retrying: $e');
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }
}

// Initialize optimization manager with retry
Future<void> _initializeOptimizationManager() async {
  int retries = 2;
  while (retries >= 0) {
    try {
      await OptimizationManager.instance.initialize();
      break; // Success!
    } catch (e) {
      retries--;
      if (retries < 0) {
        debugPrint('Failed to initialize optimization manager after all retries: $e');
      } else {
        debugPrint('Error initializing optimization manager, retrying: $e');
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }
}

// Apply conservative default optimizations if something fails
void _applyDefaultOptimizations() {
  try {
    // Try to apply minimal optimizations that don't require initialization
    final performanceMonitor = PerformanceMonitor.instance;
    performanceMonitor.enableMonitoring(true);
    
    debugPrint('Applied fallback optimization defaults');
  } catch (e) {
    debugPrint('Error applying fallback optimizations: $e');
    // At this point there's not much else we can do
  }
}

// Determine the optimal preset based on multiple factors
Future<OptimizationPreset> _determineOptimalPreset(bool isLowMemoryDevice, bool isLowEndDevice) async {
  try {
    if (isLowMemoryDevice || isLowEndDevice) {
      return OptimizationPreset.lowMemory;
    }
    
    // Check for user preference first
    final prefs = await SharedPreferences.getInstance();
    final forcedPreset = prefs.getString('forced_optimization_preset');
    
    // Check if preset is manually forced
    if (forcedPreset != null) {
      switch (forcedPreset) {
        case 'low_memory': return OptimizationPreset.lowMemory;
        case 'balanced': return OptimizationPreset.balanced;
        case 'high_performance': return OptimizationPreset.highPerformance;
      }
    }
    
    // Fall back to calculated optimal preset
    return await OptimizationManager.instance.calculateOptimalPreset();
  } catch (e) {
    debugPrint('Error determining optimal preset: $e');
    // Conservative default
    return OptimizationPreset.balanced;
  }
}

// Check if device is memory constrained 
Future<bool> _isLowMemoryDevice() async {
  try {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Consider low memory if < 3GB RAM (properties changed due to updated device_info_plus)
      final totalRam = androidInfo.systemFeatures.contains('android.hardware.ram.low') 
          ? 2 * 1024 * 1024 * 1024  // Estimate for low RAM devices
          : 4 * 1024 * 1024 * 1024; // Conservative estimate for other devices
      return totalRam < 3 * 1024 * 1024 * 1024;
    } else if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      
      // Use model identifiers to estimate memory
      final model = iosInfo.model;
      // Older devices generally have less RAM
      return model.contains('iPhone 6') || 
             model.contains('iPhone 7') || 
             model.contains('iPhone 8') || 
             model.contains('iPhone SE') || 
             model.contains('iPad5,') ||
             model.contains('iPad6,');
    }
    return false;
  } catch (e) {
    debugPrint('Error detecting device memory: $e');
    // If we can't detect, assume it's not low memory
    return false;
  }
}

// Detect if this is a low-end device that needs more aggressive optimization
Future<bool> _isLowEndDevice() async {
  try {
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    // Check for Android
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      
      // Check SDK version - older versions likely mean older hardware
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt < 24) { // Android 7.0
        return true;
      }
      
      // Check processor cores - fewer cores often mean slower device
      if (androidInfo.supportedAbis.length < 2) {
        return true;
      }
    }
    
    // Check for iOS
    if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      final model = iosInfo.model;
      
      // Older iPhone models
      if (model.contains('iPhone') && 
          (model.contains('6') || model.contains('7') || model.contains('8') || 
           model.contains('SE') || model.contains('5'))) {
        return true;
      }
      
      // Check iOS version - older versions likely mean older hardware
      final systemVersion = iosInfo.systemVersion;
      final majorVersion = int.tryParse(systemVersion.split('.').first) ?? 0;
      if (majorVersion < 13) {
        return true;
      }
    }
    
    return false;
  } catch (e) {
    debugPrint('Error detecting device capabilities: $e');
    return false;
  }
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
    // This is non-critical, app can continue
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'Sifter',
      themeMode: themeMode,
      theme: ThemeData(
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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/bottom-nav': (context) => const BottomNav(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/create-room': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return CreateRoomScreen(
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
            radius: args?['radius'] ?? 0.2, // Default to 200m (2 city blocks)
          );
        },
        '/nearby-chats': (context) => const NearbyChatsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
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
  final Widget Function(BuildContext, Object, StackTrace) onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    required this.onError,
  }) : super(key: key);

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

    // Set up the global error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stack = details.stack;
      });
    };
    
    return widget.child;
  }
}
