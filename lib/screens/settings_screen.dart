import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/riverpod/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../services/location_service.dart';
import '../utils/whatsapp_util.dart';
import '../widgets/logout_dialog.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'user_management_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Define language provider
final languageProvider = StateProvider<String>((ref) {
  return 'English';
});

class SettingsScreen extends ConsumerWidget {
  final String currentUserId;

  const SettingsScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get auth user data
    final authState = ref.watch(authNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final language = ref.watch(languageProvider);
    
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
                  subtitle: Text(authState.value?.email ?? 'Not signed in'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(authState.value?.phoneNumber ?? 'No phone number'),
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
                value: themeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeNotifierProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Enable push notifications'),
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  ref.read(settingsNotifierProvider.notifier).setNotificationsEnabled(value);
                },
              ),
              SwitchListTile(
                title: const Text('Location Services'),
                subtitle: const Text('Enable location tracking'),
                value: LocationService.instance.isEnabled,
                onChanged: (value) {
                  if (value) {
                    LocationService.instance.requestLocationPermission();
                  } else {
                    LocationService.instance.disableLocation();
                  }
                },
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(language),
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
                leading: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
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
              // Optimization Settings Section
              ListTile(
                title: Text(
                  'Performance Optimization',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: const Icon(Icons.speed),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OptimizationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (authState.isLoading)
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
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

class OptimizationSettingsScreen extends ConsumerStatefulWidget {
  const OptimizationSettingsScreen({Key? key}) : super(key: key);

  @override
  _OptimizationSettingsScreenState createState() => _OptimizationSettingsScreenState();
}

class _OptimizationSettingsScreenState extends ConsumerState<OptimizationSettingsScreen> {
  bool _isEnabled = true;
  bool _adaptiveMode = true;
  String _currentPreset = 'Balanced';
  Map<String, dynamic> _stats = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // Get the optimization manager
    final optimizationManager = ref.read(optimizationManagerProvider);
    
    final status = optimizationManager.getOptimizationStatus();
    
    setState(() {
      _isEnabled = status['enabled'] as bool;
      _adaptiveMode = status['adaptive_mode'] as bool;
      _currentPreset = status['active_preset'] as String;
      _stats = status;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final optimizationManager = ref.read(optimizationManagerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Optimization'),
      ),
      body: ListView(
        children: [
          // Main toggle
          SwitchListTile(
            title: const Text('Enable Optimization'),
            subtitle: const Text('Optimize app performance and resource usage'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
              optimizationManager.setEnabled(value);
            },
          ),
          
          // Adaptive mode toggle
          SwitchListTile(
            title: const Text('Adaptive Optimization'),
            subtitle: const Text('Automatically adjust based on device conditions'),
            value: _adaptiveMode,
            enabled: _isEnabled,
            onChanged: (value) {
              setState(() {
                _adaptiveMode = value;
              });
              optimizationManager.setAdaptiveMode(value);
            },
          ),
          
          const Divider(),
          
          // Preset selection
          ListTile(
            title: const Text('Optimization Preset'),
            subtitle: Text(_currentPreset),
            enabled: _isEnabled && !_adaptiveMode,
            trailing: const Icon(Icons.settings),
            onTap: _isEnabled && !_adaptiveMode ? () {
              _showPresetPicker();
            } : null,
          ),
          
          const Divider(),
          
          // Performance metrics
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildStatusCard(),
              ],
            ),
          ),
          
          // Optimization tips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimization Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: optimizationManager.generateOptimizationRecommendations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No optimization recommendations available.');
                    } else {
                      return Column(
                        children: snapshot.data!.map((tip) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.tips_and_updates, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(tip)),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard() {
    if (_stats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final deviceCategory = _stats['device_category'] as String? ?? 'Unknown';
    final metrics = _stats['performance_metrics'] as Map<String, dynamic>? ?? {};
    final memoryStats = _stats['memory_stats'] as Map<String, dynamic>? ?? {};
    
    // Format metrics as percentages
    final frameRateScore = ((metrics['frameRate'] as double? ?? 0) * 100).round();
    final memoryScore = ((metrics['memory'] as double? ?? 0) * 100).round();
    final networkScore = ((metrics['network'] as double? ?? 0) * 100).round();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Category: $deviceCategory'),
            const SizedBox(height: 8),
            Text('Memory Usage: ${memoryStats['estimated_memory_usage_mb'] ?? 0} MB'),
            const SizedBox(height: 16),
            
            // Score bars
            _buildScoreBar('Frame Rate', frameRateScore),
            const SizedBox(height: 8),
            _buildScoreBar('Memory', memoryScore),
            const SizedBox(height: 8),
            _buildScoreBar('Network', networkScore),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreBar(String label, int score) {
    Color barColor;
    if (score >= 80) {
      barColor = Colors.green;
    } else if (score >= 60) {
      barColor = Colors.amber;
    } else {
      barColor = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $score%'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
          minHeight: 8,
        ),
      ],
    );
  }
  
  void _showPresetPicker() {
    final optimizationManager = ref.read(optimizationManagerProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Optimization Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPresetOption('Low Memory', 'Optimize for low-end devices with limited resources'),
              _buildPresetOption('Balanced', 'Balance performance and resource usage'),
              _buildPresetOption('High Performance', 'Maximize performance on high-end devices'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPresetOption(String presetName, String description) {
    final optimizationManager = ref.read(optimizationManagerProvider);
    
    return ListTile(
      title: Text(presetName),
      subtitle: Text(description),
      trailing: _currentPreset == presetName ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        Navigator.pop(context);
        
        OptimizationPreset preset;
        switch (presetName) {
          case 'Low Memory':
            preset = OptimizationPreset.lowMemory;
            break;
          case 'High Performance':
            preset = OptimizationPreset.highPerformance;
            break;
          case 'Balanced':
          default:
            preset = OptimizationPreset.balanced;
            break;
        }
        
        await optimizationManager.applyPreset(preset);
        
        setState(() {
          _currentPreset = presetName;
        });
        
        // Give feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$presetName preset applied')),
          );
        }
      },
    );
  }
}