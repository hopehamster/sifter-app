import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/utils/whatsapp_util.dart';
import 'package:sifter/providers/riverpod/user_provider.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 24),
            const Text(
              'Quick Guide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGuideStep('1', 'Allow location permissions for the app', 'This is required to find nearby rooms.'),
            _buildGuideStep('2', 'Create a profile or sign in', 'You can customize your display name and profile picture.'),
            _buildGuideStep('3', 'Browse nearby rooms', 'See what conversations are happening around you.'),
            _buildGuideStep('4', 'Join a room or create your own', 'Start chatting instantly with people nearby.'),
            _buildGuideStep('5', 'Share messages, images, and more', 'Participate in local conversations.'),
            const SizedBox(height: 24),
            const Text(
              'Need More Help?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildContactButtons(context, ref),
          ],
        ),
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

  Widget _buildGuideStep(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.phone, color: Color(0xFF25D366)),
          title: const Text('Contact us on WhatsApp'),
          subtitle: const Text('Get help from our support team'),
          onTap: () async {
            final currentUser = ref.read(userNotifierProvider).value;
            
            if (currentUser != null) {
              final supportMessage = WhatsAppUtil.createSupportMessage(
                userId: currentUser.id,
                username: currentUser.displayName,
              );
              
              await WhatsAppUtil.launchWhatsAppChat(
                message: supportMessage,
              );
            } else {
              // If user is not logged in, just open WhatsApp without user details
              await WhatsAppUtil.launchWhatsAppChat();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.email, color: Colors.red),
          title: const Text('Email Support'),
          subtitle: const Text('support@sifterapp.com'),
          onTap: () => _launchEmail(),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline, color: Colors.blue),
          title: const Text('Visit Help Center'),
          subtitle: const Text('Find more detailed guides and tutorials'),
          onTap: () => _launchHelpCenter(),
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
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchHelpCenter() async {
    final helpCenterUrl = Uri.parse('https://sifterapp.com/help');
    
    if (await canLaunchUrl(helpCenterUrl)) {
      await launchUrl(helpCenterUrl);
    }
  }
} 
