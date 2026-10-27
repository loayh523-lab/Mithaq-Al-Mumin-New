import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_locations.dart';
import '../services/prayer_notification_service.dart';
import '../services/app_theme.dart';

const _settingsGold = Color(0xFFD9B66D);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onLocationChanged, this.embedded = false});
  final Future<void> Function()? onLocationChanged;
  final bool embedded;
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  PrayerCity _currentCity = PrayerLocations.cities.first;
  List<PrayerAdministrativeDivision> _administrativeDivisions =
      const <PrayerAdministrativeDivision>[];
  String? _selectedGovernorateId;
  String? _selectedDistrictId;
  String? _selectedSubdistrictId;
  bool _placeSelectionDirty = false;
  static const _districtCenterValue = '__district_center__';

  List<PrayerAdministrativeDivision> get _governorates =>
      PrayerLocations.governoratesFrom(_administrativeDivisions);

  List<PrayerAdministrativeDivision> get _districtOptions =>
      _selectedGovernorateId == null
          ? const <PrayerAdministrativeDivision>[]
          : PrayerLocations.districtsFrom(
              _administrativeDivisions,
              _selectedGovernorateId!,
            );

  List<PrayerAdministrativeDivision> get _subdistrictOptions =>
      _selectedDistrictId == null
          ? const <PrayerAdministrativeDivision>[]
          : PrayerLocations.subdistrictsFrom(
              _administrativeDivisions,
              _selectedDistrictId!,
            );
  double _fontSize = 24;
  bool _loaded = false;
  bool _notificationsEnabled = false;
  bool _notificationBusy = false;
  bool _gpsBusy = false;
  bool _earlyAlertEnabled = false;
  int _earlyAlertMinutes = 5;
  Map<String, bool> _prayerEnabled = {
    'fajr': true,
    'noon': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  static const _prayerOptions = <MapEntry<String, String>>[
    MapEntry('fajr', 'الفجر'),
    MapEntry('noon', 'الظهر'),
    MapEntry('asr', 'العصر'),
    MapEntry('maghrib', 'المغرب'),
    MapEntry('isha', 'العشاء'),
  ];
  AudioPlayer? _adhanPlayer;
  StreamSubscription<void>? _adhanCompleteSubscription;
  bool _isPlayingAdhan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh Android permission state and reconcile the saved prayer schedule
      // after returning from notification/exact-alarm settings.
      unawaited(_refreshAfterSystemSettings());
    }
  }

  Future<void> _refreshAfterSystemSettings() async {
    await _load();
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('prayer_notifications_enabled') != true) return;

      final city = await PrayerLocations.load();
      final scheduled = await PrayerNotificationService.ensureScheduled(city: city);
      if (!mounted) return;
      final exactAlarms = await PrayerNotificationService.exactAlarmsAreEnabled();

      if (!scheduled) {
        _message('رجعت من إعدادات أندرويد، لكن تعذّر التحقق من جدولة الأذان. افتح فحص جدولة الأذان وحاول مرة ثانية.');
      } else if (exactAlarms == false) {
        _message('الإشعارات مفعّلة، لكن إذن المنبهات الدقيقة غير مفعّل؛ قد يتأخر الأذان. فعّل الإذن ثم ارجع للتطبيق.');
      }
    } catch (_) {
      // Keep settings usable even if Android does not expose permission state.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adhanCompleteSubscription?.cancel();
    final player = _adhanPlayer;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  Future<void> _toggleAdhanPlayback() async {
    final existing = _adhanPlayer;
    if (_isPlayingAdhan) {
      try {
        await existing?.stop();
      } catch (_) { /* The local notification feature remains available. */ }
      if (mounted) setState(() => _isPlayingAdhan = false);
      return;
    }
    try {
      final player = _adhanPlayer ??= AudioPlayer(playerId: 'mithaq-adhan-preview');
      _adhanCompleteSubscription ??= player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingAdhan = false);
      });
      await player.stop();
      await player.play(AssetSource('audio/adhan_shabbar_maalla_preview.mp3'));
      if (mounted) setState(() => _isPlayingAdhan = true);
    } catch (error) {
      if (mounted) _message('تعذّر تشغيل التسجيل الصوتي. جرّب إعادة فتح التطبيق أو تحقق من الملف المرفق.');
    }
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Load local settings first so notification switches and unrelated settings
    // remain usable while the larger optional administrative dataset is parsed.
    setState(() {
      _fontSize = (prefs.getDouble('quran_font_size') ?? 24)
          .clamp(16, 34)
          .toDouble();
      _notificationsEnabled =
          prefs.getBool('prayer_notifications_enabled') ?? false;
      _earlyAlertEnabled =
          prefs.getBool('prayer_early_alert_enabled') ?? false;
      _earlyAlertMinutes =
          (prefs.getInt('prayer_early_alert_minutes') ?? 5)
              .clamp(1, 30)
              .toInt();
      _prayerEnabled = {
        for (final option in _prayerOptions)
          option.key: prefs.getBool('prayer_enabled_${option.key}') ?? true,
      };
      _loaded = true;
    });

    unawaited(_loadSavedAdministrativePlace());
    unawaited(_reconcileNotificationPermission());
  }

  Future<void> _loadSavedAdministrativePlace() async {
    var savedCity = PrayerLocations.cities.first;
    var divisions = <PrayerAdministrativeDivision>[];
    try {
      divisions = await PrayerLocations.administrativeDivisions();
      savedCity = await PrayerLocations.load();
    } catch (_) {
      // The settings screen remains usable if the optional place list is missing.
    }

    final selected = PrayerLocations.divisionById(divisions, savedCity.id) ??
        PrayerLocations.nearestDivision(
          divisions,
          latitude: savedCity.latitude,
          longitude: savedCity.longitude,
          level: 3,
        );
    final governorates =
        divisions.where((item) => item.level == 1).toList(growable: false);
    final defaultGovernorate =
        governorates.isEmpty ? null : governorates.first;

    if (!mounted || _placeSelectionDirty) return;
    setState(() {
      _administrativeDivisions = divisions;
      _currentCity = savedCity;
      _selectedGovernorateId =
          selected?.governorateId ?? defaultGovernorate?.id;
      _selectedDistrictId = selected?.level == 3
          ? selected?.districtId
          : selected?.level == 2
              ? selected?.id
              : null;
      _selectedSubdistrictId =
          selected?.level == 3 ? selected?.id : null;
      _placeSelectionDirty = !savedCity.isCurrentLocation &&
          selected != null &&
          selected.id != savedCity.id;
    });
  }

  Future<void> _reconcileNotificationPermission() async {
    try {
      final actualPermission =
          await PrayerNotificationService.notificationsAreEnabled();
      if (!mounted || actualPermission != false) return;
      // Reflect an OS-level denial without blocking unrelated settings.
      if (_notificationsEnabled) {
        setState(() => _notificationsEnabled = false);
      }
    } catch (_) {
      // Permission state is platform-dependent; keep saved settings usable.
    }
  }

  void _selectGovernorate(String? id) {
    if (id == null) return;
    setState(() {
      _selectedGovernorateId = id;
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _placeSelectionDirty = true;
    });
  }

  void _selectDistrict(String? id) {
    if (id == null) return;
    setState(() {
      _selectedDistrictId = id;
      _selectedSubdistrictId = null;
      _placeSelectionDirty = true;
    });
  }

  void _selectSubdistrict(String? id) {
    setState(() {
      _selectedSubdistrictId =
          id == _districtCenterValue ? null : id;
      _placeSelectionDirty = true;
    });
  }

  Future<void> _saveSelectedPlace() async {
    final targetId = _selectedSubdistrictId ?? _selectedDistrictId;
    if (targetId == null) {
      _message('اختَر المحافظة والقضاء أولاً، ثم احفظ الموقع.');
      return;
    }
    final target = PrayerLocations.divisionById(
      _administrativeDivisions,
      targetId,
    );
    if (target == null ||
        target.governorateId != _selectedGovernorateId ||
        (target.level == 3 && target.districtId != _selectedDistrictId)) {
      _message('اختيار الموقع غير مكتمل. راجع المحافظة والقضاء ثم حاول مجدداً.');
      return;
    }

    final city = PrayerLocations.cityForDivision(target);
    try {
      await PrayerLocations.savePlace(target);
      if (!mounted) return;
      setState(() {
        _currentCity = city;
        _placeSelectionDirty = false;
      });

      if (widget.onLocationChanged != null) {
        await widget.onLocationChanged!.call();
      } else if (_notificationsEnabled) {
        final ok = await PrayerNotificationService.configure(
          enabled: true,
          city: city,
        );
        if (!ok && mounted) {
          _message('تم حفظ الموقع لكن تعذّر تحديث تذكيرات الصلاة. افحص الأذونات.');
          return;
        }
      }
      if (mounted) _message('تم حفظ الموقع للمواقيت والقبلة');
    } catch (_) {
      if (mounted) _message('تعذّر حفظ الموقع على الجهاز');
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsBusy = true);
    try {
      final city = await PrayerLocations.acquirePreciseLocation();
      if (!mounted) return;
      if (city == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ما حصلنا GPS بدقة كافية. فعّل الموقع واسمح للتطبيق بالموقع، ثم جرّب مجدداً.'),
              action: SnackBarAction(
                label: 'أذونات التطبيق',
                onPressed: () => unawaited(_openAppPermissionsSettings()),
              ),
            ),
          );
        }
        return;
      }
      final nearest = PrayerLocations.nearestDivision(
        _administrativeDivisions,
        latitude: city.latitude,
        longitude: city.longitude,
        level: 3,
      );
      setState(() {
        _currentCity = city;
        if (nearest != null) {
          _selectedGovernorateId = nearest.governorateId;
          _selectedDistrictId = nearest.districtId;
          _selectedSubdistrictId = nearest.id;
        }
        _placeSelectionDirty = false;
      });
      if (widget.onLocationChanged != null) {
        // Let the parent update prayer times and notifications exactly once.
        await widget.onLocationChanged!.call();
      } else if (_notificationsEnabled) {
        final ok = await PrayerNotificationService.configure(
          enabled: true,
          city: city,
        );
        if (!ok && mounted) _message('حُفظ الموقع لكن تعذّر تحديث تذكيرات الصلاة');
      }
      final accuracy = await PrayerLocations.currentLocationAccuracy();
      if (mounted) {
        _message(accuracy == null
          ? 'تم تحديث موقع GPS للمواقيت والقبلة'
          : 'تم تحديث GPS بدقة تقريبية ${accuracy.round()} متر للمواقيت والقبلة');
      }
    } catch (_) {
      if (mounted) _message('تعذّر تحديد الموقع. فعّل GPS وتحقق من إذن الموقع.');
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }


  Future<void> _checkNotificationSchedule() async {
    final count = await PrayerNotificationService.pendingPrayerReminderCount();
    final allowed = await PrayerNotificationService.notificationsAreEnabled();
    final exactAlarms = await PrayerNotificationService.exactAlarmsAreEnabled();
    if (!mounted) return;
    if (allowed == false) {
      _message('إذن الإشعارات مرفوض من أندرويد. فعّله من إعدادات التطبيق ثم جرّب مجدداً.');
    } else if (count < 0) {
      _message('تعذّر قراءة مواعيد الإشعارات من النظام. جرّب إعادة تشغيل التطبيق.');
    } else if (!_notificationsEnabled || count == 0) {
      _message('ماكو مواعيد أذان مجدولة حالياً. فعّل إشعارات الصلاة أولاً.');
    } else if (exactAlarms == false) {
      _message('أكو $count موعد أذان محفوظ، لكن إذن «المنبهات والتذكيرات» غير مفعّل وقد يتأخر التنبيه. افحص أيضاً قيود البطارية والتشغيل بالخلفية.');
    } else {
      _message('النظام يحتفظ حالياً بـ$count موعد أذان مجدول. افحص أيضاً قيود البطارية والتشغيل بالخلفية إذا لم يظهر التنبيه.');
    }
  }

  Future<void> _testNotification() async {
    final ok = await PrayerNotificationService.showTestNotification();
    if (!mounted) return;
    _message(ok
      ? 'أرسلنا الإشعار التجريبي. إذا لم يظهر، افحص إذن الإشعارات وإعدادات قناة أذان الصلاة.'
      : 'فشل الإشعار التجريبي. فعّل إشعارات التطبيق من إعدادات أندرويد ثم جرّب مرة ثانية.');
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (_notificationBusy) return;
    if (enabled && !_prayerEnabled.values.any((value) => value)) {
      _message('فعّل صلاة واحدة على الأقل قبل تشغيل التذكيرات');
      return;
    }
    setState(() => _notificationBusy = true);
    try {
      if (!enabled) {
        await PrayerNotificationService.cancelAll();
        if (!mounted) return;
        setState(() => _notificationsEnabled = false);
        _message('تم إيقاف تذكيرات الصلاة');
        return;
      }

      // Ask for Android permission first; do not wait through schedule creation
      // without showing the user that activation is in progress.
      final ok = await PrayerNotificationService.configure(
        enabled: true,
        city: _currentCity,
        requestExactPermission: true,
      );
      if (!mounted) return;
      final exactAlarms = ok
          ? await PrayerNotificationService.exactAlarmsAreEnabled()
          : false;
      if (!mounted) return;
      setState(() => _notificationsEnabled = ok);
      if (!ok) {
        _message('ما اكتمل التفعيل. اسمح بإشعارات ميثاق المؤمن من إعدادات أندرويد ثم اضغط تفعيل مرة ثانية.');
      } else if (exactAlarms == false) {
        _message('إشعارات الصلاة مفعّلة، لكن أندرويد لم يمنح إذن «المنبهات والتذكيرات»؛ قد يتأخر الأذان عن وقته. فعّل الإذن من وصول خاص للتطبيقات ثم أعد تفعيل الإشعارات.');
      } else if (exactAlarms == true) {
        _message('تم تفعيل إشعارات الصلاة وجدولة المواعيد الثلاثين يوماً القادمة بالتوقيت الدقيق، بحسب قيود الجهاز والنظام.');
      } else {
        _message('تم تفعيل إشعارات الصلاة وجدولة المواعيد للأيام الثلاثين القادمة. تعذّر التحقق من صلاحية التوقيت الدقيق على هذا الجهاز.');
      }
    } catch (_) {
      if (mounted) _message('صار خطأ أثناء تفعيل الإشعارات. تحقق من إذن أندرويد ثم حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _notificationBusy = false);
    }
  }

  Future<void> _refreshReminderSchedule() async {
    if (!_notificationsEnabled) return;
    if (!_prayerEnabled.values.any((value) => value)) {
      await PrayerNotificationService.cancelAll();
      if (!mounted) return;
      setState(() => _notificationsEnabled = false);
      _message('أوقفت كل الصلوات، لذلك أوقفنا التذكيرات أيضاً');
      return;
    }
    final ok = await PrayerNotificationService.configure(
      enabled: true,
      city: _currentCity,
    );
    if (!mounted) return;
    setState(() => _notificationsEnabled = ok);
    if (!ok) {
      _message('تعذّر تحديث جدول التذكيرات؛ تحقق من الأذونات');
    }
  }

  Future<void> _togglePrayerReminder(String key, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_enabled_$key', enabled);
      if (!mounted) return;
      setState(() => _prayerEnabled = {..._prayerEnabled, key: enabled});
      await _refreshReminderSchedule();
    } catch (_) {
      if (mounted) _message('تعذّر حفظ إعداد الصلاة على الجهاز');
    }
  }

  Future<void> _toggleEarlyAlert(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_early_alert_enabled', enabled);
      if (!mounted) return;
      setState(() => _earlyAlertEnabled = enabled);
      await _refreshReminderSchedule();
    } catch (_) {
      if (mounted) _message('تعذّر حفظ إعداد التنبيه المسبق');
    }
  }

  Future<void> _changeEarlyAlertMinutes(int? minutes) async {
    if (minutes == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('prayer_early_alert_minutes', minutes);
      if (!mounted) return;
      setState(() => _earlyAlertMinutes = minutes);
      await _refreshReminderSchedule();
    } catch (_) {
      if (mounted) _message('تعذّر حفظ مدة التنبيه المسبق');
    }
  }

  Future<void> _saveFontSize(double value) async {
    setState(() => _fontSize = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_font_size', value);
  }

  Future<void> _openAppPermissionsSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (_) {
      if (mounted) _message('تعذّر فتح إعدادات التطبيق. افتحها يدوياً من إعدادات أندرويد.');
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {
      await _openAppPermissionsSettings();
      if (mounted) _message('افتح قسم الإشعارات داخل إعدادات التطبيق واسمح بعرضها.');
    }
  }

  Future<void> _openDeviceLocationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.location);
    } catch (_) {
      if (mounted) _message('تعذّر فتح إعدادات الموقع. فعّل الموقع من لوحة الإعدادات السريعة.');
    }
  }

  Future<void> _openExactAlarmSettings() async {
    try {
      final granted = await PrayerNotificationService.requestExactAlarmsPermission();
      if (granted == true) {
        if (_notificationsEnabled) await _refreshReminderSchedule();
        if (mounted) _message('تم منح إذن المنبهات الدقيقة. افحص جدولة الأذان مرة ثانية.');
      } else {
        if (mounted) {
          _message('إذا ما ظهرت صفحة الإذن، افتح إعدادات أذونات التطبيق وابحث عن «المنبهات والتذكيرات».');
        }
        await _openAppPermissionsSettings();
      }
    } catch (_) {
      if (mounted) _message('تعذّر فتح إذن المنبهات الدقيقة. افتح إعدادات التطبيق وتحقق منه يدوياً.');
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override Widget build(BuildContext context) {
    final city = _currentCity;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 24), children: [
      if (!widget.embedded) ...[
        Text('الإعدادات', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text('خصّص التطبيق بما يناسبك، وتُحفظ هذه الخيارات على جهازك.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
        const SizedBox(height: 18),
      ],
      _section(
        icon: Icons.palette_outlined,
        title: 'مظهر التطبيق',
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AppTheme.isDark,
            builder: (context, isDark, child) => Row(
              children: [
                Expanded(
                  child: _themeOption(dark: false, selected: !isDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _themeOption(dark: true, selected: isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'يتغيّر المظهر فوراً ويُحفظ اختيارك على هذا الجهاز.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.location_on_outlined,
        title: 'المدينة ومواقيت الصلاة',
        children: [
          Text('اختر أقرب مدينة إليك. الحسابات الفلكية المعروضة تقريبية ويجب مقارنتها بمواقيت مكتب مرجعك.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6, fontSize: 12)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('prayer-governorate-${_selectedGovernorateId ?? 'none'}'),
            initialValue: _selectedGovernorateId,
            decoration: const InputDecoration(
              labelText: 'المحافظة',
              border: OutlineInputBorder(),
            ),
            items: _governorates
                .map((item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ))
                .toList(),
            onChanged: _loaded ? _selectGovernorate : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('prayer-district-${_selectedDistrictId ?? 'none'}'),
            initialValue: _selectedDistrictId,
            decoration: const InputDecoration(
              labelText: 'القضاء',
              border: OutlineInputBorder(),
            ),
            items: _districtOptions
                .map((item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ))
                .toList(),
            onChanged: _loaded && _selectedGovernorateId != null
                ? _selectDistrict
                : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('prayer-subdistrict-${_selectedDistrictId ?? 'none'}-${_selectedSubdistrictId ?? _districtCenterValue}'),
            initialValue: _selectedDistrictId == null
                ? null
                : (_selectedSubdistrictId ?? _districtCenterValue),
            decoration: const InputDecoration(
              labelText: 'الناحية / مركز القضاء',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: _districtCenterValue,
                child: Text('مركز القضاء'),
              ),
              ..._subdistrictOptions.map((item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  )),
            ],
            onChanged:
                _loaded && _selectedDistrictId != null
                    ? _selectSubdistrict
                    : null,
          ),
          const SizedBox(height: 8),
          Text(
            'اختر المحافظة ثم القضاء، ويمكنك تحديد ناحية أدق إن كانت متاحة. تستخدم المراكز الإدارية وإحداثياتها التقديرية؛ GPS أدق عند توفره.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loaded &&
                      _selectedDistrictId != null &&
                      _placeSelectionDirty
                  ? _saveSelectedPlace
                  : null,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('حفظ موقع الحساب'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded && !_gpsBusy ? _useCurrentLocation : null,
              icon: _gpsBusy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
              label: Text(_gpsBusy ? 'جارٍ تحديد الموقع...' : 'استخدام موقعي الحالي تلقائياً'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _openAppPermissionsSettings : null,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('فتح إعدادات أذونات التطبيق'),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _openDeviceLocationSettings : null,
              icon: const Icon(Icons.location_searching_rounded),
              label: const Text('فتح إعدادات الموقع في الجهاز'),
            ),
          ),
          Text(
            city.isCurrentLocation
                ? 'يُستخدم GPS حالياً: ${city.latitude.toStringAsFixed(4)}, ${city.longitude.toStringAsFixed(4)} — محفوظ على الجهاز'
                : city.administrativeLabel.isNotEmpty
                    ? '${city.administrativeLabel}\nالإحداثيات: ${city.latitude.toStringAsFixed(3)}, ${city.longitude.toStringAsFixed(3)}'
                    : 'الموقع المحفوظ: ${city.name} • الإحداثيات التقريبية: ${city.latitude.toStringAsFixed(3)}, ${city.longitude.toStringAsFixed(3)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'بيانات التقسيم الإداري: Open Admin Data (CC BY 4.0). إحداثيات المراكز تقريبية؛ GPS أدق عند توفره.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.notifications_active_outlined,
        title: 'تذكيرات الصلاة',
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('إشعارات الصلاة'),
              subtitle: Text(_notificationBusy ? 'جارٍ طلب الإذن وجدولة مواقيت الصلاة…' : (_notificationsEnabled ? 'الإشعارات مفعّلة. إذا لا يصل الأذان، افحص إذن أندرويد وقناة صوت الأذان.' : 'اضغط لتفعيل إشعارات الصلاة. سيطلب أندرويد الإذن عند الحاجة، ثم تُجدول المواعيد للأيام الثلاثين القادمة.'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontSize: 12)),
              value: _notificationsEnabled,
              onChanged: _loaded && !_notificationBusy ? _toggleNotifications : null,
              activeThumbColor: _settingsGold,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _openNotificationSettings : null,
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('فتح إعدادات إشعارات أندرويد'),
            ),
          ),
          ExpansionTile(
            key: const ValueKey('advanced-prayer-notifications'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 10),
            leading: Icon(
              Icons.tune_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text(
              'خيارات الأذان المتقدمة',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'تخصيص الصلوات، تجربة الصوت، فحص الجدولة وحلول الخلفية',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            children: [
          const SizedBox(height: 10),
          Text(
            'تخصيص تنبيهات كل صلاة',
            style: TextStyle(fontWeight: FontWeight.w700, color: _settingsGold),
          ),
          const SizedBox(height: 4),
          ..._prayerOptions.map((option) => Material(
            color: Theme.of(context).colorScheme.surface,
            child: SwitchListTile(
              key: ValueKey('prayer_enabled_${option.key}'),
              contentPadding: EdgeInsets.zero,
              title: Text('أذان ${option.value}'),
              subtitle: Text(
                _prayerEnabled[option.key] == true
                    ? 'الأذان والتذكير مفعّلان'
                    : 'لا يوجد تنبيه لهذه الصلاة',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
              ),
              value: _prayerEnabled[option.key] ?? true,
              onChanged: _loaded
                  ? (value) => _togglePrayerReminder(option.key, value)
                  : null,
              activeThumbColor: _settingsGold,
            ),
          )),
          const Divider(color: Color(0x334A7562)),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('تنبيه قبل الأذان'),
              subtitle: Text(
                'يرسل إشعاراً عادياً قبل وقت الصلاة؛ لا يشغّل تسجيل الأذان مبكراً.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontSize: 12),
              ),
              value: _earlyAlertEnabled,
              onChanged: _loaded ? _toggleEarlyAlert : null,
              activeThumbColor: _settingsGold,
            ),
          ),
          DropdownButtonFormField<int>(
            key: const ValueKey('prayer_early_alert_minutes'),
            initialValue: _earlyAlertMinutes,
            decoration: const InputDecoration(
              labelText: 'كم دقيقة قبل الصلاة؟',
              border: OutlineInputBorder(),
            ),
            items: [5, 10, 15, 20, 30]
                .map((minutes) => DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes دقائق'),
                    ))
                .toList(),
            onChanged: _loaded ? _changeEarlyAlertMinutes : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _toggleAdhanPlayback : null,
              icon: Icon(_isPlayingAdhan ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded),
              label: Text(_isPlayingAdhan ? 'إيقاف التسجيل الصوتي' : 'استماع إلى تسجيل الأذان'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _testNotification : null,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text('تجربة إشعار الأذان'),
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _checkNotificationSchedule : null,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text('فحص جدولة الأذان'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _openExactAlarmSettings : null,
              icon: const Icon(Icons.alarm_on_rounded),
              label: const Text('فتح إذن المنبهات والتذكيرات الدقيقة'),
            ),
          ),
          Text('التسجيل المضمّن هو الأذان الذي اختاره صاحب التطبيق: الأذان من العتبة العلوية المقدسة بصوت القارئ الشيخ شبّر معلة.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5)),
          const SizedBox(height: 4),
          Text('يلزم السماح بإشعارات التطبيق من أندرويد. إذا وصل الإشعار بلا صوت، ارفع صوت التنبيهات وافحص إعداد قناة «أذان الصلاة».', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mobile_friendly_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'حتى يوصل الأذان والتطبيق مغلق',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '١. اسمح بإشعارات ميثاق المؤمن. ٢. فعّل «المنبهات والتذكيرات» الدقيقة إذا ظهر الخيار. ٣. اجعل استخدام البطارية للتطبيق «غير مقيّد» أو اسمح بالنشاط بالخلفية.',
                  style: TextStyle(height: 1.65, fontSize: 12),
                ),
                const SizedBox(height: 6),
                const Text(
                  'على بعض أجهزة TECNO وHiOS: افتح Phone Master أو Battery Lab واسمح بالتشغيل التلقائي والخلفي، واستثنِ التطبيق من توفير الطاقة، وثبّته في التطبيقات الأخيرة إذا توفر الخيار. تختلف أسماء القوائم حسب إصدار الجهاز.',
                  style: TextStyle(height: 1.65, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'فحص الجدولة يؤكد أن النظام يحتفظ بالمواعيد، لكنه لا يضمن وحده وصول الصوت إذا كان النظام يقيّد التطبيق.',
                  style: TextStyle(
                    height: 1.55,
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),


            ],
          ),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.menu_book_outlined,
        title: 'قراءة القرآن',
        children: [
          Text('حجم خط الآيات: ${_fontSize.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(value: _fontSize, min: 16, max: 34, divisions: 9, label: _fontSize.round().toString(), activeColor: _settingsGold, onChanged: _loaded ? _saveFontSize : null),
          Text('مثال على شكل الخط', textDirection: TextDirection.rtl, style: TextStyle(fontSize: _fontSize, height: 1.8, color: _settingsGold)),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.verified_outlined,
        title: 'المصادر والمحتوى',
        children: [
          Text('نص القرآن العثماني: مشروع Tanzil Project عبر dotquran/corpus. فهرس السور مضمّن محلياً.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
          SizedBox(height: 8),
          Text('تعرض مكتبة الأدعية اسم سجل البيانات ورابطه عند توفرهما؛ وهذا لا يغني عن توثيق الكتاب الأصلي أو تخريج الرواية. الصيغ العامة لا تُعرض على أنها روايات مسندة.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
          SizedBox(height: 8),
          Text('مواقيت الصلاة والتاريخ الهجري تقديرية حالياً، وقد تختلف باختلاف الموقع وثبوت الهلال والرأي الفقهي.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.phonelink_lock_outlined,
        title: 'الخصوصية',
        children: [
          Text('التقدّم والخيارات تُحفظ محلياً على الجهاز. لا يتطلب التطبيق حساباً ولا يرسل سجلّ عبادتك إلى خادم.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
        ],
      ),
      const SizedBox(height: 14),
      Center(child: Text('ميثاق المؤمن • إصدار التطوير 0.2.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11))),
    ]);
  }

  Widget _themeOption({required bool dark, required bool selected}) {
    final isDarkOption = dark;
    final background = isDarkOption
        ? const Color(0xFF071713)
        : const Color(0xFFF7F5EF);
    final surface = isDarkOption
        ? const Color(0xFF10251E)
        : const Color(0xFFFFFFFF);
    final foreground = isDarkOption
        ? const Color(0xFFF5F4EC)
        : const Color(0xFF18352B);
    final accent = isDarkOption
        ? const Color(0xFFD9B66D)
        : const Color(0xFF79551F);
    final border = selected
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.outlineVariant;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () async {
          try {
            await AppTheme.setDark(isDarkOption);
          } catch (_) {
            if (mounted) {
              _message('تغيّر المظهر لكن تعذّر حفظ الاختيار على الجهاز');
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: border.withValues(alpha: selected ? .95 : .45),
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: accent.withValues(alpha: .38)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDarkOption
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: accent,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    ...[
                      const Color(0xFF267A58),
                      const Color(0xFFD9B66D),
                      const Color(0xFF8AA99B),
                    ].map(
                      (color) => Container(
                        width: 9,
                        height: 20,
                        margin: const EdgeInsetsDirectional.only(end: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isDarkOption ? 'داكن' : 'فاتح',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? accent : foreground.withValues(alpha: .42),
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                isDarkOption ? 'زمردي وفحمي وذهبي' : 'عاجي وأخضر ولمسات ذهبية',
                maxLines: 2,
                style: TextStyle(
                  color: foreground.withValues(alpha: .72),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({required IconData icon, required String title, required List<Widget> children}) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 1,
    shadowColor: Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: .10)
        : const Color(0xFF30483D).withValues(alpha: .05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: .18)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _settingsGold.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _settingsGold, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.4),
        )),
      ]),
      const SizedBox(height: 14),
      Divider(height: 1, color: _settingsGold.withValues(alpha: .10)),
      const SizedBox(height: 14),
      ...children,
    ]),
    ),
  );
}
