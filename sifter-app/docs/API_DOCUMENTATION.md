# API Documentation

## Overview

The Sifter App API provides endpoints for managing chat rooms, user authentication, and real-time messaging. This documentation outlines the available endpoints, request/response formats, and authentication requirements.

## Base URL

```
https://api.sifter-app.com/v1
```

## Authentication

### Firebase Authentication

All API requests require Firebase Authentication. Include the Firebase ID token in the Authorization header:

```
Authorization: Bearer <firebase_id_token>
```

### Token Refresh

Firebase ID tokens expire after 1 hour. Implement token refresh logic:

```dart
FirebaseAuth.instance.currentUser?.getIdToken(true);
```

## Endpoints

### Authentication

#### Sign In

```http
POST /auth/signin
```

Request Body:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "user": {
    "uid": "user123",
    "email": "user@example.com",
    "displayName": "John Doe"
  },
  "token": "firebase_id_token"
}
```

#### Sign Up

```http
POST /auth/signup
```

Request Body:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "displayName": "John Doe"
}
```

Response:
```json
{
  "user": {
    "uid": "user123",
    "email": "user@example.com",
    "displayName": "John Doe"
  },
  "token": "firebase_id_token"
}
```

### Chat Rooms

#### Create Chat Room

```http
POST /chatrooms
```

Request Body:
```json
{
  "name": "Coffee Shop Chat",
  "radius": 100,
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  }
}
```

Response:
```json
{
  "id": "chat123",
  "name": "Coffee Shop Chat",
  "radius": 100,
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "createdAt": "2024-03-20T12:00:00Z",
  "createdBy": "user123"
}
```

#### Get Nearby Chat Rooms

```http
GET /chatrooms/nearby?lat=37.7749&lng=-122.4194&radius=1000
```

Response:
```json
{
  "chatrooms": [
    {
      "id": "chat123",
      "name": "Coffee Shop Chat",
      "distance": 50,
      "activeUsers": 5
    }
  ]
}
```

#### Join Chat Room

```http
POST /chatrooms/{chatId}/join
```

Response:
```json
{
  "success": true,
  "chatroom": {
    "id": "chat123",
    "name": "Coffee Shop Chat",
    "messages": []
  }
}
```

### Messages

#### Send Message

```http
POST /chatrooms/{chatId}/messages
```

Request Body:
```json
{
  "content": "Hello, world!",
  "type": "text"
}
```

Response:
```json
{
  "id": "msg123",
  "content": "Hello, world!",
  "type": "text",
  "sender": "user123",
  "timestamp": "2024-03-20T12:00:00Z"
}
```

#### Get Messages

```http
GET /chatrooms/{chatId}/messages?limit=50&before=2024-03-20T12:00:00Z
```

Response:
```json
{
  "messages": [
    {
      "id": "msg123",
      "content": "Hello, world!",
      "type": "text",
      "sender": "user123",
      "timestamp": "2024-03-20T12:00:00Z"
    }
  ],
  "hasMore": true
}
```

### User Profile

#### Get User Profile

```http
GET /users/{userId}
```

Response:
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoURL": "https://example.com/photo.jpg",
  "createdAt": "2024-03-20T12:00:00Z"
}
```

#### Update User Profile

```http
PATCH /users/{userId}
```

Request Body:
```json
{
  "displayName": "John Smith",
  "photoURL": "https://example.com/new-photo.jpg"
}
```

Response:
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "displayName": "John Smith",
  "photoURL": "https://example.com/new-photo.jpg",
  "updatedAt": "2024-03-20T12:00:00Z"
}
```

## Real-time Updates

### WebSocket Connection

Connect to WebSocket endpoint for real-time updates:

```
wss://api.sifter-app.com/v1/ws
```

### Events

#### Message Received

```json
{
  "type": "message",
  "data": {
    "id": "msg123",
    "content": "Hello, world!",
    "type": "text",
    "sender": "user123",
    "timestamp": "2024-03-20T12:00:00Z"
  }
}
```

#### User Joined

```json
{
  "type": "user_joined",
  "data": {
    "userId": "user123",
    "displayName": "John Doe"
  }
}
```

#### User Left

```json
{
  "type": "user_left",
  "data": {
    "userId": "user123"
  }
}
```

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {}
  }
}
```

### Common Error Codes

- `AUTH_REQUIRED`: Authentication required
- `INVALID_TOKEN`: Invalid authentication token
- `PERMISSION_DENIED`: User lacks required permissions
- `CHATROOM_NOT_FOUND`: Chat room not found
- `USER_NOT_FOUND`: User not found
- `INVALID_REQUEST`: Invalid request parameters
- `RATE_LIMITED`: Too many requests
- `SERVER_ERROR`: Internal server error

## Rate Limiting

- 100 requests per minute per user
- 1000 requests per hour per user
- Rate limit headers included in responses:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

## Best Practices

1. Implement exponential backoff for retries
2. Cache responses when appropriate
3. Handle token refresh automatically
4. Implement proper error handling
5. Use WebSocket for real-time updates
6. Monitor rate limits
7. Implement proper logging

## SDK Usage

### Flutter SDK

```dart
import 'package:sifter_app/sifter_app.dart';

final sifter = SifterApp(
  apiKey: 'your_api_key',
  baseUrl: 'https://api.sifter-app.com/v1'
);

// Sign in
final user = await sifter.auth.signIn(
  email: 'user@example.com',
  password: 'password123'
);

// Create chat room
final chatroom = await sifter.chatrooms.create(
  name: 'Coffee Shop Chat',
  radius: 100,
  location: Location(
    latitude: 37.7749,
    longitude: -122.4194
  )
);

// Send message
final message = await sifter.messages.send(
  chatroomId: 'chat123',
  content: 'Hello, world!',
  type: MessageType.text
);

// Listen to real-time updates
sifter.messages.listen((message) {
  print('New message: ${message.content}');
});
```

## Versioning

API versioning is handled through the URL path. Current version is v1.

## Support

For API support:
- Email: api-support@sifter-app.com
- Documentation: https://docs.sifter-app.com
- Status Page: https://status.sifter-app.com 