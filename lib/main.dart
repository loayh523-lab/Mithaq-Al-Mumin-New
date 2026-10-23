import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'data/religious_content.dart';
import 'quran/quran_pages.dart';
import 'features/prayer_calendar_page.dart';
import 'features/qibla_page.dart';
import 'features/settings_page.dart';
import 'features/smart_search_page.dart';
import 'features/shia_text_library_page.dart';
import 'features/good_deeds_page.dart';
import 'features/names_of_allah_page.dart';
import 'features/qada_tracker_page.dart';
import 'features/dhikr_fortress_page.dart';
import 'features/faith_services_page.dart';
import 'features/favorites_page.dart';
import 'features/rakah_counter_page.dart';
import 'features/about_support_page.dart';
import 'services/prayer_locations.dart';
import 'services/prayer_notification_service.dart';
import 'services/app_theme.dart';
import 'widgets/mithaq_brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppTheme.load();
  } catch (_) {
    // Keep the default dark appearance if local preferences cannot be read.
  }
  runApp(const MithaqApp());
}

const _ink = Color(0xFF071713);
const _panel = Color(0xFF10251E);
const _emerald = Color(0xFF1C8060);
const _gold = Color(0xFFD9B66D);
const _muted = Color(0xFF697A70);

const _dailyInspirations = <({String text, String source, int surahId, int verse})>[
  (text: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', source: 'سورة الرعد، الآية 28', surahId: 13, verse: 28),
  (text: 'وَقُلْ رَبِّ زِدْنِي عِلْمًا', source: 'سورة طه، الآية 114', surahId: 20, verse: 114),
  (text: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', source: 'سورة الشرح، الآية 5', surahId: 94, verse: 5),
  (text: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ', source: 'سورة البقرة، الآية 153', surahId: 2, verse: 153),
  (text: 'لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ', source: 'سورة الزمر، الآية 53', surahId: 39, verse: 53),
  (text: 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ', source: 'سورة الحديد، الآية 4', surahId: 57, verse: 4),
  (text: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا', source: 'سورة البقرة، الآية 286', surahId: 2, verse: 286),
  (text: 'فَاذْكُرُونِي أَذْكُرْكُمْ', source: 'سورة البقرة، الآية 152', surahId: 2, verse: 152),
  (text: 'لَئِنْ شَكَرْتُمْ لَأَزِيدَنَّكُمْ', source: 'سورة إبراهيم، الآية 7', surahId: 14, verse: 7),
  (text: 'وَلَا تَهِنُوا وَلَا تَحْزَنُوا', source: 'سورة آل عمران، الآية 139', surahId: 3, verse: 139),
  (text: 'وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ', source: 'سورة الطلاق، الآية 3', surahId: 65, verse: 3),
  (text: 'وَلَا تَيْأَسُوا مِنْ رَوْحِ اللَّهِ', source: 'سورة يوسف، الآية 87', surahId: 12, verse: 87),
  (text: 'قُلْ لَنْ يُصِيبَنَا إِلَّا مَا كَتَبَ اللَّهُ لَنَا', source: 'سورة التوبة، الآية 51', surahId: 9, verse: 51),
  (text: 'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ', source: 'سورة البقرة، الآية 45', surahId: 2, verse: 45),
  (text: 'إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَى', source: 'سورة طه، الآية 46', surahId: 20, verse: 46),
  (text: 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ', source: 'سورة الرحمن، الآية 13', surahId: 55, verse: 13),
  (text: 'وَمَا خَلَقْتُ الْجِنَّ وَالْإِنْسَ إِلَّا لِيَعْبُدُونِ', source: 'سورة الذاريات، الآية 56', surahId: 51, verse: 56),
  (text: 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَى', source: 'سورة الضحى، الآية 5', surahId: 93, verse: 5),
  (text: 'مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَى', source: 'سورة الضحى، الآية 3', surahId: 93, verse: 3),
  (text: 'إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّى يُغَيِّرُوا مَا بِأَنْفُسِهِمْ', source: 'سورة الرعد، الآية 11', surahId: 13, verse: 11),
  (text: 'فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ', source: 'سورة البقرة، الآية 186', surahId: 2, verse: 186),
  (text: 'ادْعُونِي أَسْتَجِبْ لَكُمْ', source: 'سورة غافر، الآية 60', surahId: 40, verse: 60),
  (text: 'سَيَجْعَلُ اللَّهُ بَعْدَ عُسْرٍ يُسْرًا', source: 'سورة الطلاق، الآية 7', surahId: 65, verse: 7),
  (text: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', source: 'سورة آل عمران، الآية 173', surahId: 3, verse: 173),
  (text: 'إِنَّمَا يُوَفَّى الصَّابِرُونَ أَجْرَهُمْ بِغَيْرِ حِسَابٍ', source: 'سورة الزمر، الآية 10', surahId: 39, verse: 10),
  (text: 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا', source: 'سورة العنكبوت، الآية 69', surahId: 29, verse: 69),
  (text: 'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ', source: 'سورة يونس، الآية 62', surahId: 10, verse: 62),
  (text: 'أَلَيْسَ اللَّهُ بِكَافٍ عَبْدَهُ', source: 'سورة الزمر، الآية 36', surahId: 39, verse: 36),
  (text: 'إِنْ يَنْصُرْكُمُ اللَّهُ فَلَا غَالِبَ لَكُمْ', source: 'سورة آل عمران، الآية 160', surahId: 3, verse: 160),
  (text: 'وَمَنْ يُؤْمِنْ بِاللَّهِ يَهْدِ قَلْبَهُ', source: 'سورة التغابن، الآية 11', surahId: 64, verse: 11),
];

class MithaqApp extends StatelessWidget {
  const MithaqApp({super.key});

  ThemeData _makeTheme(bool dark) {
    final background = dark ? _ink : const Color(0xFFF7F5EF);
    final surface = dark ? _panel : const Color(0xFFFFFFFF);
    final foreground = dark ? Colors.white : const Color(0xFF18352B);
    final muted = dark ? _muted : const Color(0xFF667A70);
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _emerald,
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: surface,
        primary: _emerald,
        secondary: _gold,
      ),
      fontFamily: 'Amiri',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: muted.withValues(alpha: .14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? _ink : const Color(0xFFF0F2EC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: muted.withValues(alpha: .24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: muted.withValues(alpha: .20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: foreground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDark,
      builder: (context, isDark, child) => MaterialApp(
        title: 'ميثاق المؤمن',
        debugShowCheckedModeBanner: false,
        theme: _makeTheme(false),
        darkTheme: _makeTheme(true),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: MainShell(),
        ),
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
  int _inspirationOffset = 0;

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
        await PrayerNotificationService.ensureScheduled(city: city);
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
        title: Row(
          children: [
            const MithaqBrandMark(size: 36),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ميثاق المؤمن',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
            _selected == 2 ? _duaPage() : const SizedBox.shrink(),
            _selected == 3
                ? PrayerCalendarPage(
                    onLocationChanged: _handleLocationChanged,
                    onHijriCorrectionChanged: _loadDashboardData,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: _gold.withValues(alpha: .18))),
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          indicatorColor: _emerald.withValues(alpha: .25),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _selected,
          onDestinationSelected: (index) => setState(() => _selected = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: _gold),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded, color: _gold),
              label: 'القرآن',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: _gold),
              label: 'الأدعية والزيارات',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: _gold),
              label: 'المواقيت',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationDrawer() => Drawer(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    child: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF173C2D), const Color(0xFF0B211A), Theme.of(context).scaffoldBackgroundColor]
                    : [const Color(0xFFE5EFE7), const Color(0xFFF2F5EF), Theme.of(context).scaffoldBackgroundColor],
              ),
              border: Border(
                bottom: BorderSide(color: _gold.withValues(alpha: .32)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const MithaqBrandMark(size: 62),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ميثاق المؤمن',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'درب العبادة والطمأنينة',
                            maxLines: 2,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: _gold, size: 17),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'قرآن • دعاء • عبادة • متابعة',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              children: [
                _drawerSectionTitle('الأقسام الرئيسية', Icons.grid_view_rounded),
                _drawerGrid(
                  children: [
                    _drawerGridItem(Icons.home_rounded, 'الرئيسية', () => _selectTab(0), selected: _selected == 0),
                    _drawerGridItem(Icons.auto_stories_rounded, 'القرآن الكريم', () => _selectTab(1), selected: _selected == 1),
                    _drawerGridItem(Icons.volunteer_activism_rounded, 'الأدعية والزيارات', () => _selectTab(2), selected: _selected == 2),
                    _drawerGridItem(Icons.access_time_rounded, 'مواقيت الصلاة', () => _selectTab(3), selected: _selected == 3),
                  ],
                ),
                const SizedBox(height: 8),
                _drawerSectionTitle('العبادات والمتابعة', Icons.spa_rounded),
                _drawerGrid(
                  children: [
                    _drawerGridItem(Icons.fingerprint_rounded, 'التسبيح', () => _openDrawerPage(const TasbeehPage())),
                    _drawerGridItem(Icons.bookmark_added_rounded, 'ختمة القرآن', () => _openDrawerPage(const KhatmaPage())),
                    _drawerGridItem(Icons.event_available_rounded, 'متابعة الصلاة', () => _openDrawerPage(const PrayerTrackerPage())),
                    _drawerGridItem(Icons.handshake_rounded, 'الأعمال الصالحة', () => _openDrawerPage(const GoodDeedsPage())),
                    _drawerGridItem(Icons.history_edu_rounded, 'قضاء العبادات', () => _openDrawerPage(const QadaTrackerPage())),
                    _drawerGridItem(Icons.shield_moon_rounded, 'حصن الأذكار', () => _openDrawerPage(const DhikrFortressPage())),
                    _drawerGridItem(Icons.calculate_rounded, 'عداد الركعات', () => _openDrawerPage(const RakahCounterPage())),
                  ],
                ),
                const SizedBox(height: 8),
                _drawerSectionTitle('المعرفة والخدمات', Icons.local_library_rounded),
                _drawerGrid(
                  children: [
                    _drawerGridItem(Icons.manage_search_rounded, 'الباحث الذكي', () => _openDrawerPage(const SmartSearchPage())),
                    _drawerGridItem(Icons.brightness_5_rounded, 'أسماء الله الحسنى', () => _openDrawerPage(const NamesOfAllahPage())),
                    _drawerGridItem(Icons.explore_rounded, 'اتجاه القبلة', () => _openDrawerPage(QiblaPage(onLocationChanged: _handleLocationChanged))),
                    _drawerGridItem(Icons.collections_bookmark_rounded, 'مكتبة النصوص', () => _openDrawerPage(const ShiaTextLibraryPage())),
                    _drawerGridItem(Icons.support_agent_rounded, 'الخدمات الإيمانية', () => _openDrawerPage(const FaithServicesPage())),
                    _drawerGridItem(Icons.info_outline_rounded, 'عن التطبيق والدعم', () => _openDrawerPage(const AboutSupportPage())),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Expanded(child: _drawerBottomItem(Icons.star_rounded, 'المفضلة', () => _openDrawerPage(const FavoritesPage()))),
                const SizedBox(width: 10),
                Expanded(child: _drawerBottomItem(Icons.tune_rounded, 'الإعدادات', () => _openDrawerPage(SettingsPage(onLocationChanged: _handleLocationChanged)))),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: .16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security_rounded, color: _gold, size: 17),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نسخة قيد التطوير • راجع المصادر عند الحاجة',
                    style: TextStyle(color: _muted, fontSize: 10, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _drawerGrid({required List<Widget> children}) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: .88,
    children: children,
  );

  Widget _drawerGridItem(IconData icon, String title, VoidCallback onTap, {bool selected = false}) =>
      Material(
        color: selected ? _emerald.withValues(alpha: .16) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? _gold.withValues(alpha: .55) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .55),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: selected ? _gold.withValues(alpha: .15) : _emerald.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: selected ? _gold : Theme.of(context).colorScheme.secondary, size: 23),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 10.5,
                    height: 1.25,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _drawerBottomItem(IconData icon, String title, VoidCallback onTap) => Material(
    color: _emerald.withValues(alpha: .13),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _gold.withValues(alpha: .22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _gold, size: 19),
            const SizedBox(width: 7),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ),
  );

  Widget _drawerSectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 7),
    child: Row(
      children: [
        Icon(icon, color: _gold.withValues(alpha: .88), size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .1,
          ),
        ),
      ],
    ),
  );

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool selected = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Material(
          color: selected ? _emerald.withValues(alpha: .18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsetsDirectional.fromSTEB(9, 7, 11, 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? _gold.withValues(alpha: .34)
                      : Colors.white.withValues(alpha: .045),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: selected ? _gold.withValues(alpha: .13) : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? _gold.withValues(alpha: .3)
                            : _muted.withValues(alpha: .08),
                      ),
                    ),
                    child: Icon(icon, color: selected ? _gold : Theme.of(context).colorScheme.onSurfaceVariant, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
                    color: selected ? _gold : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
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

  // ignore: unused_element
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

  // ignore: unused_element
  String _clockLabel(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  // ignore: unused_element
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

  Future<void> _copyDailyInspiration(
    ({String text, String source, int surahId, int verse}) inspiration,
  ) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: '${inspiration.text}\n${inspiration.source}'),
      );
      if (mounted) _notice('تم نسخ قبس اليوم مع مصدره');
    } catch (_) {
      if (mounted) _notice('تعذّر نسخ قبس اليوم');
    }
  }

  Future<void> _shareDailyInspiration(
    ({String text, String source, int surahId, int verse}) inspiration,
  ) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'قبس اليوم من ميثاق المؤمن',
          text: '${inspiration.text}\n${inspiration.source}\n\nمن تطبيق ميثاق المؤمن',
        ),
      );
    } catch (_) {
      if (mounted) _notice('تعذّرت مشاركة قبس اليوم');
    }
  }

  Future<void> _openDailyInspiration(
    ({String text, String source, int surahId, int verse}) inspiration,
  ) async {
    try {
      final raw = await rootBundle.loadString('assets/quran/chapters.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rawChapters = decoded['chapters'] as List<dynamic>;
      SurahInfo? match;
      for (final rawChapter in rawChapters) {
        if (rawChapter is! Map<String, dynamic>) continue;
        final chapter = SurahInfo.fromJson(rawChapter);
        if (chapter.id == inspiration.surahId) {
          match = chapter;
          break;
        }
      }
      if (!mounted) return;
      if (match == null) {
        _notice('تعذّر العثور على السورة في فهرس القرآن المحلي');
        return;
      }
      _pushPage(
        SurahReaderPage(surah: match, initialVerse: inspiration.verse),
      );
    } catch (_) {
      if (mounted) _notice('تعذّر فتح الآية من القرآن المحلي');
    }
  }

  Widget _homePage() {
    final dayOfYear = DateTime(_now.year, _now.month, _now.day)
        .difference(DateTime(_now.year, 1, 1)).inDays;
    final dailyTask = _dailyTasks[dayOfYear % _dailyTasks.length];
    final inspiration = _dailyInspirations[(dayOfYear + _inspirationOffset) % _dailyInspirations.length];
    final occasion = hijriOccasionLabel(_now, correction: _hijriCorrection);
    final prayerTimes = SolarPrayerTimes.forDate(
      _now, _prayerCity.latitude, _prayerCity.longitude, 3.0,
    );
    final nextPrayer = _nextPrayer(prayerTimes, _now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // The two calendars are integrated into the atmospheric home background,
        // rather than being presented as a separate date card.
        Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _gold.withValues(alpha: .30)),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF245A43),
                Color(0xFF102F25),
                Color(0xFF071713),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _emerald.withValues(alpha: .15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -18,
                bottom: -24,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 150,
                  color: _gold.withValues(alpha: .075),
                ),
              ),
              Positioned(
                left: 22,
                top: 4,
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: _gold.withValues(alpha: .55),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MithaqBrandMark(size: 42),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ميثاق المؤمن',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'درب العبادة والطمأنينة',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.nights_stay_outlined, color: _gold.withValues(alpha: .8)),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'التاريخ الهجري',
                    style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hijriDateLabel(_now, correction: _hijriCorrection),
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: _muted),
                      const SizedBox(width: 7),
                      Text(
                        _gregorianLabel(_now),
                        style: const TextStyle(color: Color(0xFFD8E3DC), fontSize: 13),
                      ),
                    ],
                  ),
                  if (occasion != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold.withValues(alpha: .18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available_rounded, size: 15, color: _gold),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              occasion,
                              style: const TextStyle(color: Color(0xFFF0DDAF), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withValues(alpha: .24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: _gold, size: 22),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'مواقيت الصلاة',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${_prayerCity.name} • تقديري',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _emerald.withValues(alpha: .35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: _gold, size: 25),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الصلاة القادمة', style: TextStyle(color: _muted, fontSize: 11)),
                          const SizedBox(height: 3),
                          Text(
                            nextPrayer.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'المتبقي ${_countdownLabel(nextPrayer.at, _now)}',
                            style: const TextStyle(color: _gold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _clockLabel(nextPrayer.at),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => setState(() => _selected = 3),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('عرض مواقيت الصلوات الخمس'),
                  style: TextButton.styleFrom(foregroundColor: _gold),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'الأوقات حسابية تقريبية؛ اعتمد جدول مكتب مرجعك عند اختلاف الموعد.',
                style: TextStyle(color: _muted, fontSize: 10, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withValues(alpha: .27)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _gold, size: 21),
                  SizedBox(width: 8),
                  Text('قبس اليوم', style: TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w800)),
                  Spacer(),
                  Icon(Icons.format_quote_rounded, color: Color(0x668AC5A8), size: 28),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                inspiration.text,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 20, height: 1.8, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: _muted, size: 15),
                  const SizedBox(width: 6),
                  Expanded(child: Text(inspiration.source, style: const TextStyle(color: _muted, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final openVerseButton = TextButton.icon(
                    onPressed: () => _openDailyInspiration(inspiration),
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('افتح الآية'),
                    style: TextButton.styleFrom(
                      foregroundColor: _gold,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                  final verseActions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'قبس آخر',
                        onPressed: () => setState(() {
                          _inspirationOffset = (_inspirationOffset + 1) % _dailyInspirations.length;
                        }),
                        icon: const Icon(Icons.refresh_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'نسخ قبس اليوم',
                        onPressed: () => _copyDailyInspiration(inspiration),
                        icon: const Icon(Icons.copy_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'مشاركة قبس اليوم',
                        onPressed: () => _shareDailyInspiration(inspiration),
                        icon: const Icon(Icons.share_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
                  if (constraints.maxWidth < 310) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: openVerseButton,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: verseActions,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      openVerseButton,
                      const Spacer(),
                      verseActions,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ابدأ وردك',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _homeShortcut(
                icon: Icons.menu_book_rounded,
                title: 'القرآن الكريم',
                subtitle: 'تلاوة وتدبّر',
                onTap: () => setState(() => _selected = 1),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _homeShortcut(
                icon: Icons.volunteer_activism_rounded,
                title: 'الأدعية',
                subtitle: 'أدعية وزيارات • 6 أقسام',
                onTap: () => setState(() => _selected = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 410 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: columns == 2 ? 1.22 : 1.02,
              children: [
                _homeMiniShortcut(
                  Icons.explore_rounded, 'اتجاه القبلة',
                  () => _pushPage(QiblaPage(onLocationChanged: _handleLocationChanged)),
                ),
                _homeMiniShortcut(
                  Icons.fingerprint_rounded, 'التسبيح',
                  () => _pushPage(const TasbeehPage()),
                ),
                _homeMiniShortcut(
                  Icons.shield_moon_rounded, 'حصن الأذكار',
                  () => _pushPage(const DhikrFortressPage()),
                ),
                _homeMiniShortcut(
                  Icons.handshake_rounded, 'الأعمال الصالحة',
                  () => _pushPage(const GoodDeedsPage()),
                ),
                _homeMiniShortcut(
                  Icons.bookmark_added_rounded, 'الختمة',
                  () => _pushPage(const KhatmaPage()),
                ),
                _homeMiniShortcut(
                  Icons.event_note_rounded, 'التقويم الهجري',
                  () => _pushPage(PrayerCalendarPage(
                    initialTab: 2,
                    onLocationChanged: _handleLocationChanged,
                    onHijriCorrectionChanged: _loadDashboardData,
                  )),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _emerald.withValues(alpha: .42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: .19),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.wb_twilight_rounded, color: _gold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وِرد اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 2),
                        Text('أعمال تتجدّد كل يوم', style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    _dailyTaskDone ? 'أُنجز' : 'عمل اليوم',
                    style: TextStyle(color: _dailyTaskDone ? _gold : _muted, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              _dailyDhikrRow(Icons.check_circle_outline_rounded, 'الحوقلة', 'لا حول ولا قوة إلا بالله'),
              _dailyDhikrRow(Icons.favorite_border_rounded, 'الاستغفار', 'أستغفر الله وأتوب إليه'),
              _dailyDhikrRow(Icons.spa_outlined, 'الصلاة على محمد وآل محمد', 'اللهم صلِّ على محمد وآل محمد'),
              const Divider(height: 20, color: Color(0x224EB58B)),
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _dailyTaskDone,
                  onChanged: (value) => _toggleDailyTask(value ?? false),
                  activeColor: _emerald,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('عمل اليوم المختار', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(dailyTask, style: const TextStyle(color: _muted, height: 1.6)),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'تتغيّر الأعمال المقترحة تلقائياً مع تغيّر اليوم، وتُحفظ علامة إنجاز العمل المختار لكل يوم.',
                style: TextStyle(color: _muted, fontSize: 11, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _homeShortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF17382C), Color(0xFF0B1C16), Color(0xFF10251E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: .28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: .18)),
                ),
                child: Icon(icon, color: _gold, size: 25),
              ),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.3)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _homeMiniShortcut(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF143126), Color(0xFF0D211A)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _gold.withValues(alpha: .20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: .16)),
                ),
                child: Icon(icon, color: _gold, size: 23),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailyDhikrRow(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _gold, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _duaPage() => const ShiaTextLibraryPage();

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
              color: Theme.of(context).colorScheme.surface,
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
                  backgroundColor: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.surface,
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
  late final List<String> _filters = dailyDhikr.map((item) => item.title).toList(growable: false);

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
    color: Theme.of(context).colorScheme.surface,
    margin: const EdgeInsets.symmetric(vertical: 5),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Colors.white.withValues(alpha: .055)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 8, 16, 8),
      minLeadingWidth: 46,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: .12)),
        ),
        child: Icon(icon, color: _gold, size: 23),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, height: 1.45),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, height: 1.45, fontSize: 12),
        ),
      ),
      trailing: const Icon(Icons.chevron_left_rounded, color: _gold, size: 23),
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
          color: Theme.of(context).colorScheme.surface,
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
          icon: Icons.menu_book_rounded,
          title: 'الصحيفة السجادية والمناجيات',
          subtitle: 'أدعية الإمام السجاد عليه السلام والمناجيات',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الصحيفة السجادية والمناجيات')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.today_rounded,
          title: 'الأدعية والأذكار اليومية',
          subtitle: 'أدعية الأيام وتعقيبات الصلوات وأذكار اليوم',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الأدعية والأذكار اليومية')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.auto_awesome_rounded,
          title: 'الأدعية العامة والفرج وصاحب الزمان',
          subtitle: 'الأدعية العامة وأدعية الفرج والإمام المهدي عليه السلام',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الأدعية العامة والفرج وصاحب الزمان')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.event_available_outlined,
          title: 'الأعمال والمناسبات',
          subtitle: 'الأدعية والأعمال المرتبطة بالأيام والمواسم',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الأعمال والمناسبات')),
          )),
        ),
        _sectionCard(
          context,
          icon: Icons.temple_buddhist_rounded,
          title: 'الزيارات الشريفة',
          subtitle: 'زيارات أهل البيت عليهم السلام',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الزيارات الشريفة')),
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
            fillColor: Theme.of(context).colorScheme.surface,
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
            color: Theme.of(context).colorScheme.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.surface,
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
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withValues(alpha: .25))),
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
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: _completedPages.length / 604, minHeight: 8, backgroundColor: Theme.of(context).scaffoldBackgroundColor, color: _gold)),
              const SizedBox(height: 8),
              Material(
                color: Theme.of(context).colorScheme.surface,
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
                          color: done ? _emerald : Theme.of(context).scaffoldBackgroundColor,
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
              color: Theme.of(context).colorScheme.surface,
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
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              color: Theme.of(context).colorScheme.surface,
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
