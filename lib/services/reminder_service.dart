import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/pet.dart';

/// On-phone vaccination reminders: a notification 7 days before each pet's
/// next dose and another on the due day, at 9:00 AM local time.
///
/// Everything happens on the device — no server, no push, nothing leaves the
/// phone. The text is deliberately minimal (pet name and vaccine only). The
/// schedule is rebuilt whenever the pet data loads, and wiped on sign-out.
class ReminderService extends ChangeNotifier {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _channelId = 'vaccination_reminders';
  static const _hour = 9; // 9:00 AM local
  static const _daysBefore = 7;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _enabled = await _readSetting();
      _ready = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Reminders] unavailable: $e');
    }
  }

  // The switch is remembered in a tiny file in the app's private folder.
  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}reminders.json');
  }

  Future<bool> _readSetting() async {
    try {
      final f = await _file;
      if (!await f.exists()) return false;
      return (jsonDecode(await f.readAsString()) as Map)['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeSetting(bool v) async {
    try {
      await (await _file).writeAsString(jsonEncode({'enabled': v}));
    } catch (_) {}
  }

  /// Turns reminders on (asking for permission first) or off. Returns false
  /// when the owner turned them on but the system permission was refused.
  Future<bool> setEnabled(bool value, List<Pet>? pets) async {
    await init();
    if (!_ready) return false;
    if (value) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? true;
      if (!granted) return false;
    }
    _enabled = value;
    await _writeSetting(value);
    notifyListeners();
    if (value) {
      await sync(pets);
    } else {
      await _plugin.cancelAll();
    }
    return true;
  }

  /// Rebuild the schedule from the current pets (no-op while reminders are off).
  Future<void> sync(List<Pet>? pets) async {
    if (!_ready || !_enabled || pets == null) return;
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final pet in pets) {
      final due = pet.nextDue;
      final vaccine = pet.latest?.vaccineName;
      if (due == null || vaccine == null) continue;
      final dueDay = tz.TZDateTime(
        tz.local,
        due.year,
        due.month,
        due.day,
        _hour,
      );
      await _schedule(
        id: _id(pet.id, 0),
        when: dueDay.subtract(const Duration(days: _daysBefore)),
        now: now,
        body: '${pet.name}’s $vaccine booster is due next week.',
      );
      await _schedule(
        id: _id(pet.id, 1),
        when: dueDay,
        now: now,
        body: '${pet.name}’s $vaccine booster is due today.',
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required tz.TZDateTime now,
    required String body,
  }) async {
    if (!when.isAfter(now)) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      title: 'Vaccination reminder',
      body: body,
      notificationDetails: _details,
      // Inexact: may fire a few minutes late, but needs no special alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Vaccination reminders',
      channelDescription: 'Reminders before your pet’s next vaccination',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // Stable per-pet notification ids (0 = week before, 1 = due day).
  int _id(String petId, int kind) => (petId.hashCode & 0x3fffffff) * 2 + kind;

  /// Sign-out: forget every pending reminder (they name the owner's pets).
  Future<void> clear() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
