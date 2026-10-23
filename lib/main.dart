import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/prayer_calendar_page.dart';

void main() => runApp(const MithaqApp());

const emerald = Color(0xFF287A59);
const gold = Color(0xFFC5A66A);
const darkBg = Color(0xFF0A1511);
const darkPanel = Color(0xFF12241C);
const lightBg = Color(0xFFF6F3E9);
const lightPanel = Color(0xFFFFFDF7);

class MithaqApp extends StatefulWidget {
  const MithaqApp({super.key});
  @override
  State<MithaqApp> createState() => _MithaqAppState();
}

class _MithaqAppState extends State<MithaqApp> {
  bool light = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => light = p.getBool('mithaq_light_theme') ?? false);
    });
  }

  Future<void> changeTheme(bool value) async {
    setState(() => light = value);
    final p = await SharedPreferences.getInstance();
    await p.setBool('mithaq_light_theme', value);
  }

  ThemeData makeTheme(bool isLight) {
    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald,
        brightness: isLight ? Brightness.light : Brightness.dark,
        surface: isLight ? lightPanel : darkPanel,
      ),
      scaffoldBackgroundColor: isLight ? lightBg : darkBg,
      fontFamily: 'NotoNaskhArabic',
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? lightBg : darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isLight ? lightPanel : darkPanel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: isLight ? const Color(0xFFE4E0D3) : const Color(0xFF263D31)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? lightPanel : const Color(0xFF0E1D16),
        indicatorColor: emerald.withOpacity(.18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ميثاق المؤمن',
    debugShowCheckedModeBanner: false,
    theme: makeTheme(true),
    darkTheme: makeTheme(false),
    themeMode: light ? ThemeMode.light : ThemeMode.dark,
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
    home: MainShell(isLight: light, onThemeChanged: changeTheme),
  );
}

class MainShell extends StatefulWidget {
  final bool isLight;
  final ValueChanged<bool> onThemeChanged;
  const MainShell({super.key, required this.isLight, required this.onThemeChanged});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  static const labels = ['الرئيسية', 'القرآن', 'المكتبة', 'العبادة'];
  static const icons = [Icons.home_rounded, Icons.menu_book_rounded, Icons.auto_awesome_rounded, Icons.spa_rounded];

  void openSection(String name) {
    Navigator.pop(context);
    if (name == 'الإعدادات') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(isLight: widget.isLight, onThemeChanged: widget.onThemeChanged)));
    } else if (name == 'مواقيت الصلاة' || name == 'التقويم') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerCalendarPage()));
    } else if (name == 'المفضلة') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'المفضلة', icon: Icons.favorite_border_rounded, subtitle: 'مكان موحد للمحتوى الذي تحفظه.')));
    } else if (name == 'القرآن الكريم') {
      setState(() => selected = 1);
    } else if (name == 'الأدعية والزيارات' || name == 'البحث والمكتبة') {
      setState(() => selected = 2);
    } else {
      setState(() => selected = 3);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        Icon(Icons.spa_rounded, color: gold, size: 25),
        SizedBox(width: 9),
        Text('ميثاق المؤمن', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ]),
      actions: [
        IconButton(tooltip: 'البحث', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'البحث والمكتبة', icon: Icons.search_rounded, subtitle: 'بحث موحد في القرآن والأدعية والزيارات.'))), icon: const Icon(Icons.search_rounded)),
        Builder(builder: (ctx) => IconButton(tooltip: 'القائمة', onPressed: () => Scaffold.of(ctx).openDrawer(), icon: const Icon(Icons.grid_view_rounded))),
        const SizedBox(width: 5),
      ],
    ),
    drawer: AppDrawer(isLight: widget.isLight, onThemeChanged: widget.onThemeChanged, onSelect: openSection),
    body: IndexedStack(index: selected, children: [
      HomePage(onOpen: openSection),
      const SimplePage(title: 'القرآن الكريم', icon: Icons.menu_book_rounded, subtitle: 'القراءة والبحث والإشارات المرجعية.'),
      const SimplePage(title: 'الأدعية والزيارات', icon: Icons.auto_awesome_rounded, subtitle: 'مكتبة مرتبة حسب نوع الدعاء والزيارة والمناسبة.'),
      const SimplePage(title: 'أقسام العبادة', icon: Icons.spa_rounded, subtitle: 'التسبيح والختمة ومتابعة الصلاة والقضاء وحصن الأذكار.'),
    ]),
    bottomNavigationBar: NavigationBar(
      height: 68,
      selectedIndex: selected,
      onDestinationSelected: (i) => setState(() => selected = i),
      destinations: List.generate(labels.length, (i) => NavigationDestination(
        icon: Icon(icons[i], size: 22),
        selectedIcon: Icon(icons[i], color: gold, size: 23),
        label: labels[i],
      )),
    ),
  );
}

class HomePage extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const HomePage({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final text = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
      Text('السلام عليك', style: TextStyle(color: muted, fontSize: 13)),
      const SizedBox(height: 2),
      Text('حيّاك الله', style: TextStyle(fontSize: 26, height: 1.5, fontWeight: FontWeight.w800, color: text)),
      const SizedBox(height: 15),
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onOpen('التقويم'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFEBF0E6) : const Color(0xFF142A20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 52,
              decoration: BoxDecoration(color: emerald.withOpacity(.12), borderRadius: BorderRadius.circular(13)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(now.day.toString(), style: const TextStyle(fontSize: 21, color: emerald, fontWeight: FontWeight.w800)),
                Text(_monthName(now.month), style: const TextStyle(fontSize: 9, color: emerald)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('التاريخ الهجري والميلادي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_weekday(now.weekday) + ' • ' + now.year.toString() + '/' + now.month.toString() + '/' + now.day.toString(), style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 3),
              Text('اضغط لفتح التقويم والمناسبات', style: TextStyle(color: muted, fontSize: 11)),
            ])),
            Icon(Icons.chevron_left_rounded, color: muted),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => onOpen('مواقيت الصلاة'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: isLight ? const [Color(0xFFE2EEE3), Color(0xFFF8F8F0)] : const [Color(0xFF1C4B35), Color(0xFF10251B)]),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: emerald.withOpacity(.28)),
          ),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, color: gold, size: 27),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مواقيت الصلاة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('اضغط لعرض الصلاة القادمة ومواقيت اليوم', style: TextStyle(fontSize: 11)),
            ])),
            const Icon(Icons.chevron_left_rounded),
          ]),
        ),
      ),
      const SizedBox(height: 22),
      const _Heading(title: 'وصول سريع', subtitle: 'أقسامك الأساسية بمكان واحد'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.35,
        children: const [
          _HomeShortcut(icon: Icons.menu_book_rounded, title: 'القرآن الكريم'),
          _HomeShortcut(icon: Icons.auto_awesome_rounded, title: 'الأدعية والزيارات'),
          _HomeShortcut(icon: Icons.circle_outlined, title: 'التسبيح'),
          _HomeShortcut(icon: Icons.explore_rounded, title: 'اتجاه القبلة'),
        ],
      ),
      const SizedBox(height: 20),
      Row(children: [
        const Icon(Icons.wb_twilight_rounded, color: gold, size: 20),
        const SizedBox(width: 8),
        Text('قبس اليوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: text)),
      ]),
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('وَقُل رَّبِّ زِدْنِي عِلْمًا', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, height: 1.8, color: text, fontWeight: FontWeight.w700)))),
    ]);
  }
}

class _Heading extends StatelessWidget {
  final String title, subtitle;
  const _Heading({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]);
}

class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  const _HomeShortcut({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اختيار ' + title))),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        Icon(icon, color: emerald, size: 23),
        const SizedBox(width: 9),
        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      ])),
    ),
  );
}

class AppDrawer extends StatelessWidget {
  final bool isLight;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onSelect;
  const AppDrawer({super.key, required this.isLight, required this.onThemeChanged, required this.onSelect});

  static const items = [
    ('القرآن الكريم', Icons.menu_book_rounded),
    ('الأدعية والزيارات', Icons.auto_awesome_rounded),
    ('مواقيت الصلاة', Icons.access_time_rounded),
    ('التقويم', Icons.calendar_month_rounded),
    ('التسبيح', Icons.circle_outlined),
    ('الختمة', Icons.bookmark_added_outlined),
    ('متابعة الصلاة', Icons.check_circle_outline_rounded),
    ('قضاء الصلاة', Icons.event_repeat_rounded),
    ('حصن الأذكار', Icons.shield_moon_outlined),
    ('اتجاه القبلة', Icons.explore_outlined),
    ('البحث والمكتبة', Icons.search_rounded),
  ];

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(15, 12, 15, 18), children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: emerald.withOpacity(.13), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.spa_rounded, color: gold, size: 26)),
        const SizedBox(width: 11),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ميثاق المؤمن', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text('رفيقك في العبادة والمعرفة', style: TextStyle(fontSize: 11)),
        ]),
      ]),
      const SizedBox(height: 20),
      const _Heading(title: 'الأقسام', subtitle: 'اختر القسم الذي تريد فتحه'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.55,
        children: items.map((item) => InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelect(item.$1),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(item.$2, color: emerald, size: 24),
              const SizedBox(height: 6),
              Text(item.$1, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        )).toList(),
      ),
      const SizedBox(height: 14),
      const Divider(),
      ListTile(leading: const Icon(Icons.favorite_border_rounded), title: const Text('المفضلة'), onTap: () => onSelect('المفضلة')),
      ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('الإعدادات'), onTap: () => onSelect('الإعدادات')),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: gold),
        title: const Text('المظهر الفاتح'),
        value: isLight,
        onChanged: onThemeChanged,
      ),
    ])),
  );
}

class SettingsPage extends StatelessWidget {
  final bool isLight;
  final ValueChanged<bool> onThemeChanged;
  const SettingsPage({super.key, required this.isLight, required this.onThemeChanged});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإعدادات')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const _Heading(title: 'المظهر والقراءة', subtitle: 'تفضيلات التطبيق'),
      const SizedBox(height: 12),
      Card(child: SwitchListTile(
        secondary: Icon(isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: emerald),
        title: const Text('المظهر الفاتح'),
        subtitle: Text(isLight ? 'عاجي وأخضر زمردي' : 'داكن زمردي مع لمسات ذهبية'),
        value: isLight, onChanged: onThemeChanged,
      )),
      const Card(child: ListTile(leading: Icon(Icons.text_fields_rounded), title: Text('الخط العربي'), subtitle: Text('توحيد الخط والأحجام عبر الصفحات'))),
      const Card(child: ListTile(leading: Icon(Icons.notifications_outlined), title: Text('الإشعارات والأذان'), subtitle: Text('إعدادات الإشعارات تحتاج ربطاً واختباراً'))),
      const Card(child: ListTile(leading: Icon(Icons.location_on_outlined), title: Text('الموقع'), subtitle: Text('تحديد الموقع من صفحة مواقيت الصلاة'))),
    ]),
  );
}

class SimplePage extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const SimplePage({super.key, required this.title, required this.icon, required this.subtitle});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      _Heading(title: title, subtitle: subtitle),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: emerald.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: emerald, size: 26)),
        const SizedBox(width: 12),
        const Expanded(child: Text('هذه الصفحة تحتاج استكمال المحتوى والوظائف قبل اعتمادها مكتملة.', style: TextStyle(height: 1.7))),
      ]))),
    ]),
  );
}

String _monthName(int month) => const ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'][month - 1];
String _weekday(int day) => const ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'][day - 1];
