import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quan_ly_cha_con/main.dart';
import 'package:quan_ly_cha_con/services/auth/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock SessionManager
class MockSessionManager extends Mock implements SessionManager {}

void main() {
  group('MyApp Widget Tests', () {
    late MockSessionManager mockSessionManager;

    setUp(() {
      mockSessionManager = MockSessionManager();

      // Mock methods
      when(mockSessionManager.isLoggedIn).thenReturn(false);
    });

    testWidgets('MyApp renders LoginScreen when not logged in',
            (WidgetTester tester) async {
          // Build our app and trigger a frame.
          await tester.pumpWidget(MyApp(sessionManager: mockSessionManager));

          // Verify that LoginScreen is displayed
          expect(find.text('Child Tracker'), findsOneWidget);
        });

    testWidgets('MyApp shows CircularProgressIndicator on splash',
            (WidgetTester tester) async {
          when(mockSessionManager.isLoggedIn).thenReturn(true);

          await tester.pumpWidget(MyApp(sessionManager: mockSessionManager));

          // Verify splash screen is shown
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });
  });
}