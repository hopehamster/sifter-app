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