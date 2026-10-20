import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../features/prayer_calendar_page.dart' show SolarPrayerTimes;
import 'prayer_locations.dart';

class PrayerNotificationService {
  PrayerNotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const int _idStart = 4000;
  static const int _daysToSchedule = 12;

  static Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Fire an immediate diagnostic notification to check permissions and sound.
  static Future<bool> showTestNotification() async {
    try {
      await _initialize();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        if (granted == false) return false;
      }
      await _plugin.show(
        _idStart - 1,
        'ميثاق المؤمن — تجربة الإشعار',
        'إذا ظهر هذا التنبيه فقد وصل الإشعار التجريبي. افحص مستوى صوت التنبيهات إذا لم تسمع الأذان.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mithaq_shia_adhan_v2', 'أذان الصلاة',
            channelDescription: 'تنبيهات الصلاة بصوت الأذان المضمّن',
            importance: Importance.high, priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adhan_persian'),
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Test notification failed: $error\n$stackTrace');
      return false;
    }
  }

  /// Schedules local reminders with the bundled Persian adhan sound for the
  /// next 12 days using the app's clearly-labelled approximate calculation.
  static Future<bool> configure({
    required bool enabled,
    required PrayerCity city,
    bool requestExactPermission = false,
  }) async {
    try {
      await _initialize();
      var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        if (enabled && granted == false) return false;
        var canScheduleExact = await android?.canScheduleExactNotifications() ?? false;
        if (enabled && requestExactPermission && !canScheduleExact) {
          try {
            canScheduleExact = await android?.requestExactAlarmsPermission() ?? false;
          } catch (_) {
            // Exact alarms are optional; retain the inexact fallback if unavailable.
          }
        }
        if (canScheduleExact) scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= _idStart && request.id < _idStart + _daysToSchedule * 10) {
          await _plugin.cancel(request.id);
        }
      }
      if (!enabled) return true;

      final now = tz.TZDateTime.now(tz.local);
      const prayerLabels = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
      for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
        final date = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
        final times = SolarPrayerTimes.forDate(date, city.latitude, city.longitude, 3.0);
        final timeLabels = [times.fajr, times.noon, times.asr, times.maghrib, times.isha];
        for (var index = 0; index < timeLabels.length; index++) {
          final parts = timeLabels[index].split(':');
          if (parts.length != 2) continue;
          final scheduled = tz.TZDateTime(tz.local, date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
          if (!scheduled.isAfter(now.add(const Duration(seconds: 15)))) continue;
          final id = _idStart + dayOffset * 10 + index;
          await _plugin.zonedSchedule(
            id,
            'تذكير الصلاة — ${prayerLabels[index]}',
            'حان وقت ${prayerLabels[index]} وفق الحساب الفلكي التقديري داخل ميثاق المؤمن.',
            scheduled,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'mithaq_shia_adhan_v2',
                'أذان الصلاة',
                channelDescription: 'تنبيهات الصلاة بصوت الأذان الفارسي المضمّن',
                importance: Importance.high,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound('adhan_persian'),
                audioAttributesUsage: AudioAttributesUsage.alarm,
              ),
            ),
            androidScheduleMode: scheduleMode,
          );
        }
      }
      final scheduled = await _plugin.pendingNotificationRequests();
      final prayerReminders = scheduled.where((request) =>
        request.id >= _idStart && request.id < _idStart + _daysToSchedule * 10).length;
      if (prayerReminders == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('prayer_notifications_enabled', false);
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_notifications_enabled', true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _initialize();
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= _idStart && request.id < _idStart + _daysToSchedule * 10) {
          await _plugin.cancel(request.id);
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_notifications_enabled', false);
    } catch (_) {
      // The rest of the app remains available if notifications are unsupported.
    }
  }
}
