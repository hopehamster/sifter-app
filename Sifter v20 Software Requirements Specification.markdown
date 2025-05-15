# Software Requirements Specification (SRS) for Sifter v20

## 1. Introduction

### 1.1 Purpose
This SRS document outlines the requirements for Sifter v20, a location-based chat application that enables users to create and join temporary, geofenced chat rooms. It ensures spontaneous, private connections while maintaining user privacy through data deletion after chat closure.

### 1.2 Scope
Sifter v20 allows users to:
- Create geofenced chat rooms (authenticated users only).
- Join nearby chats (anonymous or authenticated users).
- Send text, audio, and GIF messages.
- Ensure privacy with temporary rooms that delete data upon closure.

## 2. Overall Description

### 2.1 User Needs
- **Anonymous Users**: Join chats without an account, with an option to create an account via settings.
- **Authenticated Users**: Create and manage chats, sign in via email, phone, Google, or Apple.
- **Privacy**: Ensure chats and data are deleted after closure.

### 2.2 Assumptions and Dependencies
- Requires iOS 14.0+ for compatibility.
- Depends on Firebase for authentication and data storage, Google AdMob for ads, and Google Maps for geolocation.

## 3. System Features

### 3.1 Authentication
- **Description**: Users can sign in anonymously or via email, phone, Google, or Apple.
- **Requirements**:
  - Anonymous users can join chats if `allowAnonymous` is true.
  - Authenticated users can create chats.
  - Skip option on login screen for anonymous access.

### 3.2 Chat Creation
- **Description**: Authenticated users can create geofenced chat rooms.
- **Requirements**:
  - Set radius (50–500 meters) using Google Maps.
  - Options for room name, description, anonymous access, NSFW flag, and password.
  - Show rewarded ad every 5 chats via AdMob.

### 3.3 Chat Joining
- **Description**: Users can join nearby chats based on location.
- **Requirements**:
  - Display list of nearby chats with name, participant count, and NSFW flag.
  - Anonymous users prompted to sign in if `allowAnonymous` is false.
  - Password entry for protected chats.

### 3.4 Chat Interaction
- **Description**: Users can interact within chats.
- **Requirements**:
  - Send text, audio (user-controlled recording), and GIF messages.
  - Creators can ban users or close chats, deleting all messages.
  - Real-time ban notifications via Firebase Cloud Messaging.

### 3.5 Settings
- **Description**: Users can manage preferences.
- **Requirements**:
  - Toggle location sharing.
  - Anonymous users see “Create Account” option to navigate to login.
  - Authenticated users see “Log Out” option.

## 4. Non-Functional Requirements

### 4.1 Performance
- Maintain 60 FPS in chat scrolling (optimized with `cacheExtent: 1000.0`).
- Notification latency under 100ms.

### 4.2 Security
- Data deleted after chat closure.
- Firebase rules ensure only creators can ban/close chats.

### 4.3 Compatibility
- iOS 14.0+ support, verified via Xcode build.
- Dependencies: `google_maps_flutter: ^2.5.0`, `firebase_auth: ^4.6.0`, `google_mobile_ads: ^3.0.0`.

## 5. Constraints
- Requires internet for real-time chat and ads.
- Location services must be enabled for geofencing.

## 6. Future Enhancements
- Add user profile editing for authenticated users.
- Implement “Manage Participants” feature for chat creators.