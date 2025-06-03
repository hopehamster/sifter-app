import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'main_app_screen.dart';

/// AuthGate manages authentication state and routes users accordingly
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔍 AuthGate: Building widget');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔍 AuthGate: StreamBuilder called');
        print('🔍 AuthGate: Connection state: ${snapshot.connectionState}');
        print('🔍 AuthGate: Has data: ${snapshot.hasData}');
        print('🔍 AuthGate: User: ${snapshot.data?.uid ?? 'null'}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔍 AuthGate: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          print('🎉 AuthGate: User authenticated - UID: ${user.uid}');
          print('🔍 AuthGate: User email: ${user.email ?? 'none'}');
          print('🔍 AuthGate: User phone: ${user.phoneNumber ?? 'none'}');
          print('🔍 AuthGate: Is anonymous: ${user.isAnonymous}');
          print('🔍 AuthGate: Email verified: ${user.emailVerified}');
          print('🔍 AuthGate: Navigating to MainAppScreen');
          return const MainAppScreen();
        } else {
          print('🔍 AuthGate: No user authenticated, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Sifter Chat',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location-based conversations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
