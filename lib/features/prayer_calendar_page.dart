import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_locations.dart';

const _panel = Color(0xFF10251E);
const _gold = Color(0xFFD9B66D);
const _muted = Color(0xFF9EB5A9);

/// Approximate solar times for Qal'at Sukar using a configurable Jafari-style estimate.
/// Local religious authority timetables take precedence.
class PrayerCalendarPage extends StatefulWidget {
  const PrayerCalendarPage({super.key, this.onLocationChanged, this.onHijriCorrectionChanged});
  final Future<void> Function()? onLocationChanged;
  final Future<void> Function()? onHijriCorrectionChanged;
  @override State<PrayerCalendarPage> createState() => _PrayerCalendarPageState();
}

class _PrayerCalendarPageState extends State<PrayerCalendarPage> {
  static const zone = 3.0;
  PrayerCity city = PrayerLocations.cities.first;
  DateTime date = DateTime.now();
  DateTime now = DateTime.now();
  Timer? _clockTimer;
  int correction = 0, tab = 0;
  bool _gpsBusy = false;
  double? _gpsAccuracy;
  String? _locationMessage;
  @override void initState() {
    super.initState();
    _loadCorrection();
    _loadCity();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }
  @override void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
  Future<void> _loadCity() async {
    try {
      final selected = await PrayerLocations.load();
      if (!mounted) return;
      setState(() => city = selected);
      if (selected.id == 'current_location') {
        _gpsAccuracy = await PrayerLocations.currentLocationAccuracy();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _refreshLocation() async {
    setState(() { _gpsBusy = true; _locationMessage = null; });
    final precise = await PrayerLocations.acquirePreciseLocation();
    if (!mounted) return;
    if (precise == null) {
      setState(() => _locationMessage = 'تعذّر تحديد GPS. فعّل الموقع واسمح للتطبيق بالوصول إليه.');
    } else {
      final accuracy = await PrayerLocations.currentLocationAccuracy();
      if (!mounted) return;
      setState(() {
        city = precise;
        _gpsAccuracy = accuracy;
        _locationMessage = accuracy == null ? 'تم تحديث الموقع بواسطة GPS.' : 'دقة الموقع المعلنة من الجهاز نحو ${accuracy.round()} متر.';
      });
      await widget.onLocationChanged?.call();
    }
    if (mounted) setState(() => _gpsBusy = false);
  }
  Future<void> _loadCorrection() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => correction = p.getInt('hijri_correction') ?? 0);
  }
  Future<void> _correct(int delta) async {
    final next = (correction + delta).clamp(-3, 3);
    final p = await SharedPreferences.getInstance();
    await p.setInt('hijri_correction', next);
    if (mounted) setState(() => correction = next);
    await widget.onHijriCorrectionChanged?.call();
  }
  @override Widget build(BuildContext context) {
    final hijri = _Hijri.fromGregorian(date.add(Duration(days: correction)));
    final times = SolarPrayerTimes.forDate(date, city.latitude, city.longitude, zone);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواقيت والتقويم'),
        actions: [
          IconButton(
            tooltip: 'تحديث الموقع من GPS',
            onPressed: _gpsBusy ? null : _refreshLocation,
            icon: _gpsBusy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: _gold.withValues(alpha: .3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('التاريخ الهجري التقريبي', style: TextStyle(color: _muted)), const SizedBox(height: 8),
        Text('${hijri.day} ${hijri.monthName} ${hijri.year} هـ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _gold)),
        const SizedBox(height: 6), Text(_dateLabel(date), style: const TextStyle(color: _muted)),
        Row(children: [const Expanded(child: Text('تصحيح يدوي للتاريخ')), IconButton(onPressed: () => _correct(-1), icon: const Icon(Icons.remove_circle_outline)), Text('$correction يوم'), IconButton(onPressed: () => _correct(1), icon: const Icon(Icons.add_circle_outline))]),
        const Text('التاريخ محسوب بالتقويم الهجري الجدولي وقد يختلف يوماً عن إعلان ثبوت الهلال في العراق. يمكنك ضبطه إذا اعتمد مكتب مرجعك تاريخاً مختلفاً.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
      ])),
      if (_occasion(hijri) != null) Card(color: _panel, child: ListTile(leading: const Icon(Icons.event, color: _gold), title: const Text('مناسبة دينية'), subtitle: Text(_occasion(hijri)!, style: const TextStyle(height: 1.5)))),
      const SizedBox(height: 14),
      SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('مواقيت الصلاة'), icon: Icon(Icons.access_time)), ButtonSegment(value: 1, label: Text('إمساكية رمضان'), icon: Icon(Icons.nights_stay_outlined)), ButtonSegment(value: 2, label: Text('التقويم السنوي'), icon: Icon(Icons.calendar_month_rounded))], selected: {tab}, onSelectionChanged: (v) => setState(() => tab = v.first)),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        Row(children: [Expanded(child: Text('مواقيت ${_dateLabel(date)}', style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: () => setState(() => date = date.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)), IconButton(onPressed: () => setState(() => date = date.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)), IconButton(onPressed: () => setState(() => date = DateTime.now()), icon: const Icon(Icons.today))]),
        if (_sameDay(date, now)) _nextPrayerCard(times, now),
        _time(Icons.wb_twilight, 'الفجر (تقديري)', times.fajr), _time(Icons.wb_sunny_outlined, 'الشروق', times.sunrise), _time(Icons.sunny, 'الظهر', times.noon), _time(Icons.wb_sunny_rounded, 'العصر (تقديري)', times.asr), _time(Icons.wb_twilight, 'الغروب', times.sunset), _time(Icons.nights_stay_outlined, 'المغرب (تقديري)', times.maghrib), _time(Icons.dark_mode_outlined, 'العشاء (تقديري)', times.isha),
        const Padding(padding: EdgeInsets.all(8), child: Text('الحساب المحلي احتياطي تقريبي، وليس بديلاً عن جدول شرعي معتمد من مكتب مرجعك. استخدم زر GPS لتحديث الإحداثيات وفعّل تنبيهات الصلاة من الإعدادات.', style: TextStyle(color: _muted, fontSize: 11, height: 1.6))),
      ] else if (tab == 1) ...[
        Text('إمساكية تقديرية — ${city.name} / العراق', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5),
        const Text('يعرض الشهر كاملاً من اليوم الأول إلى آخر يوم من رمضان المحسوب تقويمياً. الأوقات فلكية تقديرية وليست بديلاً عن إمساكية مكتب مرجعك أو الجهة المحلية المعتمدة.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
        ..._ramadanRows(date, city.latitude, city.longitude),
      ] else ..._annualCalendar(date.year, correction),
      const Divider(),
      const Text('الموقع الحالي للحساب', style: TextStyle(fontWeight: FontWeight.bold)),
      Text(
        '${city.name} — ${city.id == 'current_location' ? 'موقع GPS من الجهاز' : 'إحداثيات المدينة التقريبية'}${_gpsAccuracy == null ? '' : ' (دقة نحو ${_gpsAccuracy!.round()} متر)'}',
        style: const TextStyle(color: _muted),
      ),
      if (_locationMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_locationMessage!, style: const TextStyle(color: _gold)),
        ),
    ]));
  }
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeAnnualYear(int delta) {
    final year = date.year + delta;
    final maxDay = DateUtils.getDaysInMonth(year, date.month);
    setState(() => date = DateTime(year, date.month, date.day.clamp(1, maxDay).toInt()));
  }

  List<Widget> _annualCalendar(int year, int correction) {
    final widgets = <Widget>[
      Card(
        color: _panel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(children: [
            IconButton(tooltip: 'السنة السابقة', onPressed: () => _changeAnnualYear(-1), icon: const Icon(Icons.chevron_right_rounded, color: _gold)),
            Expanded(child: Text('التقويم السنوي $year', textAlign: TextAlign.center, style: const TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 18))),
            IconButton(tooltip: 'السنة التالية', onPressed: () => _changeAnnualYear(1), icon: const Icon(Icons.chevron_left_rounded, color: _gold)),
          ]),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text('افتح أي شهر لتشاهد كل أيامه بالتاريخين الميلادي والهجري والمناسبات المسجلة. التاريخ الهجري حسابي تقريبي؛ قد يختلف عن إعلان ثبوت الهلال.', style: TextStyle(color: _muted, height: 1.6, fontSize: 12)),
      ),
    ];
    for (var month = 1; month <= 12; month++) {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      widgets.add(Card(
        color: _panel,
        child: ExpansionTile(
          leading: const Icon(Icons.calendar_month_rounded, color: _gold),
          title: Text(_gregorianMonthName(month), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$daysInMonth يوماً'),
          children: List<Widget>.generate(daysInMonth, (index) {
            final day = index + 1;
            final gregorian = DateTime(year, month, day);
            final hijri = _Hijri.fromGregorian(gregorian.add(Duration(days: correction)));
            final occasion = _occasion(hijri);
            final hijriLabel = '${hijri.day} ${hijri.monthName} ${hijri.year} هـ';
            return ListTile(
              dense: true,
              leading: SizedBox(width: 30, child: Text('$day', textAlign: TextAlign.center, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold))),
              title: Text('$day ${_gregorianMonthName(month)} $year م'),
              subtitle: Text(occasion == null ? hijriLabel : '$hijriLabel\n$occasion', style: const TextStyle(color: _muted, height: 1.5)),
              isThreeLine: occasion != null,
              trailing: occasion == null ? null : const Icon(Icons.event_available_rounded, color: _gold, size: 18),
              onTap: () => setState(() { date = gregorian; tab = 0; }),
            );
          }),
        ),
      ));
    }
    return widgets;
  }

  Widget _nextPrayerCard(SolarPrayerTimes times, DateTime clock) {
    final prayers = <({String name, String time})>[
      (name: 'الفجر', time: times.fajr),
      (name: 'الظهر', time: times.noon),
      (name: 'العصر', time: times.asr),
      (name: 'المغرب', time: times.maghrib),
      (name: 'العشاء', time: times.isha),
    ];
    DateTime? nextTime;
    String nextName = '';
    for (final prayer in prayers) {
      final parts = prayer.time.split(':');
      if (parts.length != 2) continue;
      final candidate = DateTime(clock.year, clock.month, clock.day, int.parse(parts[0]), int.parse(parts[1]));
      if (candidate.isAfter(clock)) {
        nextTime = candidate;
        nextName = prayer.name;
        break;
      }
    }
    if (nextTime == null) {
      final tomorrow = DateTime(clock.year, clock.month, clock.day).add(const Duration(days: 1));
      final tomorrowFajr = SolarPrayerTimes.forDate(tomorrow, city.latitude, city.longitude, zone).fajr.split(':');
      if (tomorrowFajr.length == 2) {
        nextTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, int.parse(tomorrowFajr[0]), int.parse(tomorrowFajr[1]));
        nextName = 'الفجر';
      }
    }
    if (nextTime == null) return const SizedBox.shrink();
    final nextTimeText = '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';
    final remaining = nextTime.difference(clock);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16372B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: .35)),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_bottom_rounded, color: _gold, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الصلاة القادمة: $nextName', style: const TextStyle(fontWeight: FontWeight.bold, color: _gold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('الوقت المحسوب: ${formatPrayerTime12Hour(nextTimeText)}', style: const TextStyle(color: _muted, fontSize: 12)),
        ])),
        Text(
          hours > 0 ? '$hoursس $minutesد' : '$minutes دقيقة',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ]),
    );
  }

  Widget _time(IconData icon, String label, String time) => Card(color: _panel, child: ListTile(leading: Icon(icon, color: _gold), title: Text(label), trailing: Text(formatPrayerTime12Hour(time), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))));
}

String hijriDateLabel(DateTime date, {int correction = 0}) {
  final hijri = _Hijri.fromGregorian(date.add(Duration(days: correction)));
  return '${hijri.day} ${hijri.monthName} ${hijri.year} هـ';
}

String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _gregorianMonthName(int month) => const [
  'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
][month - 1];

String formatPrayerTime12Hour(String value) {
  final match = RegExp(r'^(\\d{1,2}):(\\d{2})

class SolarPrayerTimes {
  const SolarPrayerTimes(this.fajr, this.sunrise, this.noon, this.asr, this.sunset, this.maghrib, this.isha);
  final String fajr, sunrise, noon, asr, sunset, maghrib, isha;

  static SolarPrayerTimes forDate(DateTime date, double lat, double lon, double zone) {
    final n = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final g = 2 * math.pi / 365 * (n - 1);
    final eq = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g) - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g));
    final dec = 0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g) + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g);
    final noon = 720 - 4 * lon - eq + zone * 60;
    double hourAngle(double altitude) {
      const rad = math.pi / 180;
      final cosine = ((math.sin(altitude * rad) - math.sin(lat * rad) * math.sin(dec)) / (math.cos(lat * rad) * math.cos(dec))).clamp(-1.0, 1.0);
      return math.acos(cosine) / rad;
    }
    final rise = noon - 4 * hourAngle(-0.833);
    final set = noon + 4 * hourAngle(-0.833);
    final asrAltitude = math.atan(1 / (1 + math.tan((lat * math.pi / 180 - dec).abs()))) * 180 / math.pi;
    return SolarPrayerTimes(
      _fmt(noon - 4 * hourAngle(-16)),
      _fmt(rise),
      _fmt(noon),
      _fmt(noon + 4 * hourAngle(asrAltitude)),
      _fmt(set),
      _fmt(noon + 4 * hourAngle(-4)),
      _fmt(noon + 4 * hourAngle(-14)),
    );
  }

  static String _fmt(double value) {
    final minute = value.round().clamp(0, 2879) % 1440;
    return '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  }
}

class _Hijri {
  const _Hijri(this.day, this.month, this.year);
  final int day, month, year;
  String get monthName => const ['محرم','صفر','ربيع الأول','ربيع الآخر','جمادى الأولى','جمادى الآخرة','رجب','شعبان','رمضان','شوال','ذو القعدة','ذو الحجة'][month - 1];
  factory _Hijri.fromGregorian(DateTime d) {
    // Standard tabular Islamic civil-calendar conversion (integer arithmetic).
    // The result is an estimate; local moon-sighting announcements can differ by one day.
    final a = (14 - d.month) ~/ 12;
    final y = d.year + 4800 - a;
    final m = d.month + 12 * a - 3;
    final jd = d.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return _Hijri(day, month, year);
  }
}

List<Widget> _ramadanRows(DateTime reference, double latitude, double longitude) {
  final current = _Hijri.fromGregorian(reference);
  final targetYear = current.month > 9 ? current.year + 1 : current.year;
  DateTime? start;
  final scanStart = DateTime(reference.year - 1, 1, 1);
  for (var i = 0; i < 800; i++) {
    final candidate = scanStart.add(Duration(days: i));
    final h = _Hijri.fromGregorian(candidate);
    if (h.year == targetYear && h.month == 9 && h.day == 1) { start = candidate; break; }
  }
  // If conversion does not find the target, keep a clearly approximate 30-day table.
  final first = start ?? DateTime(reference.year, reference.month, reference.day);
  return List.generate(30, (i) {
    final d = first.add(Duration(days: i));
    final t = SolarPrayerTimes.forDate(d, latitude, longitude, 3.0);
    final h = _Hijri.fromGregorian(d);
    return Card(color: _panel, child: ListTile(dense: true, leading: CircleAvatar(backgroundColor: _gold.withValues(alpha: .15), child: Text('${i + 1}', style: const TextStyle(color: _gold))), title: Text('رمضان ${h.day} — ${_dateLabel(d)}'), subtitle: Text('الإمساك/الفجر: ${formatPrayerTime12Hour(t.fajr)}  •  الإفطار التقريبي: ${formatPrayerTime12Hour(t.maghrib)}')));
  });
}

String? _occasion(_Hijri h) {
  const events = <String, String>{
    '1-1': 'بداية السنة الهجرية',
    '10-1': 'يوم عاشوراء — ذكرى استشهاد الإمام الحسين عليه السلام',
    '20-2': 'زيارة الأربعين للإمام الحسين عليه السلام',
    '17-3': 'ذكرى مولد النبي محمد صلى الله عليه وآله (المشهور عند كثير من الشيعة)',
    '13-7': 'ذكرى ولادة أمير المؤمنين الإمام علي عليه السلام',
    '3-8': 'ذكرى ولادة الإمام الحسين عليه السلام',
    '15-8': 'ذكرى ولادة الإمام المهدي عجل الله فرجه',
    '21-9': 'ذكرى استشهاد الإمام علي عليه السلام',
    '25-10': 'ذكرى استشهاد الإمام جعفر الصادق عليه السلام',
    '9-1': 'تاسوعاء — من أيام الحزن على الإمام الحسين عليه السلام',
    '4-8': 'ذكرى ولادة أبي الفضل العباس عليه السلام (المشهور)',
    '25-7': 'ذكرى استشهاد الإمام موسى الكاظم عليه السلام (المشهور)',
    '29-2': 'ذكرى استشهاد الإمام علي بن موسى الرضا عليه السلام (المشهور)',
  };
  return events['${h.day}-${h.month}'];
}
).firstMatch(value.trim());
  if (match == null) return value;
  final hour = int.tryParse(match.group(1)!) ?? -1;
  final minute = int.tryParse(match.group(2)!) ?? -1;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return value;
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'ص' : 'م';
  return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
}

class SolarPrayerTimes {
  const SolarPrayerTimes(this.fajr, this.sunrise, this.noon, this.asr, this.sunset, this.maghrib, this.isha);
  final String fajr, sunrise, noon, asr, sunset, maghrib, isha;

  static SolarPrayerTimes forDate(DateTime date, double lat, double lon, double zone) {
    final n = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final g = 2 * math.pi / 365 * (n - 1);
    final eq = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g) - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g));
    final dec = 0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g) + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g);
    final noon = 720 - 4 * lon - eq + zone * 60;
    double hourAngle(double altitude) {
      const rad = math.pi / 180;
      final cosine = ((math.sin(altitude * rad) - math.sin(lat * rad) * math.sin(dec)) / (math.cos(lat * rad) * math.cos(dec))).clamp(-1.0, 1.0);
      return math.acos(cosine) / rad;
    }
    final rise = noon - 4 * hourAngle(-0.833);
    final set = noon + 4 * hourAngle(-0.833);
    final asrAltitude = math.atan(1 / (1 + math.tan((lat * math.pi / 180 - dec).abs()))) * 180 / math.pi;
    return SolarPrayerTimes(
      _fmt(noon - 4 * hourAngle(-16)),
      _fmt(rise),
      _fmt(noon),
      _fmt(noon + 4 * hourAngle(asrAltitude)),
      _fmt(set),
      _fmt(noon + 4 * hourAngle(-4)),
      _fmt(noon + 4 * hourAngle(-14)),
    );
  }

  static String _fmt(double value) {
    final minute = value.round().clamp(0, 2879) % 1440;
    return '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  }
}

class _Hijri {
  const _Hijri(this.day, this.month, this.year);
  final int day, month, year;
  String get monthName => const ['محرم','صفر','ربيع الأول','ربيع الآخر','جمادى الأولى','جمادى الآخرة','رجب','شعبان','رمضان','شوال','ذو القعدة','ذو الحجة'][month - 1];
  factory _Hijri.fromGregorian(DateTime d) {
    // Standard tabular Islamic civil-calendar conversion (integer arithmetic).
    // The result is an estimate; local moon-sighting announcements can differ by one day.
    final a = (14 - d.month) ~/ 12;
    final y = d.year + 4800 - a;
    final m = d.month + 12 * a - 3;
    final jd = d.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return _Hijri(day, month, year);
  }
}

List<Widget> _ramadanRows(DateTime reference, double latitude, double longitude) {
  final current = _Hijri.fromGregorian(reference);
  final targetYear = current.month > 9 ? current.year + 1 : current.year;
  DateTime? start;
  final scanStart = DateTime(reference.year - 1, 1, 1);
  for (var i = 0; i < 800; i++) {
    final candidate = scanStart.add(Duration(days: i));
    final h = _Hijri.fromGregorian(candidate);
    if (h.year == targetYear && h.month == 9 && h.day == 1) { start = candidate; break; }
  }
  // If conversion does not find the target, keep a clearly approximate 30-day table.
  final first = start ?? DateTime(reference.year, reference.month, reference.day);
  return List.generate(30, (i) {
    final d = first.add(Duration(days: i));
    final t = SolarPrayerTimes.forDate(d, latitude, longitude, 3.0);
    final h = _Hijri.fromGregorian(d);
    return Card(color: _panel, child: ListTile(dense: true, leading: CircleAvatar(backgroundColor: _gold.withValues(alpha: .15), child: Text('${i + 1}', style: const TextStyle(color: _gold))), title: Text('رمضان ${h.day} — ${_dateLabel(d)}'), subtitle: Text('الإمساك/الفجر: ${t.fajr}  •  الإفطار التقريبي: ${t.maghrib}')));
  });
}

String? _occasion(_Hijri h) {
  const events = <String, String>{
    '1-1': 'بداية السنة الهجرية',
    '10-1': 'يوم عاشوراء — ذكرى استشهاد الإمام الحسين عليه السلام',
    '20-2': 'زيارة الأربعين للإمام الحسين عليه السلام',
    '17-3': 'ذكرى مولد النبي محمد صلى الله عليه وآله (المشهور عند كثير من الشيعة)',
    '13-7': 'ذكرى ولادة أمير المؤمنين الإمام علي عليه السلام',
    '3-8': 'ذكرى ولادة الإمام الحسين عليه السلام',
    '15-8': 'ذكرى ولادة الإمام المهدي عجل الله فرجه',
    '21-9': 'ذكرى استشهاد الإمام علي عليه السلام',
    '25-10': 'ذكرى استشهاد الإمام جعفر الصادق عليه السلام',
  };
  return events['${h.day}-${h.month}'];
}
