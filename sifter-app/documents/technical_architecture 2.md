# Sifter Chat Application - Technical Architecture

## Overview
Sifter is a real-time chat application built with Flutter that uses geofencing to restrict chat room access based on users' physical locations. The app allows users to create and join chat rooms only when they are within a specified radius, similar to how Craigslist and Uber operate. When users leave the geofenced area, they are automatically removed from the chat room, and the chat room is deleted if the creator leaves.

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

### Real-time Communication
- **WebSocket**: For real-time chat functionality
- **Firebase Realtime Database**: 10.3.8 (for presence and typing indicators)

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
- **Firebase Auth**: 4.15.3
- **Google Sign In**: 6.1.6
- **Apple Sign In**: 5.0.0

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

### Initial Flow
1. **Splash Screen**
   - Brief 2-second display of app logo
   - Proceeds directly to Chat Join Screen

2. **Chat Join Screen**
   - Main screen showing available chat rooms within user's radius
   - Ad banner at top/bottom of screen
   - Video ad plays every 5 minutes if no chats are available
   - Empty state shows message encouraging account creation
   - Bottom navigation tabs:
     - Chat Creation
     - Chat Selection
     - Settings

3. **Account Creation**
   Three entry points:
   - Settings tab
   - Create Chat tab (prompts for account creation)
   - Empty Chat Join screen
   Authentication methods:
   - Email/Password
   - Phone number
   - Social login (Google, Apple)

### Main Screens

1. **Chat Creation Screen**
   - Two-step process:
     1. Location Selection:
        - Google Maps integration
        - Geofence radius selection (50-500 meters)
        - Current location display
     2. Chat Configuration:
        - Name and description
        - Password protection option
        - NSFW content flag
        - Anonymous access option

2. **Chat Screen**
   - Real-time messaging interface
   - Rich link previews for various types of links:
     - Social media posts
     - News articles
     - Product links
     - Media content
   - Enhanced reactions:
     - Emoji reactions
     - Animated reactions (Lottie)
     - Giphy GIF reactions
   - Moderation features for chat creators:
     - Remove individual posts from guests
     - Ban users from room
   - Auto-deletion when creator leaves radius
   - Preview window for new joiners with:
     - Join option
     - Report room option
   - Chat disappears when user leaves radius
   - History not saved when rejoining
   - Profanity filtering (disabled for NSFW rooms)

3. **Settings Screen**
   - Profile management
   - Account information editing:
     - Email
     - Password
     - Username
     - Score
   - Leaderboard access
   - Sign out option
   - Account deletion
   - Customer support
   - FAQs

### Special Features

1. **NSFW Content**
   - Invisible to underage users
   - Invisible to anonymous users
   - Requires age verification

2. **Geofencing**
   - Chat rooms only visible within radius
   - Auto-removal when leaving radius
   - Rejoin capability within radius

3. **Moderation**
   - Creator controls:
     - Post removal
     - User banning
   - Room reporting system
   - Content filtering

4. **Scoring System**
   - User points tracking based on participation:
     - Points for creating chat rooms
     - Points for joining chat rooms
     - Points for watching ads
   - Leaderboard integration
   - Score display in profile
   - Future plans for prize system

## Service Layer Architecture

### Core Services
1. **AuthService**
   - User authentication
   - Session management
   - Social login integration

2. **ChatService**
   - Real-time messaging
   - Message persistence
   - Chat room management
   - Geofence monitoring
   - Moderation tools
   - Link preview generation
   - Profanity filtering
   - Reaction handling

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

2. **ChatRoom**
   - Room information
   - Participants
   - Settings
   - Geofence data
   - Moderation status

3. **Message**
   - Message content
   - Metadata
   - Status
   - Moderation flags

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