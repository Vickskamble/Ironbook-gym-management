import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/repositories/auth_repository.dart';

import 'helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGotrue mockAuth;
  late AuthRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = mockClient.auth;
    repository = AuthRepository(mockClient);
  });

  group('AuthRepository', () {
    group('signIn', () {
      test('throws Exception when user is null', () async {
        mockAuth.mockUser = null;
        mockAuth.mockSession = null;
        expect(
          () => repository.signIn(email: 'test@test.com', password: 'pass'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on auth error', () async {
        mockAuth.throwOnSignIn = true;
        expect(
          () => repository.signIn(email: 'bad@test.com', password: 'wrong'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('signUp', () {
      test('throws when user is null', () async {
        mockAuth.mockUser = null;
        mockAuth.mockSession = null;
        expect(
          () => repository.signUp(
            name: 'New User', email: 'new@ironbook.com', password: 'Password1',
            gymName: 'Test Gym', gymAddress: '123 Street', phone: '9876543210',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('signOut', () {
      test('signs out successfully', () async {
        await expectLater(repository.signOut(), completes);
      });

      test('throws on sign out failure', () async {
        mockAuth.throwOnSignOut = true;
        expect(() => repository.signOut(), throwsA(isA<Exception>()));
      });
    });

    group('getCurrentUser', () {
      test('returns null when no session', () async {
        mockAuth.mockSession = null;
        final profile = await repository.getCurrentUser();
        expect(profile, isNull);
      });
    });
  });
}
