import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Push notifications, "Level 0": every install subscribes to one Firebase
/// topic and LCVO sends announcements to it from the Firebase Console.
/// No device tokens are stored anywhere (Firebase tracks topic membership),
/// and neither the DIGIVET server nor Supabase is involved.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const announcementsTopic = 'lcvo-announcements';

  /// Lets foreground messages show as a snackbar (Android doesn't display a
  /// notification for a message that arrives while the app is open).
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  bool _started = false;

  /// Called once at app start. Never throws: push is a bonus, the app must
  /// work without it (no Google Play services, offline, etc.).
  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.subscribeToTopic(announcementsTopic);
      FirebaseMessaging.onMessage.listen(_showInApp);
      debugPrint('[Push] subscribed to $announcementsTopic');
    } catch (e) {
      debugPrint('[Push] unavailable: $e');
    }
  }

  /// Android 13+ asks the user once; earlier versions allow by default.
  Future<void> requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('[Push] permission request failed: $e');
    }
  }

  void _showInApp(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text([n.title, n.body].whereType<String>().join('\n')),
      ),
    );
  }
}
