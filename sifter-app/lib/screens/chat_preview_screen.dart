import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_room.dart';
import '../services/location_service.dart';
import '../services/chat_room_service.dart';
import '../services/auth_service.dart';
import '../screens/chat_screen.dart';
import '../services/moderation_service.dart';

class ChatPreviewScreen extends ConsumerWidget {
  final ChatRoom room;

  const ChatPreviewScreen({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Room header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created by ${room.creatorName}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildRoomBadges(context),
                ],
              ),

              const SizedBox(height: 16),

              // Room stats
              _buildRoomStats(context, ref),

              const SizedBox(height: 16),

              // Description
              _buildDescription(context, scrollController),

              const SizedBox(height: 20),

              // Action buttons
              _buildActionButtons(context),

              // Safe area padding for bottom
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomBadges(BuildContext context) {
    final badges = <Widget>[];

    if (room.isPasswordProtected) {
      badges.add(
        Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
      );
    }

    if (room.allowAnonymous) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'GUEST OK',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (room.isNsfw) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'NSFW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .expand((badge) => [badge, const SizedBox(width: 8)])
          .take(badges.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildRoomStats(BuildContext context, WidgetRef ref) {
    final locationService = ref.read(locationServiceProvider);
    final distance = locationService.getDistanceTo(
      targetLat: room.latitude,
      targetLng: room.longitude,
    );

    String distanceText = 'Unknown';
    if (distance != null) {
      if (distance < 1000) {
        distanceText = '${distance.round()}m away';
      } else {
        distanceText = '${(distance / 1000).toStringAsFixed(1)}km away';
      }
    }

    return Row(
      children: [
        Icon(Icons.people,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '${room.participantIds.length}/${room.maxMembers} members',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 16),
        Icon(Icons.location_on,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(distanceText, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(
          'Radius: ${room.radiusInMeters.round()}m',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildDescription(
      BuildContext context, ScrollController scrollController) {
    if (room.description.isNotEmpty) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Text(
                  room.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Center(
          child: Text(
            'No description provided',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Report button
        Expanded(
          child: Consumer(
            builder: (context, ref, child) => OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showReportDialog(context, ref);
              },
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Join button
        Expanded(
          flex: 2,
          child: Consumer(
            builder: (context, ref, child) {
              final authService = ref.read(authServiceProvider);
              final isAnonymous = authService.isAnonymousUser;

              return FilledButton.icon(
                onPressed: () async {
                  // ✅ NSFW Age Verification Check
                  if (room.isNsfw) {
                    if (isAnonymous) {
                      _showAgeVerificationDialog(context, isAnonymous: true);
                      return;
                    }

                    final isOfLegalAge = await authService.isUserOfLegalAge();
                    if (!isOfLegalAge) {
                      _showAgeVerificationDialog(context, isAnonymous: false);
                      return;
                    }
                  }

                  // ✅ Anonymous User Access Check
                  if (isAnonymous && !room.allowAnonymous) {
                    _showCreateAccountDialog(context);
                    return;
                  }

                  // Proceed with normal join flow
                  if (room.isPasswordProtected) {
                    _showPasswordDialog(context);
                  } else {
                    _attemptJoinRoom(context);
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Join Chat'),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reportCategories = [
      ReportCategory.inappropriate,
      ReportCategory.spam,
      ReportCategory.harassment,
      ReportCategory.violence,
      ReportCategory.illegal,
      ReportCategory.other,
    ];

    ReportCategory? selectedCategory;
    final otherReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Report ${room.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this chat room?'),
              const SizedBox(height: 16),
              ...reportCategories
                  .map((category) => RadioListTile<ReportCategory>(
                        title: Text(category.displayName),
                        value: category,
                        groupValue: selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      )),
              if (selectedCategory == ReportCategory.other) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCategory != null
                  ? () async {
                      Navigator.of(context).pop();
                      await _reportRoom(selectedCategory!,
                          otherReasonController.text, context, ref);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportRoom(ReportCategory category, String description,
      BuildContext context, WidgetRef ref) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final result = await moderationService.reportRoom(
        roomId: room.id,
        reason: category.displayName,
        category: category,
        description: description.isNotEmpty ? description : null,
      );

      if (context.mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Report submitted successfully. Thank you.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit report: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Join ${room.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This chat room is password protected.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
                onSubmitted: (_) {
                  if (!isLoading && passwordController.text.isNotEmpty) {
                    Navigator.of(context).pop();
                    _attemptJoinRoomWithPassword(
                        context, passwordController.text);
                  }
                },
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading || passwordController.text.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _attemptJoinRoomWithPassword(
                          context, passwordController.text);
                    },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  void _attemptJoinRoom(BuildContext context) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining ${room.name}...')),
    );

    try {
      // Get current user ID
      final authService =
          ProviderScope.containerOf(context).read(authServiceProvider);
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Attempt to join the room
      final chatRoomService =
          ProviderScope.containerOf(context).read(chatRoomServiceProvider);
      final success = await chatRoomService.joinChatRoom(
        roomId: room.id,
        userId: currentUserId,
      );

      if (!context.mounted) return;

      if (success) {
        // Navigate to chat screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: room),
          ),
        );
      } else {
        // Show error with specific message
        String errorMessage = 'Failed to join room. Please try again.';

        // Check if it might be a password issue
        if (room.isPasswordProtected) {
          errorMessage = 'Incorrect password. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: room.isPasswordProtected
                ? SnackBarAction(
                    label: 'Try Again',
                    textColor: Colors.white,
                    onPressed: () => _showPasswordDialog(context),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _attemptJoinRoomWithPassword(
      BuildContext context, String password) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining ${room.name}...')),
    );

    try {
      // Get current user ID
      final authService =
          ProviderScope.containerOf(context).read(authServiceProvider);
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Attempt to join the room with password
      final chatRoomService =
          ProviderScope.containerOf(context).read(chatRoomServiceProvider);
      final success = await chatRoomService.joinChatRoom(
        roomId: room.id,
        userId: currentUserId,
        password: password,
      );

      if (!context.mounted) return;

      if (success) {
        // Navigate to chat screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: room),
          ),
        );
      } else {
        // Show error with specific message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Incorrect password. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: () => _showPasswordDialog(context),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Required'),
        content: const Text(
          'This room is for registered users only. Create an account to join and unlock all features of Sifter Chat!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to settings for account creation
              // This would typically be handled by the main app navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to Settings to create your account!'),
                ),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  void _showAgeVerificationDialog(BuildContext context,
      {required bool isAnonymous}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Age Verification Required'),
        content: Text(
          isAnonymous
              ? 'This room is marked as NSFW. You must be at least 18 years old to join.'
              : 'This room is marked as NSFW. You must be at least 18 years old and verified to join.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to age verification
              // This would typically be handled by the main app navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to Verification to verify your age!'),
                ),
              );
            },
            child: const Text('Verify Age'),
          ),
        ],
      ),
    );
  }
}
