# Sifter Chat Application - Technical Architecture

## Overview
Sifter is a real-time chat application built with Flutter that uses geofencing to restrict chat room access based on users' physical locations. The app allows users to create and join chat rooms only when they are within a specified radius, similar to how Craigslist and Uber operate. When users leave the geofenced area, they are automatically removed from the chat room, and the chat room is deleted if the creator leaves.

**Core Value Proposition**: Sifter serves as a universal "sifter" for local communication - enabling people to discover and communicate with others in their immediate vicinity without requiring upfront information exchange. Unlike existing communication tools that require contact information sharing or have limitations reaching all people in an area (like festivals, conferences, or events), Sifter provides a standard, universal way to connect with nearby people while maintaining privacy and control.

**Chat Implementation**: The application uses the **Flutter Chat SDK (Flyer Chat)** for all real-time messaging functionality, providing a professional chat interface with Firebase backend integration. **Media sharing is explicitly disabled** - the app supports text-only messaging for security and simplicity.

**Profile Philosophy**: No profile pictures or redundant social features. Users already have tools to exchange photos, contact information, and other media once they connect. Our focus is purely on facilitating initial discovery and communication.

## Core Technologies

### Frontend Framework
- **Flutter**: 3.19.0
- **Dart**: 3.3.0
- **Material Design**: 3.0

### State Management
- **Flutter Riverpod**: 2.4.9
- **Riverpod Generator**: 2.3.9
- **Riverpod Annotation**: 2.3.3

### Backend Services (Firebase)
- **Firebase Core**: 2.24.2
- **Firebase Auth**: 4.15.3
- **Cloud Firestore**: 4.13.6
- **Firebase Storage**: 11.5.6
- **Firebase Messaging**: 14.7.9
- **Firebase Analytics**: 10.7.4
- **Firebase Crashlytics**: 3.4.8

### Real-time Communication (Flutter Chat SDK - Flyer Chat)
- **Flutter Chat UI**: 1.6.15 - Professional chat interface components
- **Flutter Firebase Chat Core**: 1.6.7 - Firebase backend integration for messaging
- **Flutter Chat Types**: 3.6.2 - Data types and models for chat functionality
- **WebSocket**: Built into Flutter Chat SDK for real-time messaging
- **Firebase Realtime Database**: 10.3.8 (for presence and typing indicators)

**Note**: All chat functionality is implemented using the Flutter Chat SDK (also known as Flyer Chat), which provides:
- Professional chat UI components
- Real-time message streaming
- Firebase integration
- **Text messaging only** (image/file sharing disabled)
- User presence and typing indicators
- Link preview support
- Message status tracking

**Media Sharing Policy**: Image, file, and attachment sharing are explicitly disabled for security, content moderation, and simplicity reasons.

### Local Storage
- **Shared Preferences**: 2.2.2
- **Hive**: 2.2.3 (for local caching)
- **Path Provider**: 2.1.1

### UI Components
- **Flutter Material**: 3.0
- **Cupertino Icons**: 1.0.6
- **Flutter SVG**: 2.0.9
- **Cached Network Image**: 3.3.0
- **Flutter Markdown**: 0.6.18
- **Emoji Picker Flutter**: For emoji reactions
- **Lottie**: For animated reactions
- **Giphy Get**: For GIF reactions
- **Link Preview**: For rich link previews
- **URL Launcher**: For handling links

### Location Services
- **Geolocator**: 10.1.0
- **Google Maps Flutter**: 2.5.0
- **Geocoding**: 2.1.1

### Authentication
- **Firebase Auth**: 4.15.3 (Email/OTP only)
- **OTP Verification**: Email-based one-time password system
- **Email Verification**: New user email verification flow

### Push Notifications
- **Firebase Messaging**: 14.7.9
- **Flutter Local Notifications**: 16.2.0

### Error Handling & Analytics
- **Sentry**: 7.13.2
- **Firebase Analytics**: 10.7.4
- **Firebase Crashlytics**: 3.4.8

### Code Generation
- **Build Runner**: 2.4.7
- **Freezed**: 2.4.5
- **Json Serializable**: 6.7.1

## Project Structure

```
lib/
├── config/           # App configuration and API keys
├── constants/        # App constants
├── firebase/         # Firebase configuration
├── models/          # Data models
├── providers/       # State management
├── repositories/    # Data repositories
├── screens/         # UI screens
├── services/        # Business logic
├── use_cases/       # Use cases
├── utils/           # Utilities
└── widgets/         # Reusable widgets
```

## App Flow and Screens

### Authentication Flow
1. **Sign-Up Options**
   - **OTP Sign-Up** (Instant verification):
     - User selects OTP sign-up method
     - User enters email, username, password, and birth date
     - System sends 6-digit OTP to email
     - User enters OTP to verify and create account
     - Account is immediately verified and ready to use
   
   - **Email Sign-Up** (Traditional verification):
     - User selects email sign-up method  
     - User enters email, username, password, and birth date
     - Account is created and verification email is sent
     - User must click verification link in email before signing in

2. **Email Sign-In**
   - User enters email and password
   - System verifies email is verified (for email sign-up users)
   - Access granted to main app

3. **Account Verification Requirements**
   - **OTP users**: Instant verification during sign-up
   - **Email users**: Must verify email via link before first sign-in
   - Age verification through birth date for both methods
   - Username uniqueness validation for both methods

### Main App Navigation Structure
The app uses **bottom navigation as the primary navigation method** with three main sections:

1. **Chat Creation** (Tab 0) - Create new location-based chat rooms
2. **Chat Selection/Join** (Tab 1) - Discover and join nearby chat rooms (DEFAULT TAB)
3. **Settings** (Tab 2) - Profile management and app settings

### Initial Flow
1. **Splash Screen**
   - Brief 2-second display of app logo
   - Checks authentication state
   - Routes to Login/Sign-up or Main App

2. **Authentication Gate**
   - **Unauthenticated**: Routes to Login/Sign-up flow
   - **Authenticated**: Routes to Main App with bottom navigation

3. **Main App** (Bottom Navigation Container)
   - **DEFAULT VIEW**: Chat Selection/Join Screen (Tab 1 - middle position)
   - Persistent bottom navigation across all main screens
   - Floating action button for quick chat creation

### Main Screens

1. **Chat Creation Screen** (Tab 0)
   - **Access**: Bottom nav tab 0 OR floating action button
   - Two-step process:
     1. Location Selection:
        - Google Maps integration with visual geofence preview
        - Geofence radius selection (50-500 meters)
        - Current location selection
     2. Chat Configuration:
        - Name and description
        - Password protection option
        - NSFW content flag
        - **Anonymous access option**: Toggle to allow/disallow anonymous users in chat room
        - Maximum members setting (2-100)
   - **Form validation** and proper UX flow
   - **Return flow**: Creation success → Back to Chat Selection/Join screen

2. **Chat Selection/Join Screen** (Tab 1 - DEFAULT)
   - **Core Function**: Display rooms user is **currently within geofence** of
   - **Anonymous User Filtering**: Anonymous users only see rooms that have "Allow Anonymous Users" enabled
   - **Real-time updates**: Rooms appear/disappear as user moves in/out of range
   - **Room Cards**: Show name, description preview, member count, distance, badges
   - **Tap Interaction**: Room card → Chat Preview Window
   - **Empty State**: When no eligible rooms exist:
     - Show message encouraging users to create a chat and start a conversation in their area
     - **Video Ad Display**: Show video ad every 5 minutes if screen remains empty and user stays on screen idling
   - **Refresh**: Pull to refresh or refresh button in app bar
   - **Navigation**: Active tab in bottom navigation (middle position)

3. **Settings Screen** (Tab 2)
   - **Registered Users**: Full profile management, account information editing (Email, Password, Username, Score), leaderboard access, notification settings, app preferences, and account management
   - **Anonymous Users**: Minimal interface with display name setting, account creation option, and legal/support information
   - Sign out option (registered users only)
   - Customer support and FAQs (all users)

4. **Chat Preview Window** (Modal)
   - **Detailed Information**:
     - Room name and creator
     - Full description (scrollable)
     - Current member count and capacity
     - Distance from user and geofence radius
     - Password protection and NSFW indicators
     - **Anonymous Access Indicator**: Shows if anonymous users are allowed
   - **Action Buttons**:
     - Report Room (with detailed reporting categories)
     - Join Chat (handles password input if needed)
   - **Dismissal**: Drag down, back button, or complete action

### Anonymous User Experience

**Philosophy**: Allow quick chatting with minimal upfront hassle while encouraging account creation.

**Anonymous User Capabilities**:
- **Chat Access**: Can only join chat rooms that have "Allow Anonymous Users" toggle enabled
- **Core Chat Features**: Full text messaging within allowed rooms
- **Minimal Settings**: Only display name setting and account creation option
- **Feature Limitations**: All other features are designed to entice account creation
- **Quick Chat Flow**: Enables immediate participation without registration barriers

**Anonymous User Settings Screen**:
- **Display Name Setting**: Allow anonymous users to set a display name for chat identification
- **Account Creation Option**: Prominent account creation feature to encourage conversion
- **Legal & Support Access**: FAQs, Privacy Policy, Terms of Service for transparency and support
- **No Sign-Out or Account Management**: Anonymous users are not "signed in" in a traditional sense
- **Conversion Focused**: Designed to encourage account creation while maintaining core functionality

**Chat Room Anonymous Settings**:
- Room creators can toggle "Allow Anonymous Users" option during chat creation
- This setting determines whether anonymous users can discover and join the room
- Provides flexibility for room creators to control their audience

### Account Creation Entry Points

The application provides **3 specific entry points** for account creation:

1. **Settings Screen Account Creation** (Primary for Anonymous Users)
   - **Anonymous users see minimal settings with prominent account creation option**
   - Only display name setting and account creation available to anonymous users
   - Provides seamless upgrade path from anonymous to registered user
   - Maintains user's chat history and display name upon account creation

2. **Create Chat Tab Authentication Check** (For Anonymous Users)
   - When anonymous users attempt to create chat rooms
   - Display message: "You need to have an account in order to make chats"
   - Present two options:
     - Back out (return to previous screen)
     - Go to account creation window

3. **Chat Selection Empty State** (General Encouragement)
   - When chat selection window is empty (no nearby rooms)
   - Show message encouraging users to create a chat and start a conversation in their area
   - **Video Ad Behavior**: Display video ad every 5 minutes if screen remains empty and user stays on screen idling
   - **Anonymous Context**: Encourages both account creation and room discovery

### Key UI/UX Principles

1. **Bottom Navigation is Primary**:
   - Always visible in main app
   - Primary navigation method between major sections
   - Chat Selection/Join is the default/home screen (middle position)
   - Consistent across all main app screens

2. **Geofencing is Core**: 
   - NEVER show rooms user cannot join
   - Real-time location-based filtering
   - Clear messaging when no eligible rooms exist

3. **Preview Before Join**:
   - No immediate joining on tap
   - Always show detailed preview first
   - Clear action buttons for join vs report

4. **Navigation Consistency**:
   - Bottom nav always shows: Chat Creation | Chat Selection/Join | Settings
   - Chat Selection/Join is the primary/home screen (center position)
   - Floating action button provides quick access to Chat Creation from any tab

5. **Room Discovery Flow**:
   - Chat Selection/Join (see eligible) → Preview (detailed view) → Join/Report (action)
   - Clear visual hierarchy and user control at each step

### App Structure
```
Splash Screen
     ↓
Authentication Gate
     ↓
Main App (Bottom Navigation Container)
├── Chat Creation (Tab 0)
├── Chat Selection/Join (Tab 1 - DEFAULT)
└── Settings (Tab 2)
     ↓
Chat Preview Window (Modal from Chat Selection)
     ↓
Join Chat / Report Room
```

### Authentication Requirements

1. **Email-Only Authentication**
   - No social login (Google, Apple, etc.)
   - Email and password based system
   - OTP verification for security

2. **OTP System**
   - Email-based one-time passwords
   - Required for new account verification
   - Optional for enhanced login security
   - 6-digit numeric codes
   - 5-minute expiration

3. **User Verification Flow**
   - Email verification via OTP
   - Age verification (birth date entry)
   - Username uniqueness check
   - Password strength requirements

4. **NSFW Content Protection**
   - Age verification required (18+)
   - Birth date validation
   - NSFW content invisible to verified minors
   - Anonymous users cannot access NSFW content

## Service Layer Architecture

### Core Services
1. **AuthService**
   - User authentication
   - Session management
   - Email/OTP verification

2. **ChatService (Flutter Chat SDK Integration)**
   - Real-time messaging via Flutter Chat UI
   - Message persistence through Firebase Chat Core
   - Chat room management integrated with Flyer Chat SDK
   - Geofence monitoring for chat access
   - Moderation tools
   - Link preview generation (built into SDK)
   - User presence tracking
   - Message status and delivery confirmation

3. **LocationService**
   - Location tracking
   - Geofencing
   - Radius management
   - Distance calculations
   - Location permission handling
   - Background location updates

4. **AnalyticsService**
   - User tracking
   - Event logging
   - Error reporting

### Supporting Services
1. **SettingsService**
   - User preferences
   - App configuration
   - Theme management

2. **SyncService**
   - Data synchronization
   - Offline support
   - Conflict resolution

3. **ContentFilterService**
   - Profanity filtering
   - NSFW content detection
   - Link validation
   - Content moderation

## Data Models

### Core Models
1. **AppUser**
   - User profile
   - Authentication data
   - Preferences
   - Score
   - **No profile picture** - focus on communication facilitation, not social media features

2. **ChatRoom**
   - Room information
   - Participants
   - Settings
   - Geofence data
   - Moderation status
   - **Flutter Chat SDK Integration**:
     - `toFlyerRoom()` - converts to Flutter Chat SDK Room format
     - `fromFlyerRoom()` - creates ChatRoom from Flutter Chat SDK Room

3. **Message (Flutter Chat SDK)**
   - Managed entirely by Flutter Chat SDK types
   - Text, image, file, and custom message types
   - Message metadata and status
   - User information and timestamps
   - Delivery and read receipts

4. **BlockedUser**
   - Blocked user data
   - Block reasons
   - Timestamps

## Error Handling Strategy

### Error Categories
1. **Critical Errors**
   - Authentication failures
   - Database connection issues
   - Service unavailability

2. **High Severity**
   - Message delivery failures
   - Location service issues
   - Geofence violations

3. **Medium Severity**
   - UI rendering issues
   - Cache misses
   - Network timeouts

4. **Low Severity**
   - Non-critical feature failures
   - UI glitches
   - Performance issues

### Error Recovery
1. **Automatic Recovery**
   - Retry mechanisms
   - Fallback options
   - Cache utilization

2. **User Intervention**
   - Clear error messages
   - Recovery instructions
   - Support contact

## Security Measures

1. **Authentication**
   - JWT tokens
   - Session management

2. **Data Protection**
   - End-to-end encryption
   - Secure storage
   - Data sanitization

3. **Network Security**
   - SSL/TLS
   - API key management
   - Rate limiting

## Performance Considerations

1. **Caching Strategy**
   - Memory cache
   - Disk cache
   - Network cache

2. **Network Optimization**
   - Request batching
   - Response caching
   - Connection pooling

## Testing Strategy

1. **Unit Tests**
   - Service layer
   - Business logic
   - Utility functions

2. **Integration Tests**
   - API integration
   - Service interaction
   - Data flow

3. **UI Tests**
   - Widget testing
   - Screen testing
   - User flows

## Deployment

### Android
- Minimum SDK: 21
- Target SDK: 34
- Build Tools: 34.0.0

### iOS
- Minimum iOS: 13.0
- Target iOS: 17.0
- Xcode: 15.0

## Monitoring and Maintenance

1. **Performance Monitoring**
   - Firebase Performance
   - Custom metrics
   - User analytics

2. **Error Tracking**
   - Sentry integration
   - Crash reporting
   - Error logging

3. **Usage Analytics**
   - User behavior
   - Feature usage
   - Performance metrics

## Backup and Recovery

1. **Data Backup**
   - Cloud backup
   - Local backup
   - Export functionality

2. **Recovery Procedures**
   - Data restoration
   - Account recovery
   - Service recovery

## Future Considerations

1. **Scalability**
   - Load balancing
   - Database sharding
   - CDN integration

2. **Feature Expansion**
   - Voice messages
   - Video calls
   - Group features
   - Prize system implementation
   - Enhanced link previews
   - Additional reaction types

3. **Platform Support**
   - Web version
   - Desktop version
   - Cross-platform consistency 
   - **No profile picture management** - simplified user experience focused on core communication value 