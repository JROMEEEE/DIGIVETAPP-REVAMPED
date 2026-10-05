import 'package:flutter/foundation.dart';

import 'api.dart';
import 'owner_data.dart';
import 'reminder_service.dart';

enum AuthStatus { checking, signedIn, signedOut }

/// Who is signed in, as the server reports it (`GET /api/auth/me`).
/// Only what the UI needs; nothing here is written to disk.
class OwnerUser {
  OwnerUser(this.username, this.role, this.firstName);

  final String username;
  final String role;
  final String? firstName;

  factory OwnerUser.fromJson(Map<String, dynamic> j) => OwnerUser(
    (j['username'] ?? '') as String,
    (j['role'] ?? '') as String,
    j['first_name'] as String?,
  );
}

/// What `POST /auth/claim/verify` tells an owner so they can confirm the Pet
/// Code is theirs: a masked name and their pets' names, nothing more.
class ClaimPreview {
  ClaimPreview(this.maskedName, this.petNames);

  final String maskedName;
  final List<String> petNames;

  factory ClaimPreview.fromJson(Map<String, dynamic> j) => ClaimPreview(
    (j['maskedName'] ?? '') as String,
    [for (final n in (j['petNames'] as List? ?? const [])) n as String],
  );
}

/// Owner authentication state for the whole app. The session itself is the
/// server's cookie (see [Api]); this class only tracks whether it is valid.
///
/// Owners only: this app has no staff/admin sign-in path.
class AuthService extends ChangeNotifier {
  AuthService._() {
    Api.instance.onUnauthorized = _sessionEnded;
  }
  static final AuthService instance = AuthService._();

  AuthStatus _status = AuthStatus.checking;
  OwnerUser? _user;

  AuthStatus get status => _status;
  OwnerUser? get user => _user;

  void _set(AuthStatus status, [OwnerUser? user]) {
    if (status != AuthStatus.signedIn) {
      OwnerData.instance.clear();
      ReminderService.instance.clear();
    }
    _status = status;
    _user = user;
    notifyListeners();
  }

  /// The owner edited their first name: update the greeting.
  void setFirstName(String? first) {
    final u = _user;
    if (u == null) return;
    _user = OwnerUser(u.username, u.role, first);
    notifyListeners();
  }

  // The server said 401 on some request: the session is gone.
  void _sessionEnded() {
    if (_status == AuthStatus.signedIn) {
      Api.instance.clearCookies();
      _set(AuthStatus.signedOut);
    }
  }

  /// Ask the server whether the stored cookie is still a valid owner session.
  /// Throws [ApiException] only when the server can't be reached (so the
  /// caller can offer a retry); an ended session just becomes signed-out.
  Future<void> checkSession() async {
    // Only notify on a real change: the splash calls this from initState,
    // and notifying then would rebuild the gate in the middle of a build.
    if (_status != AuthStatus.checking) _set(AuthStatus.checking);
    try {
      final me = await Api.instance.get('/auth/me');
      var user = OwnerUser.fromJson(me);
      if (user.role == 'owner') {
        user = await _withFirstName(user);
        _set(AuthStatus.signedIn, user);
      } else {
        // A non-owner session must never be usable in this app.
        await Api.instance.clearCookies();
        _set(AuthStatus.signedOut);
      }
    } on ApiException catch (e) {
      if (e.network) {
        _status =
            AuthStatus.checking; // stay on the splash so it can offer Retry
        rethrow;
      }
      await Api.instance.clearCookies();
      _set(AuthStatus.signedOut);
    }
  }

  // /auth/me doesn't include the person's name; the profile route does. A
  // failure here is cosmetic (we fall back to the username), never fatal.
  Future<OwnerUser> _withFirstName(OwnerUser user) async {
    try {
      final res = await Api.instance.get('/owner/profile');
      final profile = res['profile'];
      final first = profile is Map ? profile['first_name'] as String? : null;
      return OwnerUser(user.username, user.role, first);
    } on ApiException {
      return user;
    }
  }

  /// Sign in an owner. Throws [ApiException] with a safe message on failure
  /// (the server's wrong-credentials answer is deliberately generic).
  Future<void> login(String username, String password) async {
    final me = await Api.instance.post('/auth/owner-login', {
      'username': username.trim(),
      'password': password,
    });
    final user = OwnerUser.fromJson(me);
    if (user.role != 'owner') {
      await Api.instance.clearCookies();
      throw ApiException('Invalid username or password');
    }
    _set(AuthStatus.signedIn, await _withFirstName(user));
  }

  /// Step 1 of Pet Code sign-up. Read-only: no account is created. The server
  /// answers the same way for expired, used, revoked and unknown codes.
  Future<ClaimPreview> claimVerify(String code) async {
    final res = await Api.instance.post('/auth/claim/verify', {'code': code});
    return ClaimPreview.fromJson(res);
  }

  /// Step 2: creates the owner account and signs in (the server sets the
  /// session cookie on this response, exactly like a normal login).
  Future<void> claimRedeem(
    String code,
    String username,
    String password,
  ) async {
    final me = await Api.instance.post('/auth/claim/redeem', {
      'code': code,
      'username': username.trim(),
      'password': password,
    });
    _set(AuthStatus.signedIn, await _withFirstName(OwnerUser.fromJson(me)));
  }

  Future<void> logout() async {
    try {
      await Api.instance.post('/auth/logout');
    } on ApiException {
      // Even if the server can't be reached, sign out on this device.
    }
    await Api.instance.clearCookies();
    _set(AuthStatus.signedOut);
  }
}
