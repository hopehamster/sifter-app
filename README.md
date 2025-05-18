# Sifter - Location-Based Chat App

## Overview
Sifter is a location-based chat application that allows users to connect with people nearby and join local conversations. The app focuses on local community building through geo-fenced chat rooms.

## Key Features
- **Location-Based Chats**: Find and join chat rooms within your area
- **Group Creation**: Create your own chat groups with customizable settings
- **Points System**: Earn points for app activities (creating groups, joining conversations, watching ads)
- **Leaderboard**: Track top users and your ranking
- **Privacy Controls**: Comprehensive privacy settings for location data
- **Message Reactions**: React to messages with emojis
- **Ads Integration**: AdMob integration with rewarded videos for extra points

## Technical Details
- Built with Flutter for cross-platform compatibility
- Firebase backend for authentication, database, and cloud functions
- Real-time location services with Geolocator
- Input validation and security measures
- AdMob integration for monetization
- Comprehensive error handling and user feedback

## Getting Started
1. Clone the repository
2. Install Flutter and dependencies
```bash
flutter pub get
```
3. Run the code generator
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
4. Run the app
```bash
flutter run
```

## Platform-Specific Commands
- Run on iOS: `./run_ios.sh`
- Run on Android: `./run_android.sh`
- Run in dev mode: `./run_dev.sh`

## Requirements
- Flutter SDK: 3.0.0 or higher
- Dart SDK: 2.17.0 or higher
- iOS: 11.0 or higher
- Android: API level 21 (Android 5.0) or higher

## Architecture
The app follows a clean architecture approach with:
- Riverpod for state management
- Service classes for external APIs
- Model classes for data representation
- UI screens and widgets for presentation
- Utility classes for common functionality

## Points System
- Watching rewarded ads: 10 points
- Creating groups: 50 points
- Joining groups: 5 points

# Sifter v20 - TestFlight Deployment Instructions

## Prerequisites
- MacBook with Xcode 16.x installed.
- Apple Developer account with a bundle ID set up in App Store Connect (e.g., `com.yourdomain.sifter`).
- `GoogleService-Info.plist` file from your Firebase project.
- Firebase CLI installed (for deploying Cloud Functions and Security Rules).

## Setup Steps
1. **Unzip the Archive**:
   - Unzip `sifter-v20-testflight.zip` to a folder on your MacBook.

2. **Replace Firebase Configuration**:
   - Download your `GoogleService-Info.plist` from the Firebase Console.
   - Place it in `ios/Runner/`, replacing the placeholder file.

3. **Update Environment Variables**:
   - Open the `.env` file in the project root.
   - Replace the placeholder `GIPHY_API_KEY` with your actual GIPHY API key.

4. **Deploy Firebase Cloud Functions and Security Rules**:
   - Install the Firebase CLI if not already installed: `npm install -g firebase-tools`.
   - Log in to Firebase: `firebase login`.
   - From the project root, run: