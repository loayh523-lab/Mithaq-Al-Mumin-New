import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/religious_content.dart';

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
            tooltip: 'التنبيهات',
            onPressed: () => _notice('سيُضاف مركز التنبيهات لاحقاً'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selected,
          children: [
            _homePage(),
            _placeholderPage(Icons.menu_book_rounded, 'القرآن الكريم', 'قراءة القرآن الكريم وفهرس السور'),
            _duaPage(),
            _tasbeehPage(),
            _placeholderPage(Icons.settings_rounded, 'الإعدادات', 'التفضيلات والمظهر ومصادر المحتوى'),
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
          _featureCard(Icons.explore_rounded, 'القبلة والصلاة', 'تُضاف بعد التحقق من الحسابات', () => _notice('ميزة الصلاة والقبلة قيد التطوير')),
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
    child: Padding(
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
              onTap: () => setState(() => _count++),
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
            onPressed: () => setState(() => _count = 0),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تصفير العدّاد'),
          ),
        ],
      ),
    ),
  );

  Widget _placeholderPage(IconData icon, String title, String description) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: _gold),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.7)),
          const SizedBox(height: 20),
          const Chip(avatar: Icon(Icons.construction_rounded, size: 18), label: Text('قيد البناء')),
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
        const Text('مكتبة أولية للأذكار العامة مع توضيح طبيعة النصوص', style: TextStyle(color: _muted)),
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
