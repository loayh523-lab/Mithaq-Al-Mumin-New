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
  static const int _daysToSchedule = 30;

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
        final notificationsEnabled = await android?.areNotificationsEnabled();
        if (granted == false || notificationsEnabled == false) return false;
      }
      await _plugin.show(
        _idStart - 1,
        'ميثاق المؤمن — تجربة الإشعار',
        'إذا ظهر هذا التنبيه فقد وصل الإشعار التجريبي. افحص مستوى صوت التنبيهات إذا لم تسمع الأذان.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mithaq_prayer_adhan_v6', 'أذان الصلاة',
            channelDescription: 'أذان الشيخ شبّر معلة عند وقت الصلاة',

            sound: RawResourceAndroidNotificationSound('adhan_shabbar_maalla'),
            importance: Importance.high, priority: Priority.high,
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

  /// Schedules prayer-time reminders for the next 30 days. Times are estimates.
  /// The recording supplied for this project is bundled as an Android raw resource and
  /// used as the sound for prayer-time reminders. Early alerts use their own channel.
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
        final notificationsEnabled = await android?.areNotificationsEnabled();
        if (enabled && (granted == false || notificationsEnabled == false)) {
          return false;
        }
        var canScheduleExact = false;
        try {
          canScheduleExact = await android?.canScheduleExactNotifications() ?? false;
        } catch (_) {
          // Some Android builds do not expose exact-alarm status correctly.
        }
        if (enabled && requestExactPermission && !canScheduleExact) {
          try {
            canScheduleExact = await android?.requestExactAlarmsPermission() ?? false;
          } catch (_) {
            // Exact alarms are optional; retain the inexact fallback if unavailable.
          }
        }
        if (canScheduleExact) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        }
      }

      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= _idStart && request.id < _idStart + _daysToSchedule * 10) {
          await _plugin.cancel(request.id);
        }
      }
      if (!enabled) return true;

      final prefs = await SharedPreferences.getInstance();
      const prayerLabels = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
      const prayerKeys = ['fajr', 'noon', 'asr', 'maghrib', 'isha'];
      final prayerEnabled = <bool>[
        for (final key in prayerKeys)
          prefs.getBool('prayer_enabled_$key') ?? true,
      ];
      final earlyAlertEnabled =
          prefs.getBool('prayer_early_alert_enabled') ?? false;
      final earlyAlertMinutes =
          (prefs.getInt('prayer_early_alert_minutes') ?? 5).clamp(1, 30).toInt();
      final now = tz.TZDateTime.now(tz.local);
      for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
        final date = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
        final times = SolarPrayerTimes.forDate(date, city.latitude, city.longitude, 3.0);
        final timeLabels = [times.fajr, times.noon, times.asr, times.maghrib, times.isha];
        for (var index = 0; index < timeLabels.length; index++) {
          if (!prayerEnabled[index]) continue;
          final parts = timeLabels[index].split(':');
          if (parts.length != 2) continue;
          final scheduled = tz.TZDateTime(
            tz.local,
            date.year,
            date.month,
            date.day,
            int.tryParse(parts[0]) ?? 0,
            int.tryParse(parts[1]) ?? 0,
          );
          final id = _idStart + dayOffset * 10 + index;
          if (scheduled.isAfter(now.add(const Duration(seconds: 15)))) {
            await _plugin.zonedSchedule(
              id,
              'أذان ${prayerLabels[index]}',
              'حان الآن وقت صلاة ${prayerLabels[index]}.',
              scheduled,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'mithaq_prayer_adhan_v6',
                  'أذان الصلاة',
                  channelDescription: 'أذان الشيخ شبّر معلة عند وقت الصلاة',

                  sound: RawResourceAndroidNotificationSound('adhan_shabbar_maalla'),
                  importance: Importance.high,
                  priority: Priority.high,
                  audioAttributesUsage: AudioAttributesUsage.alarm,
                ),
              ),
              androidScheduleMode: scheduleMode,
            );
          }

          if (earlyAlertEnabled) {
            final earlyAt = scheduled.subtract(
              Duration(minutes: earlyAlertMinutes),
            );
            if (earlyAt.isAfter(now.add(const Duration(seconds: 15)))) {
              await _plugin.zonedSchedule(
                id + 5,
                'اقترب وقت صلاة ${prayerLabels[index]}',
                'باقي $earlyAlertMinutes دقائق على أذان ${prayerLabels[index]}.',
                earlyAt,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'mithaq_prayer_early_v1',
                    'التنبيه قبل الصلاة',
                    channelDescription: 'تنبيه هادئ قبل موعد الصلاة',
                    importance: Importance.defaultImportance,
                    priority: Priority.defaultPriority,
                    audioAttributesUsage: AudioAttributesUsage.notification,
                  ),
                ),
                androidScheduleMode: scheduleMode,
              );
            }
          }
        }
      }
      final scheduled = await _plugin.pendingNotificationRequests();
      final prayerReminders = scheduled.where((request) =>
        request.id >= _idStart && request.id < _idStart + _daysToSchedule * 10).length;
      if (prayerReminders == 0) {
        await prefs.setBool('prayer_notifications_enabled', false);
        return false;
      }
      await prefs.setBool('prayer_notifications_enabled', true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Prayer reminder scheduling failed: $error\\n$stackTrace');
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
