import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/riverpod/auth_provider.dart';
import '../services/location_service.dart';
import '../utils/whatsapp_util.dart';
import '../widgets/logout_dialog.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'user_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  final String currentUserId;

  const SettingsScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (currentUserId.isNotEmpty) ...[
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(currentUserId),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(currentUserId),
                ),
                const Divider(),
              ],
              const Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable dark theme'),
                value: ref.read(authProvider).isDarkMode,
                onChanged: (value) {
                  ref.read(authProvider.notifier).update((state) => state.copyWith(isDarkMode: value));
                },
              ),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Enable push notifications'),
                value: ref.read(authProvider).notificationsEnabled,
                onChanged: (value) {
                  ref.read(authProvider.notifier).update((state) => state.copyWith(notificationsEnabled: value));
                },
              ),
              SwitchListTile(
                title: const Text('Location Services'),
                subtitle: const Text('Enable location tracking'),
                value: ref.read(authProvider).locationEnabled,
                onChanged: (value) {
                  ref.read(authProvider.notifier).update((state) => state.copyWith(locationEnabled: value));
                },
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(ref.read(authProvider).language),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement language selection
                },
              ),
              const Divider(),
              
              // Help and FAQ Section
              const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                'What is Sifter?',
                'Sifter is a location-based chat application that allows you to connect with people nearby and join local conversations.',
              ),
              _buildFaqItem(
                'How do rooms work?',
                'Rooms are chat spaces defined by geographic area. You can join rooms within your area or create your own room for others to join.',
              ),
              _buildFaqItem(
                'Is my data private?',
                'We take privacy seriously. Your precise location is never shared with other users, only your proximity to chat rooms. Messages in private rooms are only visible to members.',
              ),
              _buildFaqItem(
                'Can I block users?',
                'Yes, you can block users by tapping their profile and selecting the block option. Blocked users cannot see your messages or contact you.',
              ),
              _buildFaqItem(
                'How do I report inappropriate content?',
                'Long-press on any message and select "Report" to flag inappropriate content for our moderation team to review.',
              ),
              const SizedBox(height: 16),
              
              // Contact Support options
              ListTile(
                leading: const Icon(Icons.whatsapp, color: Color(0xFF25D366)),
                title: const Text('Contact us on WhatsApp'),
                subtitle: const Text('Get help from our support team'),
                onTap: () async {
                  final supportMessage = WhatsAppUtil.createSupportMessage(
                    userId: currentUserId,
                    username: 'User', // Ideally this would be fetched from user profile
                  );
                  await WhatsAppUtil.launchWhatsAppChat(message: supportMessage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.red),
                title: const Text('Email Support'),
                subtitle: const Text('support@sifterapp.com'),
                onTap: () => _launchEmail(),
              ),
              
              const Divider(),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                onTap: () {
                  // TODO: Navigate to terms of service
                },
              ),
              const Divider(),
              if (currentUserId.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: const Text('Leaderboard'),
                  subtitle: const Text('View top users and your ranking'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaderboardScreen(
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage notification settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy'),
                  subtitle: const Text('Manage privacy settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('User Management'),
                  subtitle: const Text('Manage blocked and muted users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const LogoutDialog(),
                    );
                  },
                ),
              ],
            ],
          ),
          if (ref.watch(authProvider).isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }
  
  Future<void> _launchEmail() async {
    const email = 'support@sifterapp.com';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Sifter App Support Request',
    );
    
    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    }
  }
}