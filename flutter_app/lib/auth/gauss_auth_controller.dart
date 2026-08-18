import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum GaussAuthMode { signIn, createAccount }

enum GaussAuthStatus { restoring, signedOut, submitting, signedIn }

class GaussAuthController extends ChangeNotifier {
  GaussAuthController(this.client, {GaussAuthGateway? gateway})
    : _gateway = gateway ?? SupabaseGaussAuthGateway(client);

  final SupabaseClient client;
  final GaussAuthGateway _gateway;
  StreamSubscription<AuthState>? _subscription;
  GaussAuthStatus _status = GaussAuthStatus.restoring;
  GaussAuthMode _mode = GaussAuthMode.signIn;
  String? _message;

  GaussAuthStatus get status => _status;
  GaussAuthMode get mode => _mode;
  String? get message => _message;
  User? get user => _gateway.currentUser;
  bool get signedIn => _status == GaussAuthStatus.signedIn && user != null;
  bool get busy =>
      _status == GaussAuthStatus.restoring ||
      _status == GaussAuthStatus.submitting;

  Future<void> initialize() async {
    _subscription ??= _gateway.onAuthStateChange.listen((state) {
      _applySession(state.session);
    });
    _applySession(_gateway.currentSession);
  }

  void setMode(GaussAuthMode value) {
    if (_mode == value || busy) return;
    _mode = value;
    _message = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String email,
    required String password,
    String website = '',
  }) async {
    if (busy) return false;
    final normalizedEmail = email.trim().toLowerCase();
    final validation = _validate(normalizedEmail, password);
    if (validation != null) {
      _message = validation;
      notifyListeners();
      return false;
    }

    _status = GaussAuthStatus.submitting;
    _message = null;
    notifyListeners();
    var recoveringExistingAccount = false;
    try {
      if (_mode == GaussAuthMode.createAccount) {
        try {
          await _gateway.createAccount(
            email: normalizedEmail,
            password: password,
            website: website,
          );
        } on FunctionException catch (error) {
          if (error.status != 409) rethrow;
          // A previous registration may have completed remotely before the
          // client received its acknowledgement. The owner has already
          // supplied a password, so trying that credential is both private
          // and idempotent; it also removes the dead-end mode switch that used
          // to strand a freshly created account on this screen.
          recoveringExistingAccount = true;
        }
      }
      await _gateway.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      await _gateway.ensureProfile();
      _applySession(_gateway.currentSession);
      return signedIn;
    } on FunctionException catch (error) {
      _status = GaussAuthStatus.signedOut;
      _message = _functionMessage(error.status);
      notifyListeners();
      return false;
    } on AuthException catch (error) {
      _status = GaussAuthStatus.signedOut;
      if (recoveringExistingAccount) {
        _mode = GaussAuthMode.signIn;
      }
      _message = _authMessage(
        error,
        recoveringExistingAccount: recoveringExistingAccount,
      );
      notifyListeners();
      return false;
    } catch (_) {
      _status = GaussAuthStatus.signedOut;
      _message =
          'Gauss could not reach the observatory. Check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    _status = GaussAuthStatus.submitting;
    _message = null;
    notifyListeners();
    try {
      await _gateway.signOut();
    } finally {
      _applySession(null);
    }
  }

  Future<void> resendRecovery(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalizedEmail)) {
      _message = 'Enter the email connected to your orbit first.';
      notifyListeners();
      return;
    }
    _status = GaussAuthStatus.submitting;
    _message = null;
    notifyListeners();
    try {
      await _gateway.resetPasswordForEmail(normalizedEmail);
      _status = GaussAuthStatus.signedOut;
      _message = 'If that account exists, a reset email is on its way.';
      notifyListeners();
    } catch (_) {
      _status = GaussAuthStatus.signedOut;
      _message = 'Password reset is unavailable right now. Try again shortly.';
      notifyListeners();
    }
  }

  void _applySession(Session? session) {
    final next = session == null
        ? GaussAuthStatus.signedOut
        : GaussAuthStatus.signedIn;
    if (_status == next && (session == null) == (user == null)) return;
    _status = next;
    _message = null;
    notifyListeners();
  }

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  String? _validate(String email, String password) {
    if (!_emailPattern.hasMatch(email) || email.length > 254) {
      return 'Enter a valid email address.';
    }
    if (password.length < 10) {
      return 'Use at least 10 characters for your password.';
    }
    if (password.length > 72) {
      return 'Keep your password at 72 characters or fewer.';
    }
    return null;
  }

  String _functionMessage(int status) => switch (status) {
    409 => 'That orbit is unavailable. Try signing in with this email.',
    429 => 'Too many attempts. Let the observatory cool down, then try again.',
    _ => 'Account creation is unavailable right now. Try again shortly.',
  };

  String _authMessage(
    AuthException error, {
    bool recoveringExistingAccount = false,
  }) {
    final code = error.code ?? '';
    if (recoveringExistingAccount &&
        (code == 'invalid_credentials' || code == 'email_not_confirmed')) {
      return 'This email already has an orbit. Sign in with its password or reset it.';
    }
    if (code == 'invalid_credentials' || code == 'email_not_confirmed') {
      return 'The email or password does not match this orbit.';
    }
    if (code == 'over_request_rate_limit') {
      return 'Too many attempts. Wait a moment and try again.';
    }
    return 'Sign in could not be completed. Check the details and try again.';
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// Narrow, injectable boundary around Supabase Auth and the registration
/// function. The controller owns product state while this gateway owns remote
/// transport, which makes retry and recovery behavior deterministic in tests.
abstract interface class GaussAuthGateway {
  Stream<AuthState> get onAuthStateChange;

  Session? get currentSession;

  User? get currentUser;

  Future<void> createAccount({
    required String email,
    required String password,
    required String website,
  });

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> ensureProfile();

  Future<void> signOut();

  Future<void> resetPasswordForEmail(String email);
}

final class SupabaseGaussAuthGateway implements GaussAuthGateway {
  SupabaseGaussAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> createAccount({
    required String email,
    required String password,
    required String website,
  }) async {
    final response = await _client.functions.invoke(
      'gauss-signup',
      body: <String, Object?>{
        'email': email,
        'password': password,
        'website': website,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw const AuthException('Account creation was not completed.');
    }
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> ensureProfile() async {
    await _client.rpc('gauss_ensure_profile');
  }

  @override
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> resetPasswordForEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);
}
