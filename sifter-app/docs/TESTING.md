# Testing Documentation

## Overview

The Sifter App implements a comprehensive testing strategy to ensure code quality, reliability, and maintainability. This document outlines the testing approach, types of tests, and testing procedures used in the application.

## Testing Types

### 1. Unit Tests

#### Test Structure
```dart
void main() {
  group('AuthService Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late AuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthService(mockFirebaseAuth);
    });

    test('signInWithEmailAndPassword returns UserCredential', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: any,
        password: any,
      )).thenAnswer((_) async => mockUserCredential);

      // Act
      final result = await authService.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );

      // Assert
      expect(result, equals(mockUserCredential));
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });
  });
}
```

#### Mocking
```dart
@GenerateMocks([FirebaseAuth])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
  });
}
```

### 2. Widget Tests

#### Test Structure
```dart
void main() {
  testWidgets('LoginScreen shows error for invalid email',
      (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Act
    await tester.enterText(find.byType(EmailField), 'invalid-email');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Assert
    expect(find.text('Invalid email format'), findsOneWidget);
  });
}
```

#### Widget Testing Utilities
```dart
class TestUtils {
  static Future<void> pumpWidget(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: widget,
        ),
      ),
    );
  }

  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }
}
```

### 3. Integration Tests

#### Test Structure
```dart
void main() {
  integrationTest('Chat feature workflow', (tester) async {
    // Arrange
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ChatScreen), findsOneWidget);
  });
}
```

#### Integration Test Setup
```dart
class IntegrationTestSetup {
  static Future<void> setup() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Setup test user
    await _setupTestUser();

    // Setup test data
    await _setupTestData();
  }

  static Future<void> _setupTestUser() async {
    // Create test user
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );
  }

  static Future<void> _setupTestData() async {
    // Create test chat rooms
    await _createTestChatRooms();

    // Create test messages
    await _createTestMessages();
  }
}
```

## Test Coverage

### Coverage Configuration
```yaml
# coverage.yaml
coverage:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/generated/**"
    - "lib/firebase_options.dart"
  minimum_coverage: 80
```

### Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Data

### Test Fixtures
```dart
class TestFixtures {
  static User get testUser => User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

  static ChatRoom get testChatRoom => ChatRoom(
        id: 'test-chat-id',
        name: 'Test Chat',
        location: Location(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        radius: 100,
      );

  static Message get testMessage => Message(
        id: 'test-message-id',
        content: 'Test message',
        senderId: 'test-user-id',
        timestamp: DateTime.now(),
      );
}
```

### Test Helpers
```dart
class TestHelpers {
  static Future<void> createTestUser() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );
  }

  static Future<void> deleteTestUser() async {
    await FirebaseAuth.instance.currentUser?.delete();
  }

  static Future<void> createTestChatRoom() async {
    await FirebaseFirestore.instance.collection('chatrooms').add({
      'name': 'Test Chat',
      'location': GeoPoint(37.7749, -122.4194),
      'radius': 100,
    });
  }
}
```

## Performance Testing

### Performance Test Structure
```dart
void main() {
  test('chat room list performance', () async {
    final stopwatch = Stopwatch()..start();

    // Act
    final chatRooms = await ChatRepository().getNearbyChatRooms(
      Location(latitude: 37.7749, longitude: -122.4194),
    );

    stopwatch.stop();

    // Assert
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    expect(chatRooms.length, greaterThan(0));
  });
}
```

### Performance Metrics
```dart
class PerformanceMetrics {
  static Future<void> measureOperation(
    String operationName,
    Future<void> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    await operation();
    
    stopwatch.stop();
    
    await FirebaseAnalytics.instance.logEvent(
      name: 'performance_metric',
      parameters: {
        'operation': operationName,
        'duration_ms': stopwatch.elapsedMilliseconds,
      },
    );
  }
}
```

## Testing Best Practices

### 1. Test Organization
- Group related tests
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Keep tests independent

### 2. Test Data Management
- Use test fixtures
- Clean up test data
- Avoid test interdependencies
- Use meaningful test data

### 3. Mocking
- Mock external dependencies
- Use realistic mock data
- Verify mock interactions
- Keep mocks simple

### 4. Test Coverage
- Aim for high coverage
- Focus on critical paths
- Test edge cases
- Regular coverage reports

### 5. Performance
- Set performance benchmarks
- Monitor test execution time
- Optimize slow tests
- Regular performance testing

## Continuous Integration

### CI Configuration
```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter test --coverage
```

### Test Reports
```dart
class TestReporter {
  static Future<void> generateReport() async {
    // Generate test report
    final report = await _generateTestReport();

    // Save report
    await _saveReport(report);

    // Send notification
    await _sendNotification(report);
  }

  static Future<TestReport> _generateTestReport() async {
    // Collect test results
    final results = await _collectTestResults();

    // Generate report
    return TestReport(
      totalTests: results.length,
      passedTests: results.where((r) => r.passed).length,
      failedTests: results.where((r) => !r.passed).length,
      duration: results.fold(
        Duration.zero,
        (sum, result) => sum + result.duration,
      ),
    );
  }
}
```

## Test Maintenance

### 1. Regular Updates
- Update test dependencies
- Review test coverage
- Update test data
- Maintain test documentation

### 2. Test Review
- Code review for tests
- Test quality assessment
- Performance review
- Coverage analysis

### 3. Test Documentation
- Document test cases
- Maintain test data
- Update test procedures
- Document test environment

## Test Environment

### Environment Setup
```dart
class TestEnvironment {
  static Future<void> setup() async {
    // Setup Firebase
    await _setupFirebase();

    // Setup test data
    await _setupTestData();

    // Setup test user
    await _setupTestUser();
  }

  static Future<void> teardown() async {
    // Cleanup test data
    await _cleanupTestData();

    // Cleanup test user
    await _cleanupTestUser();
  }
}
```

### Environment Configuration
```dart
class TestConfig {
  static const testEmail = 'test@example.com';
  static const testPassword = 'password123';
  static const testLocation = Location(
    latitude: 37.7749,
    longitude: -122.4194,
  );
}
``` 