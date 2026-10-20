import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_locations.dart';
import '../services/prayer_notification_service.dart';

const _settingsPanel = Color(0xFF10251E);
const _settingsGold = Color(0xFFD9B66D);
const _settingsMuted = Color(0xFF9EB5A9);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _cityId = PrayerLocations.cities.first.id;
  PrayerCity _currentCity = PrayerLocations.cities.first;
  double _fontSize = 24;
  bool _loaded = false;
  bool _notificationsEnabled = false;
  bool _gpsBusy = false;

  @override void initState() { super.initState(); _load(); }
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
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _saveCity(String? id) async {
    if (id == null || id == 'current_location') return;
    setState(() { _cityId = id; _currentCity = PrayerLocations.byId(id); });
    try {
      await PrayerLocations.save(id);
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
    final ok = await PrayerNotificationService.configure(
      enabled: true,
      city: _currentCity,
    );
    if (!mounted) return;
    setState(() => _notificationsEnabled = ok);
    _message(ok
      ? 'تم تفعيل تذكيرات الصلاة للأيام القادمة'
      : 'تعذّر التفعيل. تحقق من إذن الإشعارات في إعدادات الجهاز.');
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
              subtitle: const Text('تذكيرات محلية للأيام الـ12 القادمة مع صوت الأذان. المواقيت الحسابية تقديرية، وقد تتأخر الإشعارات بسبب إعدادات توفير الطاقة.', style: TextStyle(color: _settingsMuted, height: 1.5, fontSize: 12)),
              value: _notificationsEnabled,
              onChanged: _loaded ? _toggleNotifications : null,
              activeThumbColor: _settingsGold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loaded ? _testNotification : null,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('تجربة الإشعار وصوت الأذان'),
            ),
          ),
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
