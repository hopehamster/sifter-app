import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    // Load display name from shared preferences or user profile
    // For now, we'll use a placeholder
    setState(() {
      _displayName = 'Guest User';
    });
  }

  Future<void> _showDisplayNameDialog() async {
    final controller = TextEditingController(text: _displayName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your display name',
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _displayName = result;
      });
      // TODO: Save to shared preferences or user profile
      _showSnackBar('Display name updated');
    }
  }

  Future<void> _signOut() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (mounted) {
        _showSnackBar('Signed out successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to sign out: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final isGuest = authService.isAnonymousUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isGuest ? 'Guest Settings' : 'Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isGuest) ...[
                // Guest user account creation
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Create Account'),
                    subtitle: const Text(
                        'Unlock all features by creating an account'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(initialMode: LoginMode.signUp),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Display Name'),
                    subtitle: Text(_displayName.isEmpty
                        ? 'Set your display name for chats'
                        : _displayName),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showDisplayNameDialog,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // FAQs and Support section for all users
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('FAQs'),
                        subtitle: const Text('Frequently asked questions'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navigate to FAQs screen
                          _showSnackBar('FAQs screen coming soon!');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: const Text('Customer Support'),
                        subtitle: const Text('Get help with your account'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navigate to support screen
                          _showSnackBar('Support contact coming soon!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Guest user info section
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Guest Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re using Sifter as a guest. Create an account to:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('• Create your own chat rooms'),
                        const Text('• Access all chat rooms'),
                        const Text('• Keep your chat history'),
                        const Text('• Earn points and see leaderboards'),
                        const Text('• Customize your profile'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Registered user settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        const ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text('Username'),
                          subtitle: Text('Registered User'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign out button
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: _isLoading ? null : _signOut,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Sifter Chat',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
