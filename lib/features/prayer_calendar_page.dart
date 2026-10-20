import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const lat = 31.85, lon = 46.07, zone = 3.0;
  DateTime date = DateTime.now();
  int correction = 0, tab = 0;
  @override void initState() { super.initState(); _loadCorrection(); }
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
    final times = _SolarTimes.forDate(date, lat, lon, zone);
    return Scaffold(appBar: AppBar(title: const Text('المواقيت والتقويم')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: _gold.withValues(alpha: .3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('التاريخ الهجري التقريبي', style: TextStyle(color: _muted)), const SizedBox(height: 8),
        Text('${hijri.day} ${hijri.monthName} ${hijri.year} هـ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _gold)),
        const SizedBox(height: 6), Text(_dateLabel(date), style: const TextStyle(color: _muted)),
        Row(children: [const Expanded(child: Text('تصحيح يدوي للتاريخ')), IconButton(onPressed: () => _correct(-1), icon: const Icon(Icons.remove_circle_outline)), Text('$correction يوم'), IconButton(onPressed: () => _correct(1), icon: const Icon(Icons.add_circle_outline))]),
        const Text('الحساب الهجري جدولي تقريبي وقد يختلف عن ثبوت الهلال الشرعي. التصحيح محفوظ على الجهاز.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
      ])), const SizedBox(height: 14),
      SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('مواقيت الصلاة'), icon: Icon(Icons.access_time)), ButtonSegment(value: 1, label: Text('إمساكية رمضان'), icon: Icon(Icons.nights_stay_outlined))], selected: {tab}, onSelectionChanged: (v) => setState(() => tab = v.first)),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        Row(children: [Expanded(child: Text('مواقيت ${_dateLabel(date)}', style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: () => setState(() => date = date.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)), IconButton(onPressed: () => setState(() => date = date.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)), IconButton(onPressed: () => setState(() => date = DateTime.now()), icon: const Icon(Icons.today))]),
        _time(Icons.wb_twilight, 'الفجر (تقديري)', times.fajr), _time(Icons.wb_sunny_outlined, 'الشروق', times.sunrise), _time(Icons.sunny, 'الظهر', times.noon), _time(Icons.wb_twilight, 'الغروب', times.sunset), _time(Icons.nights_stay_outlined, 'المغرب (تقديري)', times.maghrib),
        const Padding(padding: EdgeInsets.all(8), child: Text('الحساب الفلكي هنا تقديري: زاوية الفجر 16° والمغرب 4° بعد انخفاض الشمس. لا تعتمد عليه وحده للعبادة؛ قارن بمواقيت مكتب مرجعك في منطقتك. لا توجد حالياً تنبيهات أذان أو تحديد موقع تلقائي.', style: TextStyle(color: _muted, fontSize: 11, height: 1.6))),
      ] else ...[
        const Text('إمساكية تقديرية لقلعة سكر / ذي قار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5),
        const Text('يعرض الجدول 30 يوماً من التاريخ المختار. الفجر والغروب محسوبان فلكياً ولا يمثلان إمساكية رسمية لشهر رمضان محدد.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
        ..._ramadanRows(date),
      ],
      const Divider(), const Text('الموقع الحالي للحساب', style: TextStyle(fontWeight: FontWeight.bold)), const Text('قلعة سكر، ذي قار، العراق — إحداثيات تقريبية', style: TextStyle(color: _muted)),
    ]));
  }
  Widget _time(IconData icon, String label, String time) => Card(color: _panel, child: ListTile(leading: Icon(icon, color: _gold), title: Text(label), trailing: Text(time, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))));
}

String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _SolarTimes {
  const _SolarTimes(this.fajr, this.sunrise, this.noon, this.sunset, this.maghrib);
  final String fajr, sunrise, noon, sunset, maghrib;
  static _SolarTimes forDate(DateTime date, double lat, double lon, double zone) {
    final n = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final g = 2 * math.pi / 365 * (n - 1);
    final eq = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g) - 0.014615 * math.cos(2*g) - 0.040849 * math.sin(2*g));
    final dec = 0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2*g) + 0.000907 * math.sin(2*g) - 0.002697 * math.cos(3*g) + 0.00148 * math.sin(3*g);
    final noon = 720 - 4 * lon - eq + zone * 60;
    double angle(double altitude) { const rad = math.pi / 180; final c = ( (math.sin(altitude * rad) - math.sin(lat * rad) * math.sin(dec)) / (math.cos(lat * rad) * math.cos(dec))).clamp(-1.0, 1.0); return math.acos(c) / rad; }
    final rise = noon - 4 * angle(-0.833), set = noon + 4 * angle(-0.833);
    return _SolarTimes(_fmt(noon - 4 * angle(-16)), _fmt(rise), _fmt(noon), _fmt(set), _fmt(noon + 4 * angle(-4)));
  }
  static String _fmt(double v) { final m = v.round().clamp(0, 2879) % 1440; return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}'; }
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

List<Widget> _ramadanRows(DateTime reference) {
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
    final t = _SolarTimes.forDate(d, 31.85, 46.07, 3.0);
    final h = _Hijri.fromGregorian(d);
    return Card(color: _panel, child: ListTile(dense: true, leading: CircleAvatar(backgroundColor: _gold.withValues(alpha: .15), child: Text('${i + 1}', style: const TextStyle(color: _gold))), title: Text('رمضان ${h.day} — ${_dateLabel(d)}'), subtitle: Text('الإمساك/الفجر: ${t.fajr}  •  الإفطار التقريبي: ${t.maghrib}')));
  });
}
