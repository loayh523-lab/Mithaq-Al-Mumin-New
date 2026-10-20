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
  const PrayerCalendarPage({super.key});
  @override State<PrayerCalendarPage> createState() => _PrayerCalendarPageState();
}

class _PrayerCalendarPageState extends State<PrayerCalendarPage> {
  static const zone = 3.0;
  PrayerCity city = PrayerLocations.cities.first;
  DateTime date = DateTime.now();
  DateTime now = DateTime.now();
  Timer? _clockTimer;
  int correction = 0, tab = 0;
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
    try { final selected = await PrayerLocations.load(); if (mounted) setState(() => city = selected); } catch (_) { /* Keep the default city. */ }
  }
  Future<void> _loadCorrection() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => correction = p.getInt('hijri_correction') ?? 0);
  }
  Future<void> _correct(int delta) async {
    final next = (correction + delta).clamp(-3, 3);
    final p = await SharedPreferences.getInstance(); await p.setInt('hijri_correction', next);
    if (mounted) setState(() => correction = next);
  }
  @override Widget build(BuildContext context) {
    final hijri = _Hijri.fromGregorian(date.add(Duration(days: correction)));
    final times = SolarPrayerTimes.forDate(date, city.latitude, city.longitude, zone);
    return Scaffold(appBar: AppBar(title: const Text('المواقيت والتقويم')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: _gold.withValues(alpha: .3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('التاريخ الهجري التقريبي', style: TextStyle(color: _muted)), const SizedBox(height: 8),
        Text('${hijri.day} ${hijri.monthName} ${hijri.year} هـ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _gold)),
        const SizedBox(height: 6), Text(_dateLabel(date), style: const TextStyle(color: _muted)),
        Row(children: [const Expanded(child: Text('تصحيح يدوي للتاريخ')), IconButton(onPressed: () => _correct(-1), icon: const Icon(Icons.remove_circle_outline)), Text('$correction يوم'), IconButton(onPressed: () => _correct(1), icon: const Icon(Icons.add_circle_outline))]),
        const Text('الحساب الهجري جدولي تقريبي وقد يختلف عن ثبوت الهلال الشرعي. التصحيح محفوظ على الجهاز.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
      ])),
      if (_occasion(hijri) != null) Card(color: _panel, child: ListTile(leading: const Icon(Icons.event, color: _gold), title: const Text('مناسبة دينية'), subtitle: Text(_occasion(hijri)!, style: const TextStyle(height: 1.5)))),
      const SizedBox(height: 14),
      SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('مواقيت الصلاة'), icon: Icon(Icons.access_time)), ButtonSegment(value: 1, label: Text('إمساكية رمضان'), icon: Icon(Icons.nights_stay_outlined))], selected: {tab}, onSelectionChanged: (v) => setState(() => tab = v.first)),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        Row(children: [Expanded(child: Text('مواقيت ${_dateLabel(date)}', style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: () => setState(() => date = date.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)), IconButton(onPressed: () => setState(() => date = date.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)), IconButton(onPressed: () => setState(() => date = DateTime.now()), icon: const Icon(Icons.today))]),
        if (_sameDay(date, now)) _nextPrayerCard(times, now),
        _time(Icons.wb_twilight, 'الفجر (تقديري)', times.fajr), _time(Icons.wb_sunny_outlined, 'الشروق', times.sunrise), _time(Icons.sunny, 'الظهر', times.noon), _time(Icons.wb_sunny_rounded, 'العصر (تقديري)', times.asr), _time(Icons.wb_twilight, 'الغروب', times.sunset), _time(Icons.nights_stay_outlined, 'المغرب (تقديري)', times.maghrib), _time(Icons.dark_mode_outlined, 'العشاء (تقديري)', times.isha),
        const Padding(padding: EdgeInsets.all(8), child: Text('الحساب الفلكي هنا تقديري: زاوية الفجر 16° والمغرب 4° بعد انخفاض الشمس. لا تعتمد عليه وحده للعبادة؛ قارن بمواقيت مكتب مرجعك في منطقتك. لا توجد حالياً تنبيهات أذان أو تحديد موقع تلقائي.', style: TextStyle(color: _muted, fontSize: 11, height: 1.6))),
      ] else ...[
        Text('إمساكية تقديرية — ${city.name} / العراق', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5),
        const Text('يعرض الجدول 30 يوماً من التاريخ المختار. الفجر والغروب محسوبان فلكياً ولا يمثلان إمساكية رسمية لشهر رمضان محدد.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
        ..._ramadanRows(date, city.latitude, city.longitude),
      ],
      const Divider(), const Text('الموقع الحالي للحساب', style: TextStyle(fontWeight: FontWeight.bold)), Text('${city.name}، العراق — إحداثيات تقريبية', style: const TextStyle(color: _muted)),
    ]));
  }
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

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
          Text('الوقت المحسوب: ${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: _muted, fontSize: 12)),
        ])),
        Text(
          hours > 0 ? '$hoursس $minutesد' : '$minutes دقيقة',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ]),
    );
  }

  Widget _time(IconData icon, String label, String time) => Card(color: _panel, child: ListTile(leading: Icon(icon, color: _gold), title: Text(label), trailing: Text(time, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))));
}

String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
    final a = (14 - d.month) ~/ 12, y = d.year + 4800 - a, m = d.month + 12*a - 3;
    final jd = d.day + (153*m + 2) ~/ 5 + 365*y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
    final hy = ((30 * (jd - 1948439) + 10646) / 10631).floor();
    int start(int year, int month) => 1 + (29.5 * (month - 1)).ceil() + (year - 1) * 354 + ((3 + 11 * year) ~/ 30) + 1948439 - 1;
    var hm = 1; while (hm < 12 && jd >= start(hy, hm + 1)) { hm++; }
    return _Hijri(jd - start(hy, hm) + 1, hm, hy);
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
