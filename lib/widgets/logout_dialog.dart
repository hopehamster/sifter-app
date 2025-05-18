import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod/auth_provider.dart';

/// Dialog to confirm user logout
class LogoutDialog extends ConsumerWidget {
  const LogoutDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    return AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await authNotifier.signOut();
            // Use mounted check before using BuildContext after an async gap
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}