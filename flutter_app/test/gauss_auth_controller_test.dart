import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/auth/gauss_auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late _FakeGaussAuthGateway gateway;
  late GaussAuthController controller;

  setUp(() async {
    client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test_only',
    );
    gateway = _FakeGaussAuthGateway();
    controller = GaussAuthController(client, gateway: gateway);
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await gateway.dispose();
    client.dispose();
  });

  test(
    'a remote 409 recovers by signing in with the supplied credential',
    () async {
      gateway.createFailure = const FunctionException(
        status: 409,
        details: <String, Object?>{'code': 'account_unavailable'},
      );
      controller.setMode(GaussAuthMode.createAccount);

      final result = await controller.submit(
        email: ' Owner@Example.com ',
        password: 'a-private-passphrase',
      );

      expect(result, isTrue);
      expect(controller.status, GaussAuthStatus.signedIn);
      expect(controller.user?.id, 'test-user');
      expect(gateway.createCalls, 1);
      expect(gateway.signInCalls, 1);
      expect(gateway.ensureProfileCalls, 1);
      expect(gateway.lastEmail, 'owner@example.com');
    },
  );

  test(
    'an existing account with another password becomes a recoverable sign in',
    () async {
      gateway
        ..createFailure = const FunctionException(
          status: 409,
          details: <String, Object?>{'code': 'account_unavailable'},
        )
        ..signInFailure = const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        );
      controller.setMode(GaussAuthMode.createAccount);

      final result = await controller.submit(
        email: 'owner@example.com',
        password: 'another-private-passphrase',
      );

      expect(result, isFalse);
      expect(controller.status, GaussAuthStatus.signedOut);
      expect(controller.mode, GaussAuthMode.signIn);
      expect(
        controller.message,
        'This email already has an orbit. Sign in with its password or reset it.',
      );
      expect(gateway.signInCalls, 1);
      expect(gateway.ensureProfileCalls, 0);
    },
  );

  test('a registration outage does not attempt password sign in', () async {
    gateway.createFailure = const FunctionException(
      status: 503,
      details: <String, Object?>{'code': 'service_unavailable'},
    );
    controller.setMode(GaussAuthMode.createAccount);

    final result = await controller.submit(
      email: 'owner@example.com',
      password: 'a-private-passphrase',
    );

    expect(result, isFalse);
    expect(controller.status, GaussAuthStatus.signedOut);
    expect(
      controller.message,
      'Account creation is unavailable right now. Try again shortly.',
    );
    expect(gateway.signInCalls, 0);
    expect(gateway.ensureProfileCalls, 0);
  });
}

final class _FakeGaussAuthGateway implements GaussAuthGateway {
  final StreamController<AuthState> _states =
      StreamController<AuthState>.broadcast();

  Object? createFailure;
  Object? signInFailure;
  Session? _session;
  int createCalls = 0;
  int signInCalls = 0;
  int ensureProfileCalls = 0;
  String? lastEmail;

  @override
  Stream<AuthState> get onAuthStateChange => _states.stream;

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => _session?.user;

  @override
  Future<void> createAccount({
    required String email,
    required String password,
    required String website,
  }) async {
    createCalls += 1;
    lastEmail = email;
    if (createFailure case final Object error) throw error;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    lastEmail = email;
    if (signInFailure case final Object error) throw error;
    _session = Session(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      tokenType: 'bearer',
      user: const User(
        id: 'test-user',
        appMetadata: <String, dynamic>{'product': 'gauss'},
        userMetadata: <String, dynamic>{},
        aud: 'authenticated',
        createdAt: '2026-08-18T00:00:00Z',
        email: 'owner@example.com',
      ),
    );
  }

  @override
  Future<void> ensureProfile() async {
    ensureProfileCalls += 1;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  Future<void> dispose() => _states.close();
}
