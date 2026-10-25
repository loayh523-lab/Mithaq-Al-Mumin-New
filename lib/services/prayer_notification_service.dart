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
  static final ValueNotifier<int?> notificationTap = ValueNotifier<int?>(null);
  static bool _initialized = false;
  static const int _idStart = 4000;
  static const int _daysToSchedule = 30;
  static const String _adhanChannelId = 'mithaq_adhan_shabbar_v13';
  // Increment this when the Android notification channel or schedule format changes.
  // Android keeps channel sound settings immutable, so a new channel ID is needed
  // when migrating the bundled adhan sound on existing installations.
  static const int _scheduleRevision = 13;

  static bool isPrayerNotificationId(int id) => _isPrayerReminderId(id);

  @visibleForTesting
  static bool isPrayerNotificationIdForTesting(int id) => isPrayerNotificationId(id);

  static Future<void> initialize() => _initialize();

  static Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final responseId = response.id;
        if (responseId != null && isPrayerNotificationId(responseId)) {
          notificationTap.value = responseId;
        }
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchId = launchDetails?.notificationResponse?.id;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        launchId != null &&
        isPrayerNotificationId(launchId)) {
      notificationTap.value = launchId;
    }
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
            _adhanChannelId, 'أذان الصلاة',
            channelDescription: 'أذان الصلاة من التسجيل المرفق بالتطبيق. إذا لم تسمع الصوت فتحقق من إعدادات قناة أذان الصلاة ومستوى صوت التنبيهات.',
            importance: Importance.high, priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adhan_shabbar_maalla'),
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

  /// Keeps an existing healthy schedule instead of rebuilding up to 30 days of
  /// notifications on every app launch. Settings changes still call configure().
  static Future<bool> ensureScheduled({required PrayerCity city}) async {
    try {
      await _initialize();
      final prefs = await SharedPreferences.getInstance();
      // Android persists notification-channel settings across upgrades. Rebuild old
      // schedules once so alarms move from the legacy sound channel to the new one.
      if (prefs.getInt('prayer_schedule_revision') != _scheduleRevision) {
        return await configure(enabled: true, city: city);
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled == false) {
          return await configure(enabled: true, city: city);
        }
      }

      const prayerKeys = ['fajr', 'noon', 'asr', 'maghrib', 'isha'];
      final selectedCount = prayerKeys
          .where((key) => prefs.getBool('prayer_enabled_$key') ?? true)
          .length;
      if (selectedCount == 0) {
        return await configure(enabled: true, city: city);
      }
      final minimumHealthyCount = selectedCount * 20;
      final pending = await _plugin.pendingNotificationRequests();
      final activeCount = pending
          .where((request) => _isPrayerReminderId(request.id))
          .length;
      if (activeCount >= minimumHealthyCount) return true;
      return await configure(enabled: true, city: city);
    } catch (error, stackTrace) {
      debugPrint('Checking scheduled prayer reminders failed: $error\\n$stackTrace');
      return await configure(enabled: true, city: city);
    }
  }

  /// Schedules local reminders for the next 30 days. Prayer times are estimates;
  /// the selected recording is bundled locally as the prayer notification sound.
  static Future<bool> configure({
    required bool enabled,
    required PrayerCity city,
    bool requestExactPermission = false,
  }) async {
    try {
      await _initialize();
      final prefs = await SharedPreferences.getInstance();
      var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (enabled) {
          final granted = await android?.requestNotificationsPermission();
          final notificationsEnabled = await android?.areNotificationsEnabled();
          if (granted == false || notificationsEnabled == false) {
            // Do not leave a stale "enabled" state when Android denies notifications.
            // Cancel our pending reminders as well, so a later permission change can
            // rebuild a clean schedule through ensureScheduled().
            final pendingOnDenied = await _plugin.pendingNotificationRequests();
            for (final request in pendingOnDenied) {
              if (request.id >= _idStart &&
                  request.id < _idStart + _daysToSchedule * 10) {
                await _plugin.cancel(request.id);
              }
            }
            await prefs.setBool('prayer_notifications_enabled', false);
            return false;
          }
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
      if (!enabled) {
        await prefs.setBool('prayer_notifications_enabled', false);
        await prefs.setInt('prayer_schedule_revision', _scheduleRevision);
        return true;
      }

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
      // Bound concurrent platform-channel calls. Scheduling up to 300 alarms
      // all at once can make slower Android devices unresponsive during refresh.
      final scheduledTasks = <Future<void> Function()>[];
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
            final prayerTitle = 'حان وقت الصلاة — ${prayerLabels[index]}';
            final prayerBody =
                'حان وقت ${prayerLabels[index]} وفق الحساب الفلكي التقديري داخل ميثاق المؤمن.';
            scheduledTasks.add(() => _plugin.zonedSchedule(
              id,
              prayerTitle,
              prayerBody,
              scheduled,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  _adhanChannelId,
                  'أذان الصلاة',
                  channelDescription: 'أذان الصلاة من التسجيل المرفق بالتطبيق. إذا لم تسمع الصوت فتحقق من إعدادات قناة أذان الصلاة ومستوى صوت التنبيهات.',
                  importance: Importance.high,
                  priority: Priority.high,
                  sound: RawResourceAndroidNotificationSound('adhan_shabbar_maalla'),
                  audioAttributesUsage: AudioAttributesUsage.alarm,
                ),
              ),
              androidScheduleMode: scheduleMode,
            ));
          }

          if (earlyAlertEnabled) {
            final earlyAt = scheduled.subtract(
              Duration(minutes: earlyAlertMinutes),
            );
            if (earlyAt.isAfter(now.add(const Duration(seconds: 15)))) {
              final earlyTitle = 'تنبيه قبل الصلاة — ${prayerLabels[index]}';
              final earlyBody =
                  'باقي $earlyAlertMinutes دقائق على وقت صلاة ${prayerLabels[index]}.';
              scheduledTasks.add(() => _plugin.zonedSchedule(
                id + 5,
                earlyTitle,
                earlyBody,
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
              ));
            }
          }
        }
      }
      for (var start = 0; start < scheduledTasks.length; start += 8) {
        final end = start + 8 < scheduledTasks.length
            ? start + 8
            : scheduledTasks.length;
        await Future.wait(
          scheduledTasks.getRange(start, end).map((schedule) => schedule()),
        );
      }
      final scheduled = await _plugin.pendingNotificationRequests();
      final prayerReminders = scheduled
          .where((request) => _isPrayerReminderId(request.id))
          .length;
      if (prayerReminders == 0) {
        await prefs.setBool('prayer_notifications_enabled', false);
        return false;
      }
      await prefs.setInt('prayer_schedule_revision', _scheduleRevision);
      await prefs.setBool('prayer_notifications_enabled', true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Prayer reminder scheduling failed: $error\\n$stackTrace');
      return false;
    }
  }


  static bool _isPrayerReminderId(int id) {
    if (id < _idStart || id >= _idStart + _daysToSchedule * 10) {
      return false;
    }
    // Each day uses slots 0-4 for prayer times and 5-9 for early alerts.
    return (id - _idStart) % 10 < 5;
  }

  @visibleForTesting
  static bool isPrayerReminderNotificationIdForTesting(int id) =>
      _isPrayerReminderId(id);

  /// Number of scheduled prayer-time reminders (excludes the earlier heads-up).
  /// Returns -1 when the platform notification API could not be queried.
  static Future<int> pendingPrayerReminderCount() async {
    try {
      await _initialize();
      final pending = await _plugin.pendingNotificationRequests();
      return pending
          .where((request) => _isPrayerReminderId(request.id))
          .length;
    } catch (error, stackTrace) {
      debugPrint('Reading scheduled prayer reminders failed: $error\\n$stackTrace');
      return -1;
    }
  }

  /// Returns the Android app-level notification permission state when available.
  /// Whether Android currently allows precise alarm scheduling.
  /// False means alarms fall back to an inexact schedule and may be delayed.
  static Future<bool?> exactAlarmsAreEnabled() async {
    try {
      await _initialize();
      if (defaultTargetPlatform != TargetPlatform.android) return null;
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.canScheduleExactNotifications();
    } catch (error, stackTrace) {
      debugPrint('Reading exact alarm permission failed: $error\\n$stackTrace');
      return null;
    }
  }

  static Future<bool?> notificationsAreEnabled() async {
    try {
      await _initialize();
      if (defaultTargetPlatform != TargetPlatform.android) return null;
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled();
    } catch (error, stackTrace) {
      debugPrint('Reading notification permission state failed: $error\\n$stackTrace');
      return null;
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
