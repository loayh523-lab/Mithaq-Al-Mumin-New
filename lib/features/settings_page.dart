import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_locations.dart';
import '../services/prayer_notification_service.dart';

const _settingsPanel = Color(0xFF10251E);
const _settingsGold = Color(0xFFD9B66D);
const _settingsMuted = Color(0xFF9EB5A9);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onLocationChanged});
  final Future<void> Function()? onLocationChanged;
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _cityId = PrayerLocations.cities.first.id;
  PrayerCity _currentCity = PrayerLocations.cities.first;
  double _fontSize = 24;
  bool _loaded = false;
  bool _notificationsEnabled = false;
  bool _gpsBusy = false;
  final AudioPlayer _adhanPlayer = AudioPlayer();
  bool _adhanPlaying = false;
  late final StreamSubscription<void> _adhanCompleteSubscription;
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

  @override
  void initState() {
    super.initState();
    _adhanCompleteSubscription = _adhanPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _adhanPlaying = false);
    });
    _load();
  }

  @override
  void dispose() {
    unawaited(_adhanCompleteSubscription.cancel());
    unawaited(_adhanPlayer.dispose());
    super.dispose();
  }

  Future<void> _toggleAdhanPreview() async {
    try {
      if (_adhanPlaying) {
        await _adhanPlayer.pause();
        if (mounted) setState(() => _adhanPlaying = false);
        return;
      }
      await _adhanPlayer.stop();
      await _adhanPlayer.play(
        AssetSource('audio/adhan_shabbar_maalla.mp3'),
      );
      if (mounted) setState(() => _adhanPlaying = true);
    } catch (_) {
      if (mounted) {
        _message('تعذّر تشغيل تسجيل الأذان. أغلق الصفحة وافتحها ثم جرّب مرة ثانية.');
      }
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCity = await PrayerLocations.load();
      if (!mounted) return;
      setState(() {
        _currentCity = savedCity;
        _cityId = savedCity.id;
        _fontSize = (prefs.getDouble('quran_font_size') ?? 24).clamp(16, 34).toDouble();
        _notificationsEnabled = prefs.getBool('prayer_notifications_enabled') ?? false;
        _earlyAlertEnabled = prefs.getBool('prayer_early_alert_enabled') ?? false;
        _earlyAlertMinutes =
            (prefs.getInt('prayer_early_alert_minutes') ?? 5).clamp(1, 30).toInt();
        _prayerEnabled = {
          for (final option in _prayerOptions)
            option.key: prefs.getBool('prayer_enabled_${option.key}') ?? true,
        };
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _saveCity(String? id) async {
    if (id == null) return;
    if (id == 'current_location') {
      await _useCurrentLocation();
      return;
    }
    setState(() { _cityId = id; _currentCity = PrayerLocations.byId(id); });
    try {
      await PrayerLocations.save(id);
      await widget.onLocationChanged?.call();
      if (_notificationsEnabled) {
        final ok = await PrayerNotificationService.configure(enabled: true, city: PrayerLocations.byId(id));
        if (!ok && mounted) _message('تم حفظ المدينة لكن تعذّر تحديث التذكيرات. افتح إعدادات الإشعارات وتحقق من الإذن.');
      }
      if (mounted) _message('تم حفظ المدينة للمواقيت والقبلة');
    } catch (_) {
      if (mounted) _message('تعذّر حفظ المدينة على الجهاز');
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsBusy = true);
    try {
      final city = await PrayerLocations.acquirePreciseLocation();
      if (!mounted) return;
      if (city == null) {
        _message('ما حصلنا GPS بدقة كافية. فعّل الموقع واسمح للتطبيق بالموقع، ثم جرّب مجدداً.');
        return;
      }
      setState(() { _currentCity = city; _cityId = city.id; });
      await widget.onLocationChanged?.call();
      if (_notificationsEnabled) {
        final ok = await PrayerNotificationService.configure(enabled: true, city: city);
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

  Future<void> _testNotification() async {
    final ok = await PrayerNotificationService.showTestNotification();
    if (!mounted) return;
    _message(ok
      ? 'أرسلنا الإشعار التجريبي. إذا لم يظهر، افحص إذن الإشعارات وإعدادات قناة أذان الصلاة.'
      : 'فشل الإشعار التجريبي. فعّل إشعارات التطبيق من إعدادات أندرويد ثم جرّب مرة ثانية.');
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (!enabled) {
      await PrayerNotificationService.cancelAll();
      if (mounted) {
        setState(() => _notificationsEnabled = false);
        _message('تم إيقاف تذكيرات الصلاة');
      }
      return;
    }
    if (!_prayerEnabled.values.any((value) => value)) {
      _message('فعّل صلاة واحدة على الأقل قبل تشغيل التذكيرات');
      return;
    }
    final ok = await PrayerNotificationService.configure(
      enabled: true,
      city: _currentCity,
      requestExactPermission: true,
    );
    if (!mounted) return;
    setState(() => _notificationsEnabled = ok);
    _message(ok
      ? 'تمت جدولة تذكيرات الصلوات المختارة للأيام الثلاثين القادمة. إذا لم تسمح بالمنبّهات الدقيقة فقد يتأخر التنبيه.'
      : 'تعذّر جدولة التذكيرات. تأكد من إذن الإشعارات، ثم اسمح بالمنبّهات الدقيقة حتى تصل أقرب للموعد.');
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

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override Widget build(BuildContext context) {
    final city = _currentCity;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 24), children: [
      const Text('الإعدادات', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      const Text('خصّص التطبيق بما يناسبك، وتُحفظ هذه الخيارات على جهازك.', style: TextStyle(color: _settingsMuted, height: 1.6)),
      const SizedBox(height: 18),
      _section(
        icon: Icons.location_on_outlined,
        title: 'المدينة ومواقيت الصلاة',
        children: [
          const Text('اختر أقرب مدينة إليك. الحسابات الفلكية المعروضة تقريبية ويجب مقارنتها بمواقيت مكتب مرجعك.', style: TextStyle(color: _settingsMuted, height: 1.6, fontSize: 12)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_cityId),
            initialValue: _cityId,
            decoration: const InputDecoration(labelText: 'مدينة الحساب', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: 'current_location', child: Text('موقعي الحالي')),
              ...PrayerLocations.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: _loaded ? _saveCity : null,
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
          Text(
            city.id == 'current_location'
                ? 'الموقع الحالي: ${city.latitude.toStringAsFixed(4)}, ${city.longitude.toStringAsFixed(4)} — محفوظ على الجهاز'
                : 'الإحداثيات التقريبية: ${city.latitude.toStringAsFixed(3)}, ${city.longitude.toStringAsFixed(3)}',
            style: const TextStyle(color: _settingsMuted, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.notifications_active_outlined,
        title: 'تذكيرات الصلاة',
        children: [
          Material(
            color: _settingsPanel,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('إشعارات الصلاة'),
              subtitle: const Text('تذكيرات محلية للأيام الثلاثين القادمة وفق حساب فلكي تقديري. تستخدم إشعارات الصلاة تسجيل الشيخ شبّر معلة. يلزم السماح بالمنبّهات الدقيقة حتى لا يُستبدل وقت الصلاة بتنبيه متأخر. وقد تؤثر قيود البطارية في بعض الأجهزة.', style: TextStyle(color: _settingsMuted, height: 1.5, fontSize: 12)),
              value: _notificationsEnabled,
              onChanged: _loaded ? _toggleNotifications : null,
              activeThumbColor: _settingsGold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'تخصيص تنبيهات كل صلاة',
            style: TextStyle(fontWeight: FontWeight.w700, color: _settingsGold),
          ),
          const SizedBox(height: 4),
          ..._prayerOptions.map((option) => Material(
            color: _settingsPanel,
            child: SwitchListTile(
              key: ValueKey('prayer_enabled_${option.key}'),
              contentPadding: EdgeInsets.zero,
              title: Text('أذان ${option.value}'),
              subtitle: Text(
                _prayerEnabled[option.key] == true
                    ? 'الأذان والتذكير مفعّلان'
                    : 'لا يوجد تنبيه لهذه الصلاة',
                style: const TextStyle(color: _settingsMuted, fontSize: 11),
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
            color: _settingsPanel,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تنبيه قبل الأذان'),
              subtitle: const Text(
                'يرسل إشعاراً عادياً قبل وقت الصلاة؛ لا يشغّل تسجيل الأذان مبكراً.',
                style: TextStyle(color: _settingsMuted, height: 1.5, fontSize: 12),
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
              onPressed: _loaded ? _toggleAdhanPreview : null,
              icon: Icon(
                _adhanPlaying
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
              ),
              label: Text(
                _adhanPlaying
                    ? 'إيقاف معاينة الأذان'
                    : 'تشغيل أذان الشيخ شبّر معلة',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _testNotification : null,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('تجربة إشعار الأذان'),
            ),
          ),
          const Text('تُشغّل المعاينة من التسجيل المضمّن داخل التطبيق، ويمكن سماعه من دون اتصال بالإنترنت.', style: TextStyle(color: _settingsMuted, fontSize: 11, height: 1.5)),
          const SizedBox(height: 4),
          const SelectableText('https://www.youtube.com/watch?v=lKK4cOnIitg', style: TextStyle(color: _settingsGold, fontSize: 11)),
          const SizedBox(height: 4),
          const Text('يلزم السماح بإشعارات التطبيق من أندرويد. إذا وصل الإشعار بلا صوت، ارفع صوت التنبيهات وافحص إعداد قناة «أذان الصلاة».', style: TextStyle(color: _settingsMuted, fontSize: 11, height: 1.5)),
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
        children: const [
          Text('نص القرآن العثماني: مشروع Tanzil Project عبر dotquran/corpus. فهرس السور مضمّن محلياً.', style: TextStyle(color: _settingsMuted, height: 1.6)),
          SizedBox(height: 8),
          Text('النصوص الدعائية ستُوسّع مع إظهار اسم الكتاب والباب أو الموضع المتاح؛ لا تُعرض صيغة عامة على أنها رواية مسندة.', style: TextStyle(color: _settingsMuted, height: 1.6)),
          SizedBox(height: 8),
          Text('مواقيت الصلاة والتاريخ الهجري تقديرية حالياً، وقد تختلف باختلاف الموقع وثبوت الهلال والرأي الفقهي.', style: TextStyle(color: _settingsMuted, height: 1.6)),
        ],
      ),
      const SizedBox(height: 14),
      _section(
        icon: Icons.phonelink_lock_outlined,
        title: 'الخصوصية',
        children: const [
          Text('التقدّم والخيارات تُحفظ محلياً على الجهاز. لا يتطلب التطبيق حساباً ولا يرسل سجلّ عبادتك إلى خادم.', style: TextStyle(color: _settingsMuted, height: 1.6)),
        ],
      ),
      const SizedBox(height: 14),
      const Center(child: Text('ميثاق المؤمن • إصدار التطوير 0.1.0', style: TextStyle(color: _settingsMuted, fontSize: 11))),
    ]);
  }

  Widget _section({required IconData icon, required String title, required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _settingsPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .05))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: _settingsGold), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}
