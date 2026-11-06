import 'api.dart';

/// The owner's recovery email as the server reports it
/// (GET /owner/recovery-email). Only a verified address can receive
/// password reset codes.
class RecoveryEmailStatus {
  RecoveryEmailStatus({
    required this.email,
    required this.masked,
    required this.verified,
    required this.mailAvailable,
  });

  final String? email;
  final String? masked;
  final bool verified;
  final bool mailAvailable;

  factory RecoveryEmailStatus.fromJson(Map<String, dynamic> j) =>
      RecoveryEmailStatus(
        email: j['email'] as String?,
        masked: j['masked'] as String?,
        verified: (j['verified'] ?? false) as bool,
        mailAvailable: (j['mailAvailable'] ?? false) as bool,
      );
}

/// Password recovery by email for pet owners — the same Online routes the
/// web owner portal uses (digivetonline/server/src/routes/ownerRecovery*.js).
/// Nothing is stored on the phone.
class RecoveryService {
  RecoveryService._();
  static final RecoveryService instance = RecoveryService._();

  // ── signed in: the owner's own recovery email ──────────────────────

  Future<RecoveryEmailStatus> status() async => RecoveryEmailStatus.fromJson(
    await Api.instance.get('/owner/recovery-email'),
  );

  /// Mails a 6-digit code to [email]; returns the masked address it went to.
  Future<String> sendVerifyCode({
    required String email,
    required String password,
  }) async {
    final res = await Api.instance.post('/owner/recovery-email/send', {
      'email': email,
      'password': password,
    });
    return (res['sentTo'] ?? '') as String;
  }

  Future<RecoveryEmailStatus> confirmVerifyCode(String code) async =>
      RecoveryEmailStatus.fromJson(
        await Api.instance.post('/owner/recovery-email/confirm', {
          'code': code,
        }),
      );

  // ── signed out: forgot password ────────────────────────────────────

  /// Whether reset-by-email is switched on at all.
  Future<bool> available() async {
    final res = await Api.instance.get('/auth/owner-recovery/status');
    return (res['available'] ?? false) as bool;
  }

  /// Always answers the same way, whether or not the username exists.
  Future<void> requestResetCode(String username) =>
      Api.instance.post('/auth/owner-recovery/request', {'username': username});

  Future<void> resetPassword({
    required String username,
    required String code,
    required String newPassword,
  }) => Api.instance.post('/auth/owner-recovery/reset', {
    'username': username,
    'code': code,
    'newPassword': newPassword,
  });
}
