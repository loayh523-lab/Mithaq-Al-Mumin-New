import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/religious_content.dart';
import 'quran/quran_pages.dart';
import 'features/prayer_calendar_page.dart';
import 'features/qibla_page.dart';
import 'features/settings_page.dart';
import 'features/mafatih_library_page.dart';
import 'features/shia_text_library_page.dart';
import 'services/prayer_locations.dart';
import 'services/prayer_notification_service.dart';

void main() => runApp(const MithaqApp());

const _ink = Color(0xFF071713);
const _panel = Color(0xFF10251E);
const _emerald = Color(0xFF1C8060);
const _gold = Color(0xFFD9B66D);
const _muted = Color(0xFF9EB5A9);

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
  int _count = 0;

  static const _titles = ['الرئيسية', 'القرآن الكريم', 'الأدعية والزيارات', 'التسبيح', 'الإعدادات'];
  static const _icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.auto_awesome_rounded,
    Icons.fingerprint_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _restoreCounter();
    _refreshPrayerReminders();
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

  Future<void> _restoreCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _count = prefs.getInt('tasbeeh_count') ?? 0);
    } catch (_) {
      // Keep the counter usable even if local storage is unavailable.
    }
  }

  Future<void> _saveCounter(int value) async {
    setState(() => _count = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tasbeeh_count', value);
    } catch (_) {
      if (mounted) _notice('تعذّر حفظ العدّاد على الجهاز');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: PrayerCalendarPage()))),
            tooltip: 'المواقيت والتقويم',
            icon: const Icon(Icons.calendar_month_rounded),
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
            const SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _panel,
        indicatorColor: _emerald.withValues(alpha: .35),
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: List.generate(_titles.length, (i) => NavigationDestination(
          icon: Icon(_icons[i]),
          label: _titles[i],
        )),
      ),
    );
  }

  Widget _homePage() => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF174C3A), Color(0xFF0D2820), Color(0xFF102019)],
          ),
          border: Border.all(color: _gold.withValues(alpha: .3)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', style: TextStyle(color: _gold, fontSize: 17)),
            SizedBox(height: 18),
            Text('ميثاقٌ يتجدّد', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('مساحة هادئة للقرآن والدعاء والذكر', style: TextStyle(color: _muted, fontSize: 14)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text('الوصول السريع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: [
          _featureCard(Icons.menu_book_rounded, 'القرآن الكريم', 'المصحف والفهرس', () => setState(() => _selected = 1)),
          _featureCard(Icons.auto_awesome_rounded, 'الأدعية والزيارات', 'مكتبة المصادر', () => setState(() => _selected = 2)),
          _featureCard(Icons.fingerprint_rounded, 'التسبيح', 'عداد الذكر', () => setState(() => _selected = 3)),
          _featureCard(Icons.auto_stories_rounded, 'ختمة القرآن', 'حفظ تقدّم الختمة', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: KhatmaPage())))),
          _featureCard(Icons.checklist_rounded, 'متابعة الصلاة', 'سجلّ صلوات اليوم', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: PrayerTrackerPage())))),
          _featureCard(Icons.explore_rounded, 'المواقيت والتقويم', 'الصلاة والتاريخ الهجري والإمساكية', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: PrayerCalendarPage())))),
          _featureCard(Icons.explore_rounded, 'اتجاه القبلة', 'بوصلة الجهاز الحية', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: QiblaPage())))),
        ],
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20)),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_outlined, color: _gold),
            SizedBox(width: 12),
            Expanded(child: Text('نعتمد النصوص الموثّقة والمصادر الواضحة، ولا نعرض مواقيت أو نصوصاً غير متحقَّق منها.', style: TextStyle(color: _muted, height: 1.6))),
          ],
        ),
      ),
    ],
  );

  Widget _featureCard(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _gold, size: 25),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _duaPage() => _DuaLibrary(onNotice: _notice);

  Widget _tasbeehPage() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fingerprint_rounded, size: 48, color: _gold),
          const SizedBox(height: 12),
          const Text('التسبيح', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('اضغط على الدائرة لزيادة العدّاد', style: TextStyle(color: _muted)),
          const SizedBox(height: 28),
          Semantics(
            button: true,
            label: 'زيادة عدّاد التسبيح',
            child: InkWell(
              onTap: () => _saveCounter(_count + 1),
              customBorder: const CircleBorder(),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _panel, border: Border.all(color: _gold, width: 2), boxShadow: [BoxShadow(color: _emerald.withValues(alpha: .2), blurRadius: 30, spreadRadius: 5)]),
                child: Center(child: Text('$_count', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: _gold))),
              ),
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _saveCounter(0),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تصفير العدّاد'),
          ),
        ],
      ),
    ),
  );


  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
  String _filter = 'الكل';
  static const _filters = ['الكل', 'الاستغفار', 'الصلاة على محمد وآل محمد', 'التسبيح'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final items = dailyDhikr.where((item) {
      final matchesQuery = query.isEmpty || item.title.contains(query) || item.text.contains(query);
      final matchesFilter = _filter == 'الكل' || item.title == _filter;
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
  int _completedJuz = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _completedJuz = (prefs.getInt('khatma_completed_juz') ?? 0)
            .clamp(0, 30)
            .toInt();
      });
    } catch (_) {
      // Progress can still be changed for this session.
    }
  }

  Future<void> _setProgress(int value) async {
    final next = value.clamp(0, 30).toInt();
    setState(() => _completedJuz = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('khatma_completed_juz', next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ التقدّم على الجهاز')),
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
          const SizedBox(height: 8),
          const Text(
            'هذا سجلّ للتقدّم فقط؛ لا يحدّد موضع القراءة داخل الجزء.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
          ),
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
