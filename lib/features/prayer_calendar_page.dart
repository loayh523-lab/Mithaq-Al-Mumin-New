import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/prayer_locations.dart';
import '../data/religious_occasions.dart';

const _gold = Color(0xFFD9B66D);

/// Approximate solar times for Qal'at Sukar using a configurable Jafari-style estimate.
/// Local religious authority timetables take precedence.
class PrayerCalendarPage extends StatefulWidget {
  const PrayerCalendarPage({super.key, this.onLocationChanged, this.onHijriCorrectionChanged, this.initialTab = 0});
  final int initialTab;
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
  bool _showAnnualCalendar = false;
  double? _gpsAccuracy;
  String? _locationMessage;
  @override void initState() {
    super.initState();
    tab = widget.initialTab.clamp(0, 2).toInt();
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
    if (_gpsBusy) return;
    setState(() {
      _gpsBusy = true;
      _locationMessage = null;
    });
    try {
      final precise = await PrayerLocations.acquirePreciseLocation();
      if (!mounted) return;
      if (precise == null) {
        setState(() => _locationMessage = 'تعذّر تحديد GPS. فعّل الموقع واسمح للتطبيق بالوصول إليه.');
        return;
      }
      final accuracy = await PrayerLocations.currentLocationAccuracy();
      if (!mounted) return;
      setState(() {
        city = precise;
        _gpsAccuracy = accuracy;
        _locationMessage = accuracy == null
            ? 'تم تحديث الموقع بواسطة GPS.'
            : 'دقة الموقع المعلنة من الجهاز نحو ${accuracy.round()} متر.';
      });
      await widget.onLocationChanged?.call();
    } catch (_) {
      if (mounted) {
        setState(() => _locationMessage = 'تعذّر تحديث الموقع حالياً. تحقق من إذن الموقع وحاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
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
        title: Text('المواقيت والتقويم'),
        actions: [
          IconButton(
            tooltip: 'تحديث الموقع من GPS',
            onPressed: _gpsBusy ? null : _refreshLocation,
            icon: _gpsBusy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: _gold.withValues(alpha: .3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('التاريخ الهجري التقريبي', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 8),
        Text('${hijri.day} ${hijri.monthName} ${hijri.year} هـ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _gold)),
        const SizedBox(height: 6), Text(_dateLabel(date), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Row(children: [const Expanded(child: Text('تصحيح يدوي للتاريخ')), IconButton(onPressed: () => _correct(-1), icon: Icon(Icons.remove_circle_outline)), Text('$correction يوم'), IconButton(onPressed: () => _correct(1), icon: Icon(Icons.add_circle_outline))]),
        Text('التاريخ محسوب بالتقويم الهجري الجدولي وقد يختلف يوماً عن إعلان ثبوت الهلال في العراق. يمكنك ضبطه إذا اعتمد مكتب مرجعك تاريخاً مختلفاً.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5)),
      ])),
      if (_occasions(hijri).isNotEmpty)
        Card(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            leading: Icon(Icons.event, color: _gold),
            title: Text(_occasions(hijri).length == 1 ? 'مناسبة دينية' : 'المناسبات الدينية'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final occasion in religiousOccasionsForHijriDate(hijri.day, hijri.month))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                      onTap: () => _showOccasionDetails(context, occasion),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(occasion.displayTitle, style: const TextStyle(height: 1.5))),
                            if (occasion.sourceUrl != null)
                              const Padding(
                                padding: EdgeInsets.only(top: 3, right: 5),
                                child: Icon(Icons.open_in_new_rounded, size: 15),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 14),
      SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('مواقيت الصلاة'), icon: Icon(Icons.access_time)), ButtonSegment(value: 1, label: Text('إمساكية رمضان'), icon: Icon(Icons.nights_stay_outlined)), ButtonSegment(value: 2, label: Text('التقويم الهجري'), icon: Icon(Icons.calendar_month_rounded))], selected: {tab}, onSelectionChanged: (v) => setState(() => tab = v.first)),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        Row(children: [Expanded(child: Text('مواقيت ${_dateLabel(date)}', style: TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: () => setState(() => date = date.subtract(const Duration(days: 1))), icon: Icon(Icons.chevron_right)), IconButton(onPressed: () => setState(() => date = date.add(const Duration(days: 1))), icon: Icon(Icons.chevron_left)), IconButton(onPressed: () => setState(() => date = DateTime.now()), icon: Icon(Icons.today))]),
        if (_sameDay(date, now)) _nextPrayerCard(times, now),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.25,
          children: [
            _prayerTimeTile(Icons.wb_twilight, 'الفجر', times.fajr),
            _prayerTimeTile(Icons.sunny, 'الظهر', times.noon),
            _prayerTimeTile(Icons.wb_sunny_rounded, 'العصر', times.asr),
            _prayerTimeTile(Icons.nights_stay_outlined, 'المغرب', times.maghrib),
            _prayerTimeTile(Icons.dark_mode_outlined, 'العشاء', times.isha),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _prayerTimeTile(Icons.wb_sunny_outlined, 'الشروق', times.sunrise)),
            const SizedBox(width: 8),
            Expanded(child: _prayerTimeTile(Icons.wb_twilight, 'الغروب', times.sunset)),
          ],
        ),
        Padding(padding: EdgeInsets.all(8), child: Text('الحساب المحلي احتياطي تقريبي، وليس بديلاً عن جدول شرعي معتمد من مكتب مرجعك. استخدم زر GPS لتحديث الإحداثيات وفعّل تنبيهات الصلاة من الإعدادات.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.6))),
      ] else if (tab == 1) ...[
        Text('إمساكية تقديرية — ${city.name} / العراق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 5),
        Text('يعرض الشهر كاملاً من اليوم الأول إلى آخر يوم من رمضان المحسوب تقويمياً. الأوقات فلكية تقديرية وليست بديلاً عن إمساكية مكتب مرجعك أو الجهة المحلية المعتمدة.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5)),
        ..._ramadanRows(context, date, city.latitude, city.longitude),
      ] else if (_showAnnualCalendar) ..._annualCalendar(date.year, correction)
      else ..._monthCalendar(date, correction),
      const Divider(),
      Text('الموقع الحالي للحساب', style: TextStyle(fontWeight: FontWeight.bold)),
      Text(
        '${city.name} — ${city.id == 'current_location' ? 'موقع GPS من الجهاز' : 'إحداثيات المدينة التقريبية'}${_gpsAccuracy == null ? '' : ' (دقة نحو ${_gpsAccuracy!.round()} متر)'}',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      if (_locationMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_locationMessage!, style: TextStyle(color: _gold)),
        ),
    ]));
  }
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeAnnualYear(int delta) {
    final year = date.year + delta;
    final maxDay = DateUtils.getDaysInMonth(year, date.month);
    setState(() => date = DateTime(year, date.month, date.day.clamp(1, maxDay).toInt()));
  }


  void _moveHijriMonth(int delta) {
    final current = _Hijri.fromGregorian(date.add(Duration(days: correction)));
    var candidate = date;
    for (var step = 0; step < 35; step++) {
      candidate = candidate.add(Duration(days: delta.sign));
      final next = _Hijri.fromGregorian(candidate.add(Duration(days: correction)));
      if (next.month != current.month || next.year != current.year) {
        setState(() {
          date = candidate;
          _showAnnualCalendar = false;
        });
        return;
      }
    }
  }

  List<Widget> _monthCalendar(DateTime selectedDate, int correction) {
    final selectedHijri = _Hijri.fromGregorian(
      selectedDate.add(Duration(days: correction)),
    );
    var firstDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    for (var step = 0; step < 31; step++) {
      final previous = firstDay.subtract(const Duration(days: 1));
      final previousHijri = _Hijri.fromGregorian(
        previous.add(Duration(days: correction)),
      );
      if (previousHijri.month != selectedHijri.month ||
          previousHijri.year != selectedHijri.year) {
        break;
      }
      firstDay = previous;
    }

    final days = <DateTime>[];
    for (var step = 0; step < 31; step++) {
      final candidate = firstDay.add(Duration(days: step));
      final candidateHijri = _Hijri.fromGregorian(
        candidate.add(Duration(days: correction)),
      );
      if (candidateHijri.month != selectedHijri.month ||
          candidateHijri.year != selectedHijri.year) {
        break;
      }
      days.add(candidate);
    }
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(firstDay.weekday % 7, null),
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final selectedOccasions = religiousOccasionsForHijriDate(selectedHijri.day, selectedHijri.month);
    const weekdays = <String>['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return [
      Card(
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _gold.withValues(alpha: .24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'الشهر الهجري السابق',
                onPressed: () => _moveHijriMonth(-1),
                icon: Icon(Icons.chevron_right_rounded, color: _gold),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${selectedHijri.monthName} ${_arabicIndicDigits(selectedHijri.year)} هـ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_gregorianMonthName(firstDay.month)} ${firstDay.year}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'الشهر الهجري التالي',
                onPressed: () => _moveHijriMonth(1),
                icon: Icon(Icons.chevron_left_rounded, color: _gold),
              ),
              IconButton(
                tooltip: 'عرض التقويم السنوي',
                onPressed: () => setState(() => _showAnnualCalendar = true),
                icon: Icon(Icons.calendar_view_month_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Text(
          'اختر يوماً لعرض مناسبته وتاريخه. التقويم حسابي وقد يختلف عن إعلان ثبوت الهلال.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontSize: 11),
        ),
      ),
      Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        )).toList(),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: .78,
        ),
        itemBuilder: (context, index) {
          final day = cells[index];
          if (day == null) return const SizedBox.shrink();
          final hijri = _Hijri.fromGregorian(day.add(Duration(days: correction)));
          final occasion = _occasion(hijri);
          final selected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          return Padding(
            padding: const EdgeInsets.all(2),
            child: Material(
              color: selected
                  ? _gold
                  : occasion != null
                      ? _gold.withValues(alpha: .10)
                      : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  date = day;
                  _showAnnualCalendar = false;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? _gold
                          : occasion != null
                              ? _gold.withValues(alpha: .5)
                              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .4),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _arabicIndicDigits(hijri.day),
                        style: TextStyle(
                          color: selected ? const Color(0xFF071713) : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: selected ? const Color(0xFF071713).withValues(alpha: .7) : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                      if (occasion != null)
                        Icon(
                          Icons.circle,
                          size: 4,
                          color: selected ? const Color(0xFF071713) : _gold,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      Card(
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_rounded, color: _gold, size: 21),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_arabicIndicDigits(selectedHijri.day)} ${selectedHijri.monthName} ${_arabicIndicDigits(selectedHijri.year)} هـ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${_dateLabel(selectedDate)} م',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              if (selectedOccasions.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final occasion in selectedOccasions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: InkWell(
                      onTap: () => _showOccasionDetails(context, occasion),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                occasion.displayTitle,
                                style: TextStyle(color: _gold, fontSize: 15, height: 1.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (occasion.sourceUrl != null)
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 5),
                                child: Icon(Icons.open_in_new_rounded, size: 15),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'لا توجد مناسبة مسجلة لهذا اليوم في قائمة المناسبات الحالية.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, height: 1.5),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        helpText: 'اختر التاريخ الميلادي',
                      );
                      if (chosen != null && mounted) {
                        setState(() {
                          date = chosen;
                          _showAnnualCalendar = false;
                        });
                      }
                    },
                    icon: Icon(Icons.sync_alt_rounded),
                    label: Text('تحويل تاريخ ميلادي'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      date = DateTime.now();
                      _showAnnualCalendar = false;
                    }),
                    icon: Icon(Icons.today_rounded),
                    label: Text('اليوم'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _annualCalendar(int year, int correction) {
    final widgets = <Widget>[
      Card(
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _gold.withValues(alpha: .16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(children: [
            IconButton(tooltip: 'السنة السابقة', onPressed: () => _changeAnnualYear(-1), icon: Icon(Icons.chevron_right_rounded, color: _gold)),
            Expanded(child: Text('التقويم السنوي $year', textAlign: TextAlign.center, style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 18))),
            IconButton(tooltip: 'السنة التالية', onPressed: () => _changeAnnualYear(1), icon: Icon(Icons.chevron_left_rounded, color: _gold)),
            IconButton(tooltip: 'العودة إلى التقويم الشهري', onPressed: () => setState(() => _showAnnualCalendar = false), icon: Icon(Icons.calendar_view_month_rounded, color: _gold)),
          ]),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text('افتح أي شهر لتشاهد كل أيامه بالتاريخين الميلادي والهجري والمناسبات المسجلة. التاريخ الهجري حسابي تقريبي؛ قد يختلف عن إعلان ثبوت الهلال.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6, fontSize: 12)),
      ),
    ];
    for (var month = 1; month <= 12; month++) {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      widgets.add(Card(
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 5),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .45)),
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: Icon(Icons.calendar_month_rounded, color: _gold),
          title: Text(_gregorianMonthName(month), style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$daysInMonth يوماً'),
          children: List<Widget>.generate(daysInMonth, (index) {
            final day = index + 1;
            final gregorian = DateTime(year, month, day);
            final hijri = _Hijri.fromGregorian(gregorian.add(Duration(days: correction)));
            final occasions = _occasions(hijri);
            final hijriLabel = '${hijri.day} ${hijri.monthName} ${hijri.year} هـ';
            final subtitle = occasions.isEmpty
                ? hijriLabel
                : '$hijriLabel\n${occasions.join('\n')}';
            return ListTile(
              dense: true,
              leading: SizedBox(width: 30, child: Text('$day', textAlign: TextAlign.center, style: TextStyle(color: _gold, fontWeight: FontWeight.bold))),
              title: Text('$day ${_gregorianMonthName(month)} $year م'),
              subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
              isThreeLine: occasions.isNotEmpty,
              trailing: occasions.isEmpty ? null : Icon(Icons.event_available_rounded, color: _gold, size: 18),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.secondary.withValues(alpha: .35)),
      ),
      child: Row(children: [
        Icon(Icons.hourglass_bottom_rounded, color: scheme.secondary, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الصلاة القادمة: $nextName', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.secondary, fontSize: 16)),
          const SizedBox(height: 4),
          Text('الوقت المحسوب: ${formatPrayerTime12Hour(nextTimeText)}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ])),
        Text(
          hours > 0 ? '$hoursس $minutesد' : '$minutes دقيقة',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: scheme.onSurface),
        ),
      ]),
    );
  }

  Widget _prayerTimeTile(IconData icon, String label, String time) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _gold.withValues(alpha: .18)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _gold, size: 21),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700))),
        Text(
          formatPrayerTime12Hour(time),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _gold),
        ),
      ],
    ),
  );

}

String _arabicIndicDigits(int value) => value.toString().replaceAllMapped(
  RegExp(r'[0-9]'),
  (match) => '٠١٢٣٤٥٦٧٨٩'[int.parse(match.group(0)!)],
);

String hijriDateLabel(DateTime date, {int correction = 0}) {
  final hijri = _Hijri.fromGregorian(date.add(Duration(days: correction)));
  return '${_arabicIndicDigits(hijri.day)} ${hijri.monthName} ${_arabicIndicDigits(hijri.year)} هـ';
}

/// Returns the devotional occasion recorded for the estimated Hijri date, if any.
/// The result follows this app's approximate civil Hijri calendar.
String? hijriOccasionLabel(DateTime date, {int correction = 0}) {
  final hijri = _Hijri.fromGregorian(date.add(Duration(days: correction)));
  return _occasion(hijri);
}

/// Structured tabular Hijri date for features that need month/day matching.
/// Moon-sighting announcements can differ from this civil-calendar estimate.
({int day, int month, int year, String monthName}) hijriDateParts(
  DateTime date, {
  int correction = 0,
}) {
  final hijri = _Hijri.fromGregorian(date.add(Duration(days: correction)));
  return (
    day: hijri.day,
    month: hijri.month,
    year: hijri.year,
    monthName: hijri.monthName,
  );
}

String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _gregorianMonthName(int month) => const [
  'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
][month - 1];

String formatPrayerTime12Hour(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 2) return value;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || hour < 0 || hour > 23 || minute == null || minute < 0 || minute > 59) {
    return value;
  }
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

List<Widget> _ramadanRows(
  BuildContext context,
  DateTime reference,
  double latitude,
  double longitude,
) {
  final current = _Hijri.fromGregorian(reference);
  final targetYear = current.month > 9 ? current.year + 1 : current.year;
  DateTime? start;
  final scanStart = DateTime(reference.year - 1, 1, 1);
  for (var i = 0; i < 800; i++) {
    final candidate = scanStart.add(Duration(days: i));
    final hijri = _Hijri.fromGregorian(candidate);
    if (hijri.year == targetYear && hijri.month == 9 && hijri.day == 1) {
      start = candidate;
      break;
    }
  }

  if (start == null) {
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'تعذّر تحديد بداية رمضان بالتقويم الحسابي. اعتمد تقويماً محلياً موثوقاً.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ),
    ];
  }

  final rows = <Widget>[];
  for (var i = 0; i < 30; i++) {
    final day = start.add(Duration(days: i));
    final hijri = _Hijri.fromGregorian(day);
    if (hijri.year != targetYear || hijri.month != 9) break;

    final times = SolarPrayerTimes.forDate(
      day,
      latitude,
      longitude,
      3.0,
    );
    rows.add(
      Card(
        color: Theme.of(context).colorScheme.surface,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: _gold.withValues(alpha: .15),
            child: Text('${hijri.day}', style: TextStyle(color: _gold)),
          ),
          title: Text('رمضان ${hijri.day} — ${_dateLabel(day)}'),
          subtitle: Text(
            'الإمساك/الفجر: ${formatPrayerTime12Hour(times.fajr)}  •  الإفطار التقريبي: ${formatPrayerTime12Hour(times.maghrib)}',
          ),
        ),
      ),
    );
  }
  return rows;
}

Future<void> _showOccasionDetails(
  BuildContext context,
  ReligiousOccasion occasion,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              occasion.title,
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              '${occasion.hijriDay} ${_hijriMonthName(occasion.hijriMonth)} هـ • ${occasion.kindLabel}',
              style: TextStyle(color: Theme.of(sheetContext).colorScheme.secondary),
            ),
            if (occasion.qualification != null) ...[
              const SizedBox(height: 10),
              Text(
                occasion.qualification!,
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant, height: 1.6),
              ),
            ],
            if (occasion.sourceLabel != null) ...[
              const SizedBox(height: 14),
              Text(
                'المصدر: ${occasion.sourceLabel}',
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant, height: 1.5),
              ),
            ],
            if (occasion.sourceUrl != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(occasion.sourceUrl!);
                  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('فتح المصدر'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

String _hijriMonthName(int month) => const [
      'المحرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى',
      'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
    ][month - 1];

List<String> _occasions(_Hijri h) => religiousOccasionsForHijriDate(
      h.day,
      h.month,
    ).map((occasion) => occasion.displayTitle).toList(growable: false);

String? _occasion(_Hijri h) {
  final occasions = _occasions(h);
  return occasions.isEmpty ? null : occasions.first;
}
