# Firestore Rules Deployment Instructions

## Problem
The app shows "CloudFirestore permission denied" errors during authentication because Firestore security rules are blocking necessary operations.

## Solution: Deploy Updated Firestore Rules

### Method 1: Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **sifter-v20** project
3. Navigate to **Firestore Database** → **Rules**
4. Copy and paste the rules from `firestore.rules` file in this directory
5. Click **Publish**

### Method 2: Firebase CLI (if authentication issues are resolved)
```bash
firebase login --reauth
firebase use sifter-v20
firebase deploy --only firestore:rules
```

## What These Rules Fix
- Allow username checking during signup (prevents "username already taken" errors)
- Allow phone number lookup during sign-in 
- Properly secure user data while allowing necessary authentication operations
- Allow authenticated users to access their own data
- Prevent unauthorized access to other users' data

## Test After Deployment
1. Try creating a new account with a different username
2. Try signing in with your existing phone number and password
3. Both operations should work without permission errors

## If Issues Persist
The app now has improved error handling that will gracefully handle permission issues during the transition period. 