import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sifter/providers/riverpod/auth_provider.dart';
import 'package:sifter/screens/auth/login_screen.dart';
import 'package:sifter/screens/bottomNav/bottom_nav.dart';
import 'package:sifter/screens/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    // Navigate to the appropriate screen after splash
    Future.delayed(const Duration(seconds: 3), () {
      _checkOnboardingStatus();
    });
  }
  
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    if (!onboardingCompleted) {
      // User hasn't completed onboarding, show onboarding screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      // Onboarding completed, check auth state
      _checkAuthState();
    }
  }
  
  void _checkAuthState() {
    // Use authStateChanges to determine where to navigate
    ref.read(authStateChangesProvider.future).then((user) {
      if (user != null) {
        // User is logged in, navigate to the main screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavScreen()),
        );
      } else {
        // User is not logged in, navigate to the login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }).catchError((_) {
      // Error occurred, navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // App logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sifter',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with the world around you',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
