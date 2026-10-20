import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/religious_content.dart';
import 'quran/quran_pages.dart';
import 'features/prayer_calendar_page.dart';
import 'features/qibla_page.dart';
import 'features/settings_page.dart';
import 'features/smart_search_page.dart';
import 'features/mafatih_library_page.dart';
import 'features/shia_text_library_page.dart';
import 'features/good_deeds_page.dart';
import 'features/names_of_allah_page.dart';
import 'features/qada_tracker_page.dart';
import 'features/dhikr_fortress_page.dart';
import 'services/prayer_locations.dart';
import 'services/prayer_notification_service.dart';

void main() => runApp(const MithaqApp());

const _ink = Color(0xFF071713);
const _panel = Color(0xFF10251E);
const _emerald = Color(0xFF1C8060);
const _gold = Color(0xFFD9B66D);
const _muted = Color(0xFF9EB5A9);

const _dailyInspirations = <({String text, String source})>[
  (text: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', source: 'سورة الرعد، الآية 28'),
  (text: 'وَقُلْ رَبِّ زِدْنِي عِلْمًا', source: 'سورة طه، الآية 114'),
  (text: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', source: 'سورة الشرح، الآية 5'),
  (text: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ', source: 'سورة البقرة، الآية 153'),
  (text: 'لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ', source: 'سورة الزمر، الآية 53'),
  (text: 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ', source: 'سورة الحديد، الآية 4'),
];

class MithaqApp extends StatelessWidget {
  const MithaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ميثاق المؤمن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _emerald,
          brightness: Brightness.dark,
          surface: _panel,
          primary: _emerald,
          secondary: _gold,
        ),
        fontFamily: 'NotoNaskhArabic',
        appBarTheme: const AppBarTheme(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selected = 0;
  PrayerCity _prayerCity = PrayerLocations.cities.first;
  DateTime _now = DateTime.now();
  Timer? _dashboardClock;
  int _hijriCorrection = 0;
  bool _dailyTaskDone = false;
  String _dailyTaskKey = '';

  static const _dailyTasks = <String>[
    'اقرأ صفحة من القرآن الكريم بتدبّر',
    'استغفر الله 100 مرة',
    'صلِّ على محمد وآل محمد 100 مرة',
    'اقرأ سورة الإخلاص وتدبّر معناها',
    'قدّم مساعدة لأحد من أهلك',
    'راجع صلواتك الخمس واهتم بأدائها في وقتها',
  ];

  @override
  void initState() {
    super.initState();
    _refreshPrayerReminders();
    _loadDashboardData();
    _dashboardClock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final current = DateTime.now();
      setState(() => _now = current);
      if (_dayKey(current) != _dailyTaskKey) {
        _loadDailyTask(current);
      }
    });
  }

  @override
  void dispose() {
    _dashboardClock?.cancel();
    super.dispose();
  }

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = await PrayerLocations.load();
      final today = DateTime.now();
      final key = _dayKey(today);
      if (!mounted) return;
      setState(() {
        _prayerCity = city;
        _hijriCorrection = prefs.getInt('hijri_correction') ?? 0;
        _dailyTaskKey = key;
        _dailyTaskDone = prefs.getBool('daily_task_done_$key') ?? false;
      });
    } catch (_) {
      // The dashboard stays available with its default city if preferences fail.
    }
  }

  Future<void> _loadDailyTask(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _dayKey(date);
      if (!mounted) return;
      setState(() {
        _dailyTaskKey = key;
        _dailyTaskDone = prefs.getBool('daily_task_done_$key') ?? false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dailyTaskKey = _dayKey(date);
        _dailyTaskDone = false;
      });
    }
  }

  Future<void> _toggleDailyTask(bool done) async {
    final key = _dayKey(_now);
    setState(() {
      _dailyTaskKey = key;
      _dailyTaskDone = done;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_task_done_$key', done);
    } catch (_) {
      if (mounted) _notice('تعذّر حفظ إنجاز عمل اليوم');
    }
  }

  Future<void> _refreshPrayerReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('prayer_notifications_enabled') ?? false) {
        final city = await PrayerLocations.load();
        await PrayerNotificationService.configure(enabled: true, city: city);
      }
    } catch (_) {
      // Reminder issues must never prevent the app from opening.
    }
  }

  Future<void> _handleLocationChanged() async {
    await _loadDashboardData();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('prayer_notifications_enabled') ?? false) {
        final city = await PrayerLocations.load();
        final ok = await PrayerNotificationService.configure(
          enabled: true,
          city: city,
        );
        if (!ok && mounted) {
          _notice('تغيّر الموقع، لكن تعذّر تحديث تذكيرات الصلاة.');
        }
      }
    } catch (_) {
      if (mounted) _notice('تم تحديث الموقع، وتعذّر تحديث التذكيرات تلقائياً.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _navigationDrawer(),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.mosque_rounded, color: _gold, size: 27),
            SizedBox(width: 10),
            Text('ميثاق المؤمن', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الباحث الذكي',
            onPressed: () => _pushPage(const SmartSearchPage()),
            icon: const Icon(Icons.search_rounded, color: _gold),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selected,
          children: [
            _homePage(),
            _selected == 1 ? const QuranIndexPage() : const SizedBox.shrink(),
            _duaPage(),
            _tasbeehPage(),
            SettingsPage(onLocationChanged: _loadDashboardData),
          ],
        ),
      ),
    );
  }

  Widget _navigationDrawer() => Drawer(
    backgroundColor: _ink,
    child: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF1B5943), Color(0xFF0B211A)],
              ),
              border: Border(bottom: BorderSide(color: _gold.withValues(alpha: .3))),
            ),
            child: const Row(
              children: [
                Icon(Icons.mosque_rounded, color: _gold, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ميثاق المؤمن', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('درب العبادة والطمأنينة', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                _drawerItem(Icons.home_rounded, 'الرئيسية', () => _selectTab(0), selected: _selected == 0),
                _drawerItem(Icons.menu_book_rounded, 'القرآن الكريم', () => _selectTab(1), selected: _selected == 1),
                _drawerItem(Icons.auto_awesome_rounded, 'الأدعية والزيارات', () => _selectTab(2), selected: _selected == 2),
                _drawerItem(Icons.fingerprint_rounded, 'التسبيح', () => _selectTab(3), selected: _selected == 3),
                _drawerItem(Icons.settings_rounded, 'الإعدادات', () => _selectTab(4), selected: _selected == 4),
                _drawerItem(Icons.search_rounded, 'الباحث الذكي', () => _openDrawerPage(const SmartSearchPage())),
                _drawerItem(Icons.checklist_rounded, 'صالح الأعمال', () => _openDrawerPage(const GoodDeedsPage())),
                _drawerItem(Icons.auto_awesome_rounded, 'أسماء الله الحسنى', () => _openDrawerPage(const NamesOfAllahPage())),
                _drawerItem(Icons.calculate_outlined, 'سجل القضاء', () => _openDrawerPage(const QadaTrackerPage())),
                _drawerItem(Icons.shield_moon_outlined, 'حصن الأذكار', () => _openDrawerPage(const DhikrFortressPage())),
                const Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(14, 18, 14, 8),
                  child: Text('خدمات إضافية', style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const Divider(color: Color(0x223CB58B)),
                _drawerItem(Icons.auto_stories_rounded, 'ختمة القرآن', () => _openDrawerPage(const KhatmaPage())),
                _drawerItem(Icons.checklist_rounded, 'متابعة الصلاة', () => _openDrawerPage(const PrayerTrackerPage())),
                _drawerItem(Icons.calendar_month_rounded, 'مواقيت الصلاة والتقويم', () => _openDrawerPage(PrayerCalendarPage(onLocationChanged: _handleLocationChanged, onHijriCorrectionChanged: _loadDashboardData))),
                _drawerItem(Icons.explore_rounded, 'اتجاه القبلة', () => _openDrawerPage(QiblaPage(onLocationChanged: _handleLocationChanged)),
                _drawerItem(Icons.menu_book_rounded, 'مفاتيح الجنان', () => _openDrawerPage(const MafatihLibraryPage())),
                _drawerItem(Icons.library_books_rounded, 'مكتبة الأدعية والزيارات', () => _openDrawerPage(const ShiaTextLibraryPage())),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('ميثاق المؤمن • نسخة قيد التطوير', style: TextStyle(color: _muted, fontSize: 11)),
          ),
        ],
      ),
    ),
  );

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool selected = false}) =>
      ListTile(
        leading: Icon(icon, color: selected ? _gold : _muted),
        title: Text(title, style: TextStyle(color: selected ? Colors.white : _muted, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
        selected: selected,
        selectedTileColor: _emerald.withValues(alpha: .18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        dense: true,
      );

  void _selectTab(int index) {
    Navigator.of(context).pop();
    setState(() => _selected = index);
  }

  void _pushPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: page),
    ));
  }

  void _openDrawerPage(Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: page),
    ));
  }

  ({String name, DateTime at}) _nextPrayer(SolarPrayerTimes times, DateTime clock) {
    final prayers = <({String name, String value})>[
      (name: 'الفجر', value: times.fajr),
      (name: 'الظهر', value: times.noon),
      (name: 'العصر', value: times.asr),
      (name: 'المغرب', value: times.maghrib),
      (name: 'العشاء', value: times.isha),
    ];
    for (final prayer in prayers) {
      final parts = prayer.value.split(':');
      if (parts.length != 2) continue;
      final candidate = DateTime(
        clock.year,
        clock.month,
        clock.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
      if (candidate.isAfter(clock)) return (name: prayer.name, at: candidate);
    }

    final tomorrow = DateTime(clock.year, clock.month, clock.day).add(const Duration(days: 1));
    final parts = SolarPrayerTimes.forDate(
      tomorrow, _prayerCity.latitude, _prayerCity.longitude, 3.0,
    ).fajr.split(':');
    return (
      name: 'الفجر',
      at: DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day,
        int.tryParse(parts[0]) ?? 5, int.tryParse(parts[1]) ?? 0,
      ),
    );
  }

  String _clockLabel(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _countdownLabel(DateTime target, DateTime current) {
    final minutes = target.difference(current).inMinutes.clamp(0, 999999);
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours > 0) return '$hours س $remainder د';
    return '$remainder دقيقة';
  }

  String _gregorianLabel(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _homePage() {
    final times = SolarPrayerTimes.forDate(
      _now, _prayerCity.latitude, _prayerCity.longitude, 3.0,
    );
    final next = _nextPrayer(times, _now);
    final prayers = <({String name, String time, IconData icon})>[
      (name: 'الفجر', time: times.fajr, icon: Icons.nights_stay_outlined),
      (name: 'الظهر', time: times.noon, icon: Icons.wb_sunny_outlined),
      (name: 'العصر', time: times.asr, icon: Icons.wb_sunny_rounded),
      (name: 'المغرب', time: times.maghrib, icon: Icons.wb_twilight_rounded),
      (name: 'العشاء', time: times.isha, icon: Icons.dark_mode_outlined),
    ];
    final dayOfYear = DateTime(_now.year, _now.month, _now.day)
        .difference(DateTime(_now.year, 1, 1)).inDays;
    final dailyTask = _dailyTasks[dayOfYear % _dailyTasks.length];
    final inspiration = _dailyInspirations[dayOfYear % _dailyInspirations.length];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1B5943), Color(0xFF103226), Color(0xFF0B211A)],
            ),
            border: Border.all(color: _gold.withValues(alpha: .35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: _gold, size: 26),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التاريخ الهجري', style: TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(
                      hijriDateLabel(_now, correction: _hijriCorrection),
                      style: const TextStyle(color: _gold, fontSize: 21, fontWeight: FontWeight.w800, height: 1.5),
                    ),
                    const SizedBox(height: 3),
                    Text(_gregorianLabel(_now), style: const TextStyle(color: Color(0xFFD0DED6), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: .3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: _gold),
              SizedBox(width: 8),
              Text('قبس اليوم', style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 10),
            Text(inspiration.text, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 20, height: 1.9, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(inspiration.source, style: const TextStyle(color: _muted, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withValues(alpha: .38)),
            boxShadow: [
              BoxShadow(color: _emerald.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 7)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.hourglass_bottom_rounded, color: _gold, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الصلاة القادمة', style: TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 3),
                    Text(next.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _gold)),
                    const SizedBox(height: 4),
                    Text('موعدها ${_clockLabel(next.at)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('المتبقي', style: TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(
                    _countdownLabel(next.at, _now),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        const Text('مواقيت الصلوات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < prayers.length; i++) ...[
                Builder(builder: (context) {
                  final prayer = prayers[i];
                  final active = next.name == prayer.name;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    decoration: BoxDecoration(
                      color: active ? _emerald.withValues(alpha: .2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Icon(prayer.icon, color: active ? _gold : _muted, size: 21),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            prayer.name,
                            style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? Colors.white : _muted),
                          ),
                        ),
                        if (active) ...[
                          const Text('القادمة', style: TextStyle(color: _gold, fontSize: 11)),
                          const SizedBox(width: 9),
                        ],
                        Text(prayer.time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: active ? _gold : Colors.white)),
                      ],
                    ),
                  );
                }),
                if (i < prayers.length - 1)
                  Divider(height: 1, indent: 42, color: Colors.white.withValues(alpha: .05)),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
          child: Text(
            'المواقيت هنا فلكية تقديرية، وقد تختلف عن جدول مكتب مرجعك؛ اعتمد الجدول الشرعي المعتمد في منطقتك.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.6),
          ),
        ),
        const SizedBox(height: 22),
        const Text('عمل اليوم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(color: _gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.volunteer_activism_rounded, color: _gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dailyTask,
                  style: TextStyle(
                    height: 1.6,
                    color: _dailyTaskDone ? _muted : Colors.white,
                    decoration: _dailyTaskDone ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              Checkbox(
                value: _dailyTaskDone,
                activeColor: _emerald,
                checkColor: Colors.white,
                onChanged: (value) => _toggleDailyTask(value ?? false),
              ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _pushPage(const GoodDeedsPage()),
            icon: const Icon(Icons.checklist_rounded),
            label: const Text('عرض بقية صالح الأعمال'),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => setState(() => _selected = 1),
            child: Ink(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold.withValues(alpha: .2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Color(0x223CB58B), borderRadius: BorderRadius.all(Radius.circular(15))),
                    child: Icon(Icons.menu_book_rounded, color: _gold, size: 26),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('القرآن الكريم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        SizedBox(height: 4),
                        Text('افتح المصحف وتابع قراءتك', style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: _gold, size: 25),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _duaPage() => _DuaLibrary(onNotice: _notice);

  Widget _tasbeehPage() => const TasbeehPage();

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});
  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage> {
  static const _steps = <({String title, String phrase, int target})>[
    (title: 'التكبير', phrase: 'الله أكبر', target: 34),
    (title: 'التحميد', phrase: 'الحمد لله', target: 33),
    (title: 'التسبيح', phrase: 'سبحان الله', target: 33),
  ];
  bool _zahraMode = true;
  int _step = 0;
  int _count = 0;
  int _generalCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _zahraMode = prefs.getBool('tasbeeh_zahra_mode') ?? true;
        _step = (prefs.getInt('tasbeeh_zahra_step') ?? 0).clamp(0, 2);
        _count = (prefs.getInt('tasbeeh_zahra_count') ?? 0).clamp(0, 34);
        _generalCount = prefs.getInt('tasbeeh_general_count') ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tasbeeh_zahra_mode', _zahraMode);
      await prefs.setInt('tasbeeh_zahra_step', _step);
      await prefs.setInt('tasbeeh_zahra_count', _count);
      await prefs.setInt('tasbeeh_general_count', _generalCount);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ التقدم على الجهاز')),
        );
      }
    }
  }

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      if (!_zahraMode) {
        _generalCount++;
      } else {
        final target = _steps[_step].target;
        if (_count < target) {
          _count++;
        }
        if (_count >= target && _step < _steps.length - 1) {
          _step++;
          _count = 0;
        } else if (_count >= target && _step == _steps.length - 1) {
          _count = target;
        }
      }
    });
    _persist();
  }

  Future<void> _reset() async {
    setState(() {
      _step = 0;
      _count = 0;
      _generalCount = 0;
    });
    await _persist();
  }

  Future<void> _setMode(bool zahra) async {
    setState(() => _zahraMode = zahra);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final current = _zahraMode ? _count : _generalCount;
    final target = _zahraMode ? step.target : null;
    final progress = target == null ? 0.0 : current / target;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const Text('التسبيح', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (_zahraMode) const Text('عداد محفوظ على جهازك، مع تسبيح الزهراء عليها السلام بالترتيب', style: TextStyle(color: _muted, height: 1.6)),
        const SizedBox(height: 18),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('تسبيح الزهراء'), icon: Icon(Icons.auto_awesome_rounded)),
            ButtonSegment(value: false, label: Text('تسبيح عام'), icon: Icon(Icons.fingerprint_rounded)),
          ],
          selected: {_zahraMode},
          onSelectionChanged: _loading ? null : (selection) => _setMode(selection.first),
        ),
        const SizedBox(height: 18),
        if (_zahraMode) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withValues(alpha: .28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('مراحل تسبيح الزهراء عليها السلام', style: TextStyle(color: _gold, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(
                      i < _step || (i == _step && _count >= _steps[i].target)
                          ? Icons.check_circle_rounded
                          : i == _step ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      color: i == _step ? _gold : _muted,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text('${_steps[i].title}: ${_steps[i].phrase}', style: TextStyle(color: i == _step ? Colors.white : _muted, fontWeight: i == _step ? FontWeight.bold : FontWeight.normal))),
                    Text('${i == _step ? _count : i < _step ? _steps[i].target : 0}/${_steps[i].target}', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  ]),
                ),
              const SizedBox(height: 4),
              const Text('التكبير 34 مرة، ثم الحمد 33 مرة، ثم التسبيح 33 مرة.', style: TextStyle(color: _muted, fontSize: 12, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 20),
        ],
        Center(
          child: Column(children: [
            if (_zahraMode)
              Text(
                current >= (target ?? 0) && _step == 2 ? 'اكتمل تسبيح الزهراء' : step.phrase,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, height: 1.8, color: _gold, fontWeight: FontWeight.w800),
              ),
            const SizedBox(height: 18),
            if (_zahraMode) ...[
              Text('$_count', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress < 0.0 ? 0.0 : (progress > 1.0 ? 1.0 : progress),
                  minHeight: 7,
                  backgroundColor: _panel,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 8),
              Text('المرحلة ${_step + 1} من 3 • المطلوب ${step.target}', style: const TextStyle(color: _muted)),
            ] else
              Text('$_generalCount', style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w800)),
            const SizedBox(height: 22),
            Semantics(
              button: true,
              label: 'زيادة عداد التسبيح',
              child: InkWell(
                onTap: _loading || (_zahraMode && _step == 2 && _count >= 33) ? null : _increment,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _panel,
                    border: Border.all(color: _gold, width: 2),
                    boxShadow: [BoxShadow(color: _emerald.withValues(alpha: .2), blurRadius: 28, spreadRadius: 4)],
                  ),
                  child: const Center(child: Icon(Icons.fingerprint_rounded, color: _gold, size: 76)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_zahraMode) const Text('اضغط على الدائرة للتسبيح', style: TextStyle(color: _muted)),
            const SizedBox(height: 18),
            Wrap(alignment: WrapAlignment.center, spacing: 10, children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _reset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة من البداية'),
              ),
              if (_zahraMode && _step > 0)
                OutlinedButton.icon(
                  onPressed: _loading ? null : () {
                    setState(() { _step--; _count = 0; });
                    _persist();
                  },
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('المرحلة السابقة'),
                ),
            ]),
            if (_zahraMode && _step == 2 && _count >= 33)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text('تقبّل الله طاعتكم', style: TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
      ],
    );
  }
}

class _DuaLibrary extends StatefulWidget {
  const _DuaLibrary({required this.onNotice});
  final ValueChanged<String> onNotice;

  @override
  State<_DuaLibrary> createState() => _DuaLibraryState();
}

class _DuaLibraryState extends State<_DuaLibrary> {
  final _search = TextEditingController();
  String _filter = 'الاستغفار';
  static const _filters = ['الاستغفار', 'الصلاة على محمد وآل محمد', 'التسبيح'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Card(
    color: _panel,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: _gold.withValues(alpha: .13),
        child: Icon(icon, color: _gold),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: _muted, height: 1.5)),
      trailing: const Icon(Icons.chevron_left_rounded, color: _gold),
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final items = dailyDhikr.where((item) {
      final matchesQuery = query.isEmpty || item.title.contains(query) || item.text.contains(query);
      final matchesFilter = item.title == _filter;
      return matchesQuery && matchesFilter;
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('الأدعية والأذكار', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('الأدعية والأذكار والمكتبة الشيعية', style: TextStyle(color: _muted)),
        const SizedBox(height: 14),
        Card(
          color: _panel,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0x223CB58B), child: Icon(Icons.auto_stories_rounded, color: _gold)),
            title: const Text('مفاتيح الجنان', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تصفح الأبواب والنصوص دون إنترنت', style: TextStyle(color: _muted)),
            trailing: const Icon(Icons.chevron_left_rounded, color: _gold),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: MafatihLibraryPage()),
            )),
          ),
        ),
        Card(
          color: _panel,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0x223CB58B), child: Icon(Icons.menu_book_rounded, color: _gold)),
            title: const Text('الأدعية والزيارات والصحيفة السجادية', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('مجموعة نصوص مع البحث والعرض دون إنترنت', style: TextStyle(color: _muted)),
            trailing: const Icon(Icons.chevron_left_rounded, color: _gold),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage()),
            )),
          ),
        ),
        const SizedBox(height: 16),
        const Text('أقسام المكتبة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _sectionCard(
          context,
          icon: Icons.auto_stories_rounded,
          title: 'الأدعية العامة',
          subtitle: 'الأدعية والمناجيات المتوفرة في المكتبة',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'أدعية عامة')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.today_rounded,
          title: 'أدعية الأيام',
          subtitle: 'الأدعية الأسبوعية المتوفرة',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'أدعية الأيام')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.temple_buddhist_rounded,
          title: 'الزيارات الشريفة',
          subtitle: 'زيارات المعصومين عليهم السلام',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الزيارات')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.menu_book_rounded,
          title: 'التعقيبات ومفاتيح الجنان',
          subtitle: 'تصفح أبواب مفاتيح الجنان وبحثها',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: MafatihLibraryPage()),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.auto_awesome_rounded,
          title: 'الصحيفة السجادية',
          subtitle: 'أدعية الإمام زين العابدين عليه السلام',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الصحيفة السجادية')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.favorite_border_rounded,
          title: 'أسماء الله الحسنى',
          subtitle: 'الأسماء ومعانيها الموجزة',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: NamesOfAllahPage()),
          )),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ابحث عن ذكر...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: _panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filters.map((filter) => ChoiceChip(
            label: Text(filter),
            selected: _filter == filter,
            onSelected: (_) => setState(() => _filter = filter),
          )).toList(),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('ماكو نتائج مطابقة', style: TextStyle(color: _muted))))
        else
          ...items.map((item) => Card(
            color: _panel,
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: _panel,
                  title: Text(item.title),
                  content: SingleChildScrollView(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.text, style: const TextStyle(fontSize: 20, height: 1.8)),
                      const SizedBox(height: 16),
                      const Text('المصدر / التوضيح', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(item.source, style: const TextStyle(color: _muted)),
                      if (item.note != null) ...[
                        const SizedBox(height: 8),
                        Text(item.note!, style: const TextStyle(color: _muted, height: 1.5)),
                      ],
                    ],
                  )),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(item.title, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold))), const Icon(Icons.open_in_new_rounded, size: 17, color: _muted)]),
                    const SizedBox(height: 10),
                    Text(item.text, style: const TextStyle(fontSize: 18, height: 1.7)),
                    const SizedBox(height: 8),
                    Text(item.source, style: const TextStyle(fontSize: 12, color: _muted)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'نسخ الذكر',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.text));
                          widget.onNotice('تم نسخ الذكر');
                        },
                        icon: const Icon(Icons.content_copy_rounded, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        const SizedBox(height: 8),
        const Text('تنبيه: هذه نسخة تأسيسية؛ النصوص المنسوبة إلى روايات أو كتب ستضاف بعد مراجعة المصدر والموضع بدقة.', style: TextStyle(color: _muted, fontSize: 12, height: 1.6)),
      ],
    );
  }
}


class KhatmaPage extends StatefulWidget {
  const KhatmaPage({super.key});

  @override
  State<KhatmaPage> createState() => _KhatmaPageState();
}

class _KhatmaPageState extends State<KhatmaPage> {
  static const _juzStartPages = <int>[1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
  final Set<int> _completedPages = <int>{};

  bool _isJuzComplete(int juz) {
    final start = _juzStartPages[juz];
    final end = juz == 29 ? 604 : _juzStartPages[juz + 1] - 1;
    for (var page = start; page <= end; page++) {
      if (!_completedPages.contains(page)) return false;
    }
    return true;
  }

  int get _completedJuz => List<int>.generate(30, (index) => index).where(_isJuzComplete).length;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final savedPages = prefs.getStringList('khatma_completed_pages') ?? const <String>[];
      setState(() {
        _completedPages
          ..clear()
          ..addAll(savedPages.map(int.tryParse).whereType<int>().where((page) => page >= 1 && page <= 604));
      });
    } catch (_) {
      // Progress can still be changed for this session.
    }
  }

  Future<void> _setProgress(int value) async {
    final target = value.clamp(0, 30).toInt();
    setState(() {
      if (target == 0) {
        _completedPages.clear();
      } else {
        final current = _completedJuz;
        int? juzToChange;
        if (target > current) {
          for (var juz = 0; juz < 30; juz++) {
            if (!_isJuzComplete(juz)) { juzToChange = juz; break; }
          }
        } else {
          for (var juz = 29; juz >= 0; juz--) {
            if (_isJuzComplete(juz)) { juzToChange = juz; break; }
          }
        }
        if (juzToChange != null) {
          final start = _juzStartPages[juzToChange];
          final end = juzToChange == 29 ? 604 : _juzStartPages[juzToChange + 1] - 1;
          for (var page = start; page <= end; page++) {
            if (target > current) {
              _completedPages.add(page);
            } else {
              _completedPages.remove(page);
            }
          }
        }
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('khatma_completed_pages', (_completedPages.toList()..sort()).map((page) => page.toString()).toList());
      await prefs.remove('khatma_completed_juz');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ تقدّم الختمة')),
        );
      }
    }
  }

  Future<void> _togglePage(int page) async {
    setState(() {
      if (_completedPages.contains(page)) {
        _completedPages.remove(page);
      } else {
        _completedPages.add(page);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'khatma_completed_pages',
        (_completedPages.toList()..sort()).map((value) => value.toString()).toList(),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ صفحات الختمة')),
        );
      }
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط الختمة؟'),
        content: const Text('سيُعاد تقدّم الختمة إلى صفر جزء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة الضبط'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _setProgress(0);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_completedJuz / 30 * 100).round();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ختمة القرآن'),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط الختمة',
            onPressed: _confirmReset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _gold.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories_rounded, color: _gold, size: 34),
                const SizedBox(height: 16),
                const Text(
                  'خطوة كل يوم',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سجّل الأجزاء التي أكملت قراءتها، وسيبقى تقدّمك محفوظاً على هذا الجهاز.',
                  style: TextStyle(color: _muted, height: 1.7),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_completedJuz',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: _gold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10, right: 8),
                      child: Text('/ 30 جزءاً', style: TextStyle(color: _muted)),
                    ),
                    const Spacer(),
                    Text('$percent%', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _completedJuz / 30,
                    minHeight: 10,
                    backgroundColor: _ink,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _completedJuz > 0
                            ? () => _setProgress(_completedJuz - 1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        label: const Text('إنقاص جزء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _completedJuz < 30
                            ? () => _setProgress(_completedJuz + 1)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إكمال جزء'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_completedJuz == 30)
            const ListTile(
              leading: Icon(Icons.check_circle_rounded, color: _gold),
              title: Text('تقبّل الله طاعتكم'),
              subtitle: Text('أكملت تسجيل الأجزاء الثلاثين في هذه الختمة.'),
            )
          else
            ListTile(
              leading: const Icon(Icons.bookmark_outline_rounded, color: _gold),
              title: const Text('الخطوة التالية'),
              subtitle: Text('بعد قراءة الجزء ${_completedJuz + 1}، حدّث تقدّمك هنا.'),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withValues(alpha: .25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('تتبّع الصفحات', style: TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('سجّل كل صفحة بعد قراءتها في مصحف المدينة ذي 604 صفحات. يُحسب اكتمال الجزء من الصفحات المسجّلة ضمن نطاقه.', style: TextStyle(color: _muted, height: 1.6, fontSize: 12)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('${_completedPages.length} / 604 صفحة', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold))),
                Text('${(_completedPages.length / 604 * 100).round()}%', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: _completedPages.length / 604, minHeight: 8, backgroundColor: _ink, color: _gold)),
              const SizedBox(height: 8),
              Material(
                color: _panel,
                borderRadius: BorderRadius.circular(12),
                child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('اختيار الصفحات المكتملة'),
                subtitle: const Text('اضغط رقم الصفحة لتسجيلها أو إلغاء تسجيلها'),
                children: [
                  SizedBox(
                    height: 360,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 6, mainAxisSpacing: 6),
                      itemCount: 604,
                      itemBuilder: (context, index) {
                        final page = index + 1;
                        final done = _completedPages.contains(page);
                        return Material(
                          color: done ? _emerald : _ink,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => _togglePage(page),
                            child: Center(child: Text('$page', style: TextStyle(color: done ? Colors.white : _muted, fontSize: 11, fontWeight: done ? FontWeight.bold : FontWeight.normal))),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('أرقام الصفحات تخص مصحف المدينة ذي 604 صفحات. إذا كنت تستخدم طبعة مختلفة، اعتمد ترقيمها أو تابع الأجزاء أعلاه.', style: TextStyle(color: _muted, fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }
}


class PrayerTrackerPage extends StatefulWidget {
  const PrayerTrackerPage({super.key});

  @override
  State<PrayerTrackerPage> createState() => _PrayerTrackerPageState();
}

class _PrayerTrackerPageState extends State<PrayerTrackerPage> {
  static const _prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  final Set<String> _completed = <String>{};
  bool _loaded = false;

  String get _storageKey {
    final now = DateTime.now();
    final day = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'prayer_tracker_$day';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addAll(prefs.getStringList(_storageKey) ?? const <String>[]);
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _toggle(String prayer, bool checked) async {
    setState(() {
      if (checked) {
        _completed.add(prayer);
      } else {
        _completed.remove(prayer);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _completed.toList());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ السجل على الجهاز')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completed.length / _prayers.length;
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الصلاة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _gold.withValues(alpha: .3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: _gold, size: 34),
                const SizedBox(height: 14),
                const Text('صلوات اليوم', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('علّم الصلاة بعد أدائها. السجلّ يُحفظ لهذا اليوم على جهازك.', style: TextStyle(color: _muted, height: 1.7)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          color: _gold,
                          backgroundColor: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_completed.length}/5', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_loaded)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            ..._prayers.map((prayer) => Card(
              color: _panel,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 9),
              child: Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                value: _completed.contains(prayer),
                onChanged: (checked) => _toggle(prayer, checked ?? false),
                activeColor: _emerald,
                checkColor: Colors.white,
                secondary: Icon(
                  _completed.contains(prayer) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: _completed.contains(prayer) ? _gold : _muted,
                ),
                title: Text(prayer, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _completed.contains(prayer) ? 'تم تسجيلها' : 'لم تُسجّل بعد',
                  style: const TextStyle(color: _muted),
                ),
              ),
            ))),
          const SizedBox(height: 8),
          const Text('هذا سجلّ شخصي فقط وليس جدولاً لمواقيت الصلاة. ستُضاف المواقيت بعد اعتماد طريقة حساب جعفرية موثّقة.', style: TextStyle(color: _muted, fontSize: 12, height: 1.7)),
        ],
      ),
    );
  }
}
