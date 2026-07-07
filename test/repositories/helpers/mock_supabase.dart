import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends SupabaseClient {
  MockSupabaseClient() : super('https://mock.supabase.co', 'mock-anon-key');

  final MockGotrue _mockAuth = MockGotrue();
  final _builders = <String, MockSupabaseQueryBuilder>{};

  @override
  MockGotrue get auth => _mockAuth;

  @override
  MockSupabaseQueryBuilder from(String table) {
    _builders.putIfAbsent(table, () => MockSupabaseQueryBuilder());
    return _builders[table]!;
  }
}

class MockGotrue extends GoTrueClient {
  MockGotrue()
      : super(
          url: 'https://mock.supabase.co/auth/v1',
          headers: {},
        );

  User? _mockUser;
  Session? _mockSession;
  bool _throwOnSignIn = false;
  bool _throwOnSignUp = false;
  bool _throwOnSignOut = false;

  set mockUser(User? user) => _mockUser = user;
  set mockSession(Session? session) => _mockSession = session;
  set throwOnSignIn(bool val) => _throwOnSignIn = val;
  set throwOnSignUp(bool val) => _throwOnSignUp = val;
  set throwOnSignOut(bool val) => _throwOnSignOut = val;

  @override
  Session? get currentSession => _mockSession;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (_throwOnSignIn) throw AuthException('Invalid credentials');
    if (_mockUser == null) {
      return AuthResponse(session: _mockSession, user: null);
    }
    return AuthResponse(session: _mockSession, user: _mockUser);
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel? channel,
    String? emailRedirectTo,
  }) async {
    if (_throwOnSignUp) throw AuthException('Signup failed');
    return AuthResponse(session: _mockSession, user: _mockUser);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    if (_throwOnSignOut) throw AuthException('Sign out failed');
  }
}

// ignore: must_be_immutable
class MockSupabaseQueryBuilder extends SupabaseQueryBuilder {
  MockSupabaseQueryBuilder()
      : super(
          'https://mock.supabase.co/rest/v1/profiles',
          RealtimeClient('wss://mock.supabase.co/realtime/v1'),
          schema: 'public',
          table: 'profiles',
          httpClient: null,
          incrementId: 1,
          isolate: null,
        );

  Map<String, dynamic>? mockSingleResult;
  Map<String, dynamic>? mockMaybeSingleResult;
  bool throwOnSelect = false;

  @override
  MockSupabaseFilterBuilder select([String columns = '*']) {
    return MockSupabaseFilterBuilder(
      singleResult: mockSingleResult,
      maybeSingleResult: mockMaybeSingleResult,
      throwOnSelect: throwOnSelect,
    );
  }

  @override
  MockSupabaseFilterBuilder insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    return MockSupabaseFilterBuilder(
      singleResult: mockSingleResult ?? (values is List && values.isNotEmpty
          ? Map<String, dynamic>.from(values.first)
          : null),
      maybeSingleResult: mockMaybeSingleResult,
      throwOnSelect: throwOnSelect,
    );
  }

  @override
  MockSupabaseFilterBuilder update(Map values) {
    return MockSupabaseFilterBuilder(
      singleResult: mockSingleResult ?? Map<String, dynamic>.from(values),
      maybeSingleResult: mockMaybeSingleResult,
      throwOnSelect: throwOnSelect,
    );
  }
}

class MockSupabaseFilterBuilder extends PostgrestFilterBuilder<PostgrestList> {
  final Map<String, dynamic>? _singleResult;
  final Map<String, dynamic>? _maybeSingleResult;
  final bool _throwOnSelect;

  MockSupabaseFilterBuilder({
    Map<String, dynamic>? singleResult,
    Map<String, dynamic>? maybeSingleResult,
    bool throwOnSelect = false,
  })  : _singleResult = singleResult,
        _maybeSingleResult = maybeSingleResult,
        _throwOnSelect = throwOnSelect,
        super(PostgrestBuilder<PostgrestList, PostgrestList, PostgrestList>(
          url: Uri.parse('https://mock.supabase.co/rest/v1/profiles'),
          headers: {},
        ));

  @override
  MockSupabaseFilterBuilder eq(String column, dynamic value) => this;

  @override
  MockPostgrestTransformBuilder<PostgrestList> select([String columns = '*']) {
    return MockPostgrestTransformBuilder<PostgrestList>(
      singleItem: _singleResult,
      shouldThrow: _throwOnSelect,
    );
  }

  @override
  MockPostgrestTransformBuilder<PostgrestMap> single() {
    return MockPostgrestTransformBuilder<PostgrestMap>(
      data: _singleResult,
      shouldThrow: _throwOnSelect,
    );
  }

  @override
  MockPostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return MockPostgrestTransformBuilder<PostgrestMap?>(
      data: _maybeSingleResult,
      shouldThrow: _throwOnSelect,
    );
  }
}

class MockPostgrestTransformBuilder<T> extends PostgrestTransformBuilder<T> {
  final T? data;
  final bool shouldThrow;
  final Map<String, dynamic>? singleItem;

  MockPostgrestTransformBuilder({
    this.data,
    this.shouldThrow = false,
    this.singleItem,
  }) : super(PostgrestBuilder<T, T, T>(
          url: Uri.parse('https://mock.supabase.co/rest/v1/profiles'),
          headers: {},
        ));

  @override
  MockPostgrestTransformBuilder<PostgrestMap> single() {
    return MockPostgrestTransformBuilder<PostgrestMap>(
      data: singleItem,
      shouldThrow: shouldThrow,
    );
  }

  @override
  MockPostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return MockPostgrestTransformBuilder<PostgrestMap?>(
      data: data as Map<String, dynamic>?,
      shouldThrow: shouldThrow,
    );
  }

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) {
    if (shouldThrow) {
      return Future.error(
        PostgrestException(message: 'Error', code: '404'),
        StackTrace.empty,
      );
    }
    if (data == null && null is! T) {
      return Future.error(
        PostgrestException(message: 'Not found', code: '404'),
        StackTrace.empty,
      );
    }
    return Future.value(data as T).then(onValue);
  }
}
