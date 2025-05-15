import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sifter/main.dart';
import '../auth/login_screen.dart';

class LegalNoticesScreen extends StatefulWidget {
  @override
  _LegalNoticesScreenState createState() => _LegalNoticesScreenState();
}

class _LegalNoticesScreenState extends State<LegalNoticesScreen> {
  bool _hasSeenNotices = false;

  @override
  void initState() {
    super.initState();
    _checkNoticesStatus();
  }

  Future<void> _checkNoticesStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenLegalNotices') ?? false;
    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('notices_version').get();
    final currentVersion = snapshot.value as int? ?? 1;
    final savedVersion = prefs.getInt('noticesVersion') ?? 0;

    if (hasSeen && savedVersion >= currentVersion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthWrapper()),
      );
    } else {
      setState(() => _hasSeenNotices = false);
    }
  }

  Future<void> _markNoticesSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenLegalNotices', true);
    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('notices_version').get();
    final currentVersion = snapshot.value as int? ?? 1;
    await prefs.setInt('noticesVersion', currentVersion);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sifter Privacy Notice',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            Text(
              'Sifter values your privacy. We collect minimal data to provide a spontaneous, location-based chat experience:\n'
              '- **Anonymous Chat**: No personal credentials (e.g., name, email) are required for chat participation. Your user ID is a random identifier stored in Firebase.\n'
              '- **Chat Data Retention**: Chat messages and information are deleted once a chat is closed, either manually or if the creator leaves the radius for over 10 minutes. We do not retain chat data beyond this point.\n'
              '- **Location Data**: If you enable location sharing, we use your approximate location to connect you with nearby users. This data is not stored after you leave a chat room.\n'
              '- **Authentication Data**: If you sign in with email, phone, Google, or Apple, we store only your user ID and email (if provided) in Firebase for account management. Profile edits (e.g., display name) are optional and stored securely.\n'
              '- **Third-Party Services**: We use Firebase for authentication and data storage, and Google AdMob for ads. These services may collect device data (e.g., IP address, device ID) per their policies.\n'
              '- **Data Sharing**: We do not sell your data. Data may be shared with authorities if legally required.\n'
              '- **Your Rights**: You can delete your account anytime via the Profile screen, removing all associated data from Firebase.\n'
              '- **Contact Us**: For privacy concerns, email privacy@sifterapp.com.',
            ),
            SizedBox(height: 20),
            Text('Sifter Terms of Service',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            Text(
              'By using Sifter, you agree to these terms:\n'
              '- **Eligibility**: You must be 13+ to use Sifter.\n'
              '- **Usage**: Sifter enables anonymous, location-based chats. Do not use the app for illegal activities, harassment, or sharing harmful content. Violators will be banned.\n'
              '- **Chat Closure**: Chats close manually or if the creator leaves the radius for over 10 minutes. All messages and data are deleted upon closure. Sifter is not responsible for lost data.\n'
              '- **Location Sharing**: Enable location to connect with nearby users. Sifter does not store location data after you leave a chat.\n'
              '- **Third-Party Services**: We use Firebase and AdMob. Review their terms for data handling.\n'
              '- **Liability**: Sifter is not liable for user-generated content or interactions. Use at your own risk.\n'
              '- **Termination**: We may suspend accounts violating these terms.\n'
              '- **Changes**: Terms may update. Continued use implies acceptance.\n'
              '- **Contact**: Email support@sifterapp.com for issues.',
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _markNoticesSeen,
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
