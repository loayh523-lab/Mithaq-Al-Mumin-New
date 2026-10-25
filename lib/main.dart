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
import 'features/faith_library_pages.dart';
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
const _emerald = Color(0xFF1C8060);
const _gold = Color(0xFFD9B66D);

Color _themeMuted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

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
    final background =
        dark ? const Color(0xFF071713) : const Color(0xFFF7F5EF);
    final surface = dark ? const Color(0xFF10251E) : const Color(0xFFFFFFFF);
    final foreground =
        dark ? const Color(0xFFF5F4EC) : const Color(0xFF18352B);
    final muted =
        dark ? const Color(0xFFB2C0B7) : const Color(0xFF5D7166);
    final scheme = ColorScheme.fromSeed(
      seedColor: _emerald,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: surface,
      primary: dark ? const Color(0xFF4CA782) : const Color(0xFF267A58),
      secondary: dark ? _gold : const Color(0xFF79551F),
    ).copyWith(
      onSurface: foreground,
      onSurfaceVariant: muted,
      outlineVariant: muted.withValues(alpha: dark ? .34 : .28),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      fontFamily: 'Amiri',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .60),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .58),
        thickness: .7,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.secondary,
          side: BorderSide(
            color: scheme.secondary.withValues(alpha: .45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: scheme.primary.withValues(alpha: dark ? .28 : .12),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? _ink : const Color(0xFFF0F2EC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .80),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .70),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.secondary, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: foreground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
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
    'استغفر الله وأتوب إليه، واجعل لك وقتاً للاستغفار',
    'صلِّ على محمد وآل محمد 100 مرة',
    'اقرأ سورة الإخلاص وتدبّر معناها',
    'قدّم مساعدة لأحد من أهلك',
    'راجع صلواتك الخمس واهتم بأدائها في وقتها',
    'اقرأ تسبيح الزهراء عليها السلام بعد إحدى الصلوات',
    'اقرأ دعاءً قصيراً وتمعّن بمعناه',
    'تصدّق بما تستطيع أو اقضِ حاجة محتاج',
    'صِل رحماً أو اتصل بقريب للاطمئنان عليه',
    'اقرأ آية الكرسي بتدبّر',
    'سبّح الله واحمده وهلّله وكبّره',
    'اقرأ زيارة قصيرة لأحد أهل البيت عليهم السلام',
    'راجع عملاً صالحاً تستطيع المداومة عليه',
    'أصلح خلافاً أو اعتذر إذا أخطأت',
    'أكثر من الصلاة على محمد وآل محمد يوم الجمعة',
    'اقرأ دعاء الندبة يوم الجمعة إن تيسّر',
    'تذكّر إمام الزمان عجل الله فرجه وادعُ بتعجيل الفرج',
    'خصّص دقائق لمحاسبة النفس من دون قسوة عليها',
    'اقرأ حديثاً موثوقاً وتعلّم منه عملاً',
    'ساعد في عمل منزلي من دون انتظار طلب',
    'اقرأ شيئاً من نهج البلاغة وتدبّر حكمته',
    'أحسن إلى جار أو زميل بكلمة طيبة',
    'اختم يومك بالشكر على نعمة تتذكرها',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PrayerNotificationService.notificationTap.addListener(_handlePrayerNotificationTap);
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
    WidgetsBinding.instance.removeObserver(this);
    PrayerNotificationService.notificationTap.removeListener(_handlePrayerNotificationTap);
    _dashboardClock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh the dashboard clock and top up scheduled reminders after returning
      // from Android settings, battery saver, or a long period in the background.
      if (mounted) setState(() => _now = DateTime.now());
      _loadDashboardData();
      _refreshPrayerReminders();
    }
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

  void _handlePrayerNotificationTap() {
    final id = PrayerNotificationService.notificationTap.value;
    if (id == null) return;
    PrayerNotificationService.notificationTap.value = null;
    if (!PrayerNotificationService.isPrayerNotificationId(id) || !mounted) return;
    setState(() => _selected = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pushPage(PrayerCalendarPage(
        onLocationChanged: _handleLocationChanged,
        onHijriCorrectionChanged: _loadDashboardData,
      ));
      _notice('تم فتح مواقيت الصلاة من الإشعار');
    });
  }

  Future<void> _refreshPrayerReminders() async {
    try {
      await PrayerNotificationService.initialize();
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
        title: _selected == 0
            ? Row(
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
              )
            : Text(
                _selected == 1 ? 'المفضلة المباركة' : _selected == 2 ? 'الأقسام' : 'الإعدادات',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
        actions: [
          IconButton(
            tooltip: 'الباحث الذكي',
            onPressed: () => _pushPage(const SmartSearchPage()),
            icon: Icon(Icons.search_rounded, color: _gold),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selected,
          children: [
            _homePage(),
            _selected == 1 ? const FavoritesPage(embedded: true) : const SizedBox.shrink(),
            _selected == 2 ? _sectionsPage() : const SizedBox.shrink(),
            _selected == 3
                ? SettingsPage(onLocationChanged: _handleLocationChanged, embedded: true)
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Theme.of(context).colorScheme.secondary),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: const Icon(Icons.star_border_rounded),
              selectedIcon: Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.secondary),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: Theme.of(context).colorScheme.secondary),
              label: 'الأقسام',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: Theme.of(context).colorScheme.secondary),
              label: 'الإعدادات',
            ),

          ],
        ),
      ),
    );
  }

  Widget _sectionsPage() {
    final groups = <({String title, List<Widget> items})>[
      (
        title: 'العبادات',
        items: [
          _sectionGridItem(icon: Icons.menu_book_rounded, title: 'القرآن الكريم', onTap: () => _pushPage(const QuranIndexPage())),
          _sectionGridItem(icon: Icons.auto_awesome_rounded, title: 'الأدعية والزيارات', onTap: () => _pushPage(_duaPage())),
          _sectionGridItem(icon: Icons.shield_moon_rounded, title: 'الأذكار', onTap: () => _pushPage(const DhikrFortressPage())),
          _sectionGridItem(icon: Icons.fingerprint_rounded, title: 'التسبيح', onTap: () => _pushPage(const TasbeehPage())),
          _sectionGridItem(icon: Icons.volunteer_activism_rounded, title: 'الأعمال الصالحة', onTap: () => _pushPage(const GoodDeedsPage())),
          _sectionGridItem(icon: Icons.calculate_rounded, title: 'عداد الركعات', onTap: () => _pushPage(const RakahCounterPage())),
          _sectionGridItem(icon: Icons.history_edu_rounded, title: 'قضاء العبادات', onTap: () => _pushPage(const QadaTrackerPage())),
          _sectionGridItem(icon: Icons.event_available_rounded, title: 'متابعة الصلاة', onTap: () => _pushPage(const PrayerTrackerPage())),
        ],
      ),
      (
        title: 'الخدمات',
        items: [
          _sectionGridItem(icon: Icons.access_time_rounded, title: 'أوقات الصلاة', onTap: () => _pushPage(PrayerCalendarPage(onLocationChanged: _handleLocationChanged, onHijriCorrectionChanged: _loadDashboardData))),
          _sectionGridItem(icon: Icons.explore_rounded, title: 'اتجاه القبلة', onTap: () => _pushPage(QiblaPage(onLocationChanged: _handleLocationChanged))),
          _sectionGridItem(icon: Icons.bookmark_added_rounded, title: 'ختمة القرآن', onTap: () => _pushPage(const KhatmaPage())),
          _sectionGridItem(icon: Icons.manage_search_rounded, title: 'الباحث الذكي', onTap: () => _pushPage(const SmartSearchPage())),
          _sectionGridItem(icon: Icons.brightness_5_rounded, title: 'أسماء الله الحسنى', onTap: () => _pushPage(const NamesOfAllahPage())),
          _sectionGridItem(icon: Icons.format_quote_rounded, title: 'نهج البلاغة والحِكم', onTap: () => _pushPage(const NahjAlBalaghaPage())),
          _sectionGridItem(icon: Icons.support_agent_rounded, title: 'الخدمات الإيمانية', onTap: () => _pushPage(const FaithServicesPage())),
          _sectionGridItem(icon: Icons.info_outline_rounded, title: 'عن التطبيق والدعم', onTap: () => _pushPage(const AboutSupportPage())),
        ],
      ),
      (
        title: 'المناسبات',
        items: [
          _sectionGridItem(icon: Icons.calendar_month_rounded, title: 'أعمال المناسبات', onTap: () => _pushPage(const ShiaTextLibraryPage(initialCategory: 'الأعمال والمناسبات'))),
          _sectionGridItem(icon: Icons.location_on_rounded, title: 'زيارة الأربعين', onTap: () => _pushPage(const ArbaeenGuidePage())),
          _sectionGridItem(icon: Icons.explore_rounded, title: 'الاستخارة القرآنية', onTap: () => _pushPage(const IstikharaGuidePage())),
          _sectionGridItem(icon: Icons.mosque_rounded, title: 'الزيارات الشريفة', onTap: () => _pushPage(const ShiaTextLibraryPage(initialCategory: 'الزيارات الشريفة'))),
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [Color(0xFF163C2D), Color(0xFF0E241C)]
                  : const [Color(0xFFE7F0E5), Color(0xFFF6F4EC)],
            ),
            border: Border.all(color: _gold.withValues(alpha: .18)),
          ),
          child: Text(
            'خدمات ميثاق المؤمن مرتبة حسب العبادة والمعرفة والمناسبات',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < groups.length; index++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(
              groups[index].title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700
                ? 5
                : MediaQuery.sizeOf(context).width >= 480
                    ? 4
                    : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 4,
            childAspectRatio: .90,
            children: groups[index].items,
          ),
          if (index < groups.length - 1) ...[
            const SizedBox(height: 4),
            Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .65), height: 18),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _sectionGridItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark ? .22 : .12,
                  ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .24),
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 34,
            child: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

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
                    SizedBox(width: 13),
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
                              color: _themeMuted(context),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
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
                      Icon(Icons.auto_awesome_rounded, color: _gold, size: 17),
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
                _drawerSectionTitle('العبادات', Icons.spa_rounded),
                _drawerGrid(
                  children: [
                    _drawerGridItem(Icons.auto_stories_rounded, 'القرآن الكريم', () => _openDrawerPage(const QuranIndexPage())),
                    _drawerGridItem(Icons.volunteer_activism_rounded, 'الأدعية والزيارات', () => _openDrawerPage(_duaPage())),
                    _drawerGridItem(Icons.fingerprint_rounded, 'التسبيح', () => _openDrawerPage(const TasbeehPage())),
                    _drawerGridItem(Icons.handshake_rounded, 'الأعمال الصالحة', () => _openDrawerPage(const GoodDeedsPage())),
                    _drawerGridItem(Icons.shield_moon_rounded, 'حصن الأذكار', () => _openDrawerPage(const DhikrFortressPage())),
                    _drawerGridItem(Icons.calculate_rounded, 'عداد الركعات', () => _openDrawerPage(const RakahCounterPage())),
                  ],
                ),
                SizedBox(height: 8),
                _drawerSectionTitle('الخدمات والمتابعة', Icons.grid_view_rounded),
                _drawerGrid(
                  children: [
                    _drawerGridItem(Icons.home_rounded, 'الرئيسية', () => _selectTab(0), selected: _selected == 0),
                    _drawerGridItem(Icons.access_time_rounded, 'مواقيت الصلاة', () => _openDrawerPage(PrayerCalendarPage(onLocationChanged: _handleLocationChanged, onHijriCorrectionChanged: _loadDashboardData))),
                    _drawerGridItem(Icons.explore_rounded, 'اتجاه القبلة', () => _openDrawerPage(QiblaPage(onLocationChanged: _handleLocationChanged))),
                    _drawerGridItem(Icons.bookmark_added_rounded, 'ختمة القرآن', () => _openDrawerPage(const KhatmaPage())),
                    _drawerGridItem(Icons.event_available_rounded, 'متابعة الصلاة', () => _openDrawerPage(const PrayerTrackerPage())),
                    _drawerGridItem(Icons.history_edu_rounded, 'قضاء العبادات', () => _openDrawerPage(const QadaTrackerPage())),
                  ],
                ),
                SizedBox(height: 8),
                _drawerSectionTitle('المعرفة والمناسبات', Icons.local_library_rounded),
                _drawerGrid(
                  children: [
                    _drawerGridItem(Icons.calendar_month_rounded, 'التقويم الهجري', () => _openDrawerPage(PrayerCalendarPage(initialTab: 2, onLocationChanged: _handleLocationChanged, onHijriCorrectionChanged: _loadDashboardData))),
                    _drawerGridItem(Icons.brightness_5_rounded, 'أسماء الله الحسنى', () => _openDrawerPage(const NamesOfAllahPage())),
                    _drawerGridItem(Icons.manage_search_rounded, 'الباحث الذكي', () => _openDrawerPage(const SmartSearchPage())),
                    _drawerGridItem(Icons.format_quote_rounded, 'نهج البلاغة والحِكم', () => _openDrawerPage(const NahjAlBalaghaPage())),
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
                Expanded(child: _drawerBottomItem(Icons.star_rounded, 'المفضلة', () => _selectTab(1))),
                SizedBox(width: 10),
                Expanded(child: _drawerBottomItem(Icons.tune_rounded, 'الإعدادات', () => _selectTab(3))),
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
            child: Row(
              children: [
                Icon(Icons.security_rounded, color: _gold, size: 17),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نسخة قيد التطوير • راجع المصادر عند الحاجة',
                    style: TextStyle(color: _themeMuted(context), fontSize: 10, height: 1.45),
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
    childAspectRatio: .80,
    children: children,
  );

  Color _drawerAccent(String title) {
    const worshipAndText = <String>{
      'الأدعية والزيارات',
      'الأدعية',
      'التسبيح',
      'الأعمال الصالحة',
      'قضاء العبادات',
      'عداد الركعات',
      'حصن الأذكار',
      'أسماء الله الحسنى',
    };
    final scheme = Theme.of(context).colorScheme;
    return worshipAndText.contains(title) ? scheme.secondary : scheme.primary;
  }

  Widget _drawerGridItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool selected = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _drawerAccent(title);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: isDark ? .20 : .09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            border: selected
                ? Border.all(
                    color: scheme.secondary.withValues(alpha: .58),
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? .20 : .12),
                  border: Border.all(
                    color: accent.withValues(alpha: selected ? .75 : .34),
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
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
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: _gold,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .1,
          ),
        ),
      ],
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
    final hijriParts = hijriDateParts(_now, correction: _hijriCorrection);
    final hijriDayIndex = ((hijriParts.month - 1) * 30) + hijriParts.day - 1;
    final dailyTask = _dailyTasks[hijriDayIndex % _dailyTasks.length];
    final inspiration = _dailyInspirations[(dayOfYear + _inspirationOffset) % _dailyInspirations.length];
    final occasion = hijriOccasionLabel(_now, correction: _hijriCorrection);
    final prayerTimes = SolarPrayerTimes.forDate(
      _now, _prayerCity.latitude, _prayerCity.longitude, 3.0,
    );
    final nextPrayer = _nextPrayer(prayerTimes, _now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // Transparent date header: the calendar belongs to the page background,
        // not to a separate card or boxed panel.
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 20),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                bottom: 2,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 126,
                  color: scheme.secondary.withValues(alpha: isDark ? .055 : .07),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MithaqBrandMark(size: 42),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ميثاق المؤمن',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'درب العبادة والطمأنينة',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.nights_stay_outlined,
                        color: _gold.withValues(alpha: .8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hijriDateLabel(_now, correction: _hijriCorrection),
                    style: TextStyle(
                      color: scheme.secondary,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: _themeMuted(context),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _gregorianLabel(_now),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (occasion != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 16,
                          color: _gold,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            occasion,
                            style: TextStyle(
                              color: scheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
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
                  Icon(Icons.access_time_filled_rounded, color: _gold, size: 22),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'مواقيت الصلاة',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${_prayerCity.name} • تقديري',
                    style: TextStyle(color: _themeMuted(context), fontSize: 10),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _emerald.withValues(alpha: .35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: _gold, size: 25),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الصلاة القادمة', style: TextStyle(color: _themeMuted(context), fontSize: 11)),
                          SizedBox(height: 3),
                          Text(
                            nextPrayer.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'المتبقي ${_countdownLabel(nextPrayer.at, _now)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _clockLabel(nextPrayer.at),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.secondary),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => _pushPage(PrayerCalendarPage(
                    onLocationChanged: _handleLocationChanged,
                    onHijriCorrectionChanged: _loadDashboardData,
                  )),
                  icon: Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text('عرض مواقيت الصلوات الخمس'),
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'الأوقات حسابية تقريبية؛ اعتمد جدول مكتب مرجعك عند اختلاف الموعد.',
                style: TextStyle(color: _themeMuted(context), fontSize: 10, height: 1.5),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
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
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _gold, size: 21),
                  SizedBox(width: 8),
                  Text('قبس اليوم', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 17, fontWeight: FontWeight.w800)),
                  Spacer(),
                  Icon(Icons.format_quote_rounded, color: Color(0x668AC5A8), size: 28),
                ],
              ),
              SizedBox(height: 10),
              Text(
                inspiration.text,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 20, height: 1.8, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: _themeMuted(context), size: 15),
                  SizedBox(width: 6),
                  Expanded(child: Text(inspiration.source, style: TextStyle(color: _themeMuted(context), fontSize: 12))),
                ],
              ),
              SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final openVerseButton = TextButton.icon(
                    onPressed: () => _openDailyInspiration(inspiration),
                    icon: Icon(Icons.open_in_new_rounded, size: 17),
                    label: Text('افتح الآية'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
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
                        icon: Icon(Icons.refresh_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'نسخ قبس اليوم',
                        onPressed: () => _copyDailyInspiration(inspiration),
                        icon: Icon(Icons.copy_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'مشاركة قبس اليوم',
                        onPressed: () => _shareDailyInspiration(inspiration),
                        icon: Icon(Icons.share_rounded, size: 19),
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
                      Spacer(),
                      verseActions,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        Text(
          'ابدأ وردك',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 10),
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
            SizedBox(width: 11),
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
        SizedBox(height: 10),
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
        SizedBox(height: 20),
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
                    child: Icon(Icons.wb_twilight_rounded, color: _gold, size: 22),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وِرد اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 2),
                        Text('عمل يتجدّد بحسب التاريخ الهجري', style: TextStyle(color: _themeMuted(context), fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    _dailyTaskDone ? 'أُنجز' : 'عمل اليوم',
                    style: TextStyle(color: _dailyTaskDone ? _gold : _themeMuted(context), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SizedBox(height: 13),
              _dailyDhikrRow(Icons.check_circle_outline_rounded, 'الحوقلة', 'لا حول ولا قوة إلا بالله'),
              _dailyDhikrRow(Icons.favorite_border_rounded, 'الاستغفار', 'أستغفر الله وأتوب إليه'),
              _dailyDhikrRow(Icons.spa_outlined, 'الصلاة على محمد وآل محمد', 'اللهم صلِّ على محمد وآل محمد'),
              Divider(height: 20, color: Color(0x224EB58B)),
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _dailyTaskDone,
                  onChanged: (value) => _toggleDailyTask(value ?? false),
                  activeColor: _emerald,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('عمل اليوم الهجري', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(dailyTask, style: TextStyle(color: _themeMuted(context), height: 1.6)),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'يتغيّر العمل المقترح بحسب اليوم الهجري بعد تطبيق تصحيح التاريخ، وتُحفظ علامة الإنجاز لكل يوم ميلادي حتى لا تضيع متابعة إنجازك.',
                style: TextStyle(color: _themeMuted(context), fontSize: 11, height: 1.6),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _drawerAccent(title);
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
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF17382C),
                      Color(0xFF0B1C16),
                      Color(0xFF10251E),
                    ]
                  : const [
                      Color(0xFFFFFFFF),
                      Color(0xFFF3F7EF),
                      Color(0xFFE8F0E6),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? .32 : .30),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? .08 : .07),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? .20 : .12),
                  border: Border.all(color: accent.withValues(alpha: .40)),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(height: 13),
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeMiniShortcut(IconData icon, String title, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _drawerAccent(title);
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
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? .25 : .24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? .20 : .12),
                  border: Border.all(color: accent.withValues(alpha: .36)),
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
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
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(height: 2),
                Text(text, style: TextStyle(color: _themeMuted(context), fontSize: 12)),
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
        _count = (prefs.getInt('tasbeeh_zahra_count') ?? 0)
            .clamp(0, _steps[_step].target);
        _generalCount = (prefs.getInt('tasbeeh_general_count') ?? 0)
            .clamp(0, 2147483647);
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
    final progress = target == null ? 0.0 : (current / target).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dialSize = (MediaQuery.sizeOf(context).width * .42).clamp(132.0, 164.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التسبيح'),
        actions: [
          IconButton(
            tooltip: 'إعادة العداد',
            onPressed: _loading ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: theme.brightness == Brightness.dark
                      ? const [Color(0xFF18392B), Color(0xFF111A15)]
                      : const [Color(0xFFE8F1E6), Color(0xFFF7F3E8)],
                ),
                border: Border.all(color: _gold.withValues(alpha: .22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: _gold, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _zahraMode ? 'تسبيح الزهراء عليها السلام' : 'المسبحة المفتوحة',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _zahraMode
                              ? '34 تكبيرة، ثم 33 تحميدة، ثم 33 تسبيحة'
                              : 'عداد مستقل لحساب الذكر الذي تختاره',
                          style: TextStyle(fontSize: 12, height: 1.45, color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('تسبيح الزهراء'),
                  icon: Icon(Icons.auto_awesome_rounded),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('تسبيح عام'),
                  icon: Icon(Icons.fingerprint_rounded),
                ),
              ],
              selected: {_zahraMode},
              onSelectionChanged: _loading ? null : (selection) => _setMode(selection.first),
            ),
            if (_zahraMode) ...[
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مراحل التسبيح',
                        style: TextStyle(color: _gold, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _steps.length; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 8),
                          child: Row(
                            children: [
                              Icon(
                                i < _step || (i == _step && _count >= _steps[i].target)
                                    ? Icons.check_circle_rounded
                                    : i == _step
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                color: i == _step ? _gold : colors.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '${_steps[i].title}: ${_steps[i].phrase}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 14,
                                    fontWeight: i == _step ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${i == _step ? _count : i < _step ? _steps[i].target : 0}/${_steps[i].target}',
                                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: _gold.withValues(alpha: .28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  children: [
                    Text(
                      _zahraMode
                          ? (_step == 2 && _count >= 33 ? 'اكتمل تسبيح الزهراء' : step.phrase)
                          : 'اضغط على المسبحة لزيادة العدد',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.45,
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current.toString(),
                      style: TextStyle(
                        fontSize: 44,
                        height: 1.1,
                        color: _gold,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_zahraMode) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: colors.surfaceContainerHighest,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'المرحلة ${_step + 1} من 3  •  المطلوب ${step.target}',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Center(
                      child: Semantics(
                        button: true,
                        label: 'زيادة عداد التسبيح',
                        child: InkWell(
                          onTap: _loading || (_zahraMode && _step == 2 && _count >= 33)
                              ? null
                              : _increment,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: dialSize,
                            height: dialSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF17231B)
                                  : const Color(0xFFF2F5EC),
                              border: Border.all(color: _gold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _emerald.withValues(alpha: .14),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fingerprint_rounded, color: _gold, size: dialSize * .34),
                                  const SizedBox(height: 2),
                                  Text(
                                    _zahraMode && _step == 2 && _count >= 33 ? 'تمّ' : 'سبّح',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _zahraMode && _step == 2 && _count >= 33
                          ? 'تقبّل الله طاعتكم'
                          : 'اضغط على الدائرة للتسبيح',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.45, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _reset,
                          icon: const Icon(Icons.restart_alt_rounded, size: 19),
                          label: const Text('إعادة من البداية'),
                        ),
                        if (_zahraMode && _step > 0)
                          OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _step--;
                                      _count = 0;
                                    });
                                    _persist();
                                  },
                            icon: const Icon(Icons.undo_rounded, size: 19),
                            label: const Text('المرحلة السابقة'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يُحفظ العداد على هذا الجهاز. يمكنك التبديل بين تسبيح الزهراء عليها السلام والعداد العام دون خلط العددين.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.6, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
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
        style: TextStyle(fontWeight: FontWeight.w800, height: 1.45),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _themeMuted(context), height: 1.45, fontSize: 12),
        ),
      ),
      trailing: Icon(Icons.chevron_left_rounded, color: _gold, size: 23),
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
        Text('الأدعية والأذكار', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text('الأدعية والأذكار والمكتبة الشيعية', style: TextStyle(color: _themeMuted(context))),
        SizedBox(height: 14),
        Card(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(0x223CB58B), child: Icon(Icons.menu_book_rounded, color: _gold)),
            title: Text('الأدعية والزيارات والصحيفة السجادية', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('مجموعة نصوص مع البحث والعرض دون إنترنت', style: TextStyle(color: _themeMuted(context))),
            trailing: Icon(Icons.chevron_left_rounded, color: _gold),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage()),
            )),
          ),
        ),
        SizedBox(height: 16),
        Text('أقسام المكتبة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
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
        SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ابحث عن ذكر...',
            prefixIcon: Icon(Icons.search_rounded),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filters.map((filter) => ChoiceChip(
            label: Text(filter),
            selected: _filter == filter,
            onSelected: (_) => setState(() => _filter = filter),
          )).toList(),
        ),
        SizedBox(height: 16),
        if (items.isEmpty)
          Padding(padding: EdgeInsets.all(24), child: Center(child: Text('ماكو نتائج مطابقة', style: TextStyle(color: _themeMuted(context)))))
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
                      Text(item.text, style: TextStyle(fontSize: 20, height: 1.8)),
                      SizedBox(height: 16),
                      Text('المصدر / التوضيح', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text(item.source, style: TextStyle(color: _themeMuted(context))),
                      if (item.note != null) ...[
                        SizedBox(height: 8),
                        Text(item.note!, style: TextStyle(color: _themeMuted(context), height: 1.5)),
                      ],
                    ],
                  )),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق'))],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(item.title, style: TextStyle(color: _gold, fontWeight: FontWeight.bold))), Icon(Icons.open_in_new_rounded, size: 17, color: _themeMuted(context))]),
                    SizedBox(height: 10),
                    Text(item.text, style: TextStyle(fontSize: 18, height: 1.7)),
                    SizedBox(height: 8),
                    Text(item.source, style: TextStyle(fontSize: 12, color: _themeMuted(context))),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'نسخ الذكر',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.text));
                          widget.onNotice('تم نسخ الذكر');
                        },
                        icon: Icon(Icons.content_copy_rounded, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        SizedBox(height: 8),
        Text('يضم هذا القسم أذكاراً عامة ومختارات قرآنية قصيرة. لا تُعرض الصيغ العامة على أنها روايات مسندة، وتُذكر إحالة الآية حيث يكون النص قرآنيّاً.', style: TextStyle(color: _themeMuted(context), fontSize: 12, height: 1.6)),
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
        title: Text('إعادة ضبط الختمة؟'),
        content: Text('سيُعاد تقدّم الختمة إلى صفر جزء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('إعادة الضبط'),
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
        title: Text('ختمة القرآن'),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط الختمة',
            onPressed: _confirmReset,
            icon: Icon(Icons.restart_alt_rounded),
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
                Icon(Icons.auto_stories_rounded, color: _gold, size: 34),
                SizedBox(height: 16),
                Text(
                  'خطوة كل يوم',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'سجّل الأجزاء التي أكملت قراءتها، وسيبقى تقدّمك محفوظاً على هذا الجهاز.',
                  style: TextStyle(color: _themeMuted(context), height: 1.7),
                ),
                SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_completedJuz',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: _gold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10, right: 8),
                      child: Text('/ 30 جزءاً', style: TextStyle(color: _themeMuted(context))),
                    ),
                    Spacer(),
                    Text('$percent%', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _completedJuz / 30,
                    minHeight: 10,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    color: _gold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _completedJuz > 0
                            ? () => _setProgress(_completedJuz - 1)
                            : null,
                        icon: Icon(Icons.remove_rounded),
                        label: Text('إنقاص جزء'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _completedJuz < 30
                            ? () => _setProgress(_completedJuz + 1)
                            : null,
                        icon: Icon(Icons.add_rounded),
                        label: Text('إكمال جزء'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          if (_completedJuz == 30)
            ListTile(
              leading: Icon(Icons.check_circle_rounded, color: _gold),
              title: Text('تقبّل الله طاعتكم'),
              subtitle: Text('أكملت تسجيل الأجزاء الثلاثين في هذه الختمة.'),
            )
          else
            ListTile(
              leading: Icon(Icons.bookmark_outline_rounded, color: _gold),
              title: Text('الخطوة التالية'),
              subtitle: Text('بعد قراءة الجزء ${_completedJuz + 1}، حدّث تقدّمك هنا.'),
            ),
          SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withValues(alpha: .25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تتبّع الصفحات', style: TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('سجّل كل صفحة بعد قراءتها في مصحف المدينة ذي 604 صفحات. يُحسب اكتمال الجزء من الصفحات المسجّلة ضمن نطاقه.', style: TextStyle(color: _themeMuted(context), height: 1.6, fontSize: 12)),
              SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('${_completedPages.length} / 604 صفحة', style: TextStyle(color: _gold, fontWeight: FontWeight.bold))),
                Text('${(_completedPages.length / 604 * 100).round()}%', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
              ]),
              SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: _completedPages.length / 604, minHeight: 8, backgroundColor: Theme.of(context).scaffoldBackgroundColor, color: _gold)),
              SizedBox(height: 8),
              Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('اختيار الصفحات المكتملة'),
                subtitle: Text('اضغط رقم الصفحة لتسجيلها أو إلغاء تسجيلها'),
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
                            child: Center(child: Text('$page', style: TextStyle(color: done ? Colors.white : _themeMuted(context), fontSize: 11, fontWeight: done ? FontWeight.bold : FontWeight.normal))),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )),
            ]),
          ),
          SizedBox(height: 8),
          Text('أرقام الصفحات تخص مصحف المدينة ذي 604 صفحات. إذا كنت تستخدم طبعة مختلفة، اعتمد ترقيمها أو تابع الأجزاء أعلاه.', style: TextStyle(color: _themeMuted(context), fontSize: 12, height: 1.6)),
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
      appBar: AppBar(title: Text('متابعة الصلاة')),
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
                Icon(Icons.volunteer_activism_rounded, color: _gold, size: 34),
                SizedBox(height: 14),
                Text('صلوات اليوم', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('علّم الصلاة بعد أدائها. السجلّ يُحفظ لهذا اليوم على جهازك.', style: TextStyle(color: _themeMuted(context), height: 1.7)),
                SizedBox(height: 20),
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
                    SizedBox(width: 12),
                    Text('${_completed.length}/5', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (!_loaded)
            Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
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
                  color: _completed.contains(prayer) ? _gold : _themeMuted(context),
                ),
                title: Text(prayer, style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _completed.contains(prayer) ? 'تم تسجيلها' : 'لم تُسجّل بعد',
                  style: TextStyle(color: _themeMuted(context)),
                ),
              ),
            ))),
          SizedBox(height: 8),
          Text('هذا سجلّ شخصي لمتابعة أداء الصلوات، وليس جدولاً للمواقيت. افتح قسم «المواقيت والتقويم» لمشاهدة الأوقات التقديرية، وقارنها بجدول مكتب مرجعك.', style: TextStyle(color: _themeMuted(context), fontSize: 12, height: 1.7)),
        ],
      ),
    );
  }
}
