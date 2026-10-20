import 'package:flutter/material.dart';

void main() => runApp(const MithaqApp());

const Color ink = Color(0xFF081712);
const Color panel = Color(0xFF10271F);
const Color panelLight = Color(0xFF18372B);
const Color emerald = Color(0xFF3B9B75);
const Color gold = Color(0xFFD8B875);
const Color muted = Color(0xFFA7B9AE);

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
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: emerald,
          brightness: Brightness.dark,
          surface: panel,
        ),
        fontFamily: 'NotoNaskhArabic',
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
  int selectedIndex = 0;

  static const destinations = [
    _Destination('الرئيسية', Icons.home_rounded),
    _Destination('القرآن', Icons.menu_book_rounded),
    _Destination('الأدعية', Icons.auto_awesome_rounded),
    _Destination('التسبيح', Icons.circle_outlined),
    _Destination('الإعدادات', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.spa_rounded, color: gold, size: 25),
            SizedBox(width: 10),
            Text(
              'ميثاق المؤمن',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'التقويم',
            onPressed: () => _showNotice(context, 'التقويم', 'سنصمم صفحة التقويم بعد إكمال الواجهة الأساسية.'),
            icon: const Icon(Icons.calendar_month_rounded, color: gold),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          const HomePage(),
          const PlaceholderPage(
            icon: Icons.menu_book_rounded,
            title: 'القرآن الكريم',
            subtitle: 'واجهة القرآن ستُبنى بعد اعتماد التصميم الأساسي.',
          ),
          const PlaceholderPage(
            icon: Icons.auto_awesome_rounded,
            title: 'الأدعية والزيارات',
            subtitle: 'سنضيف المكتبة ونصوصها في مرحلتها المخصصة.',
          ),
          const PlaceholderPage(
            icon: Icons.circle_outlined,
            title: 'التسبيح',
            subtitle: 'هذه صفحة مبدئية ضمن هيكل التطبيق الجديد.',
          ),
          const PlaceholderPage(
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            subtitle: 'سنكمل خيارات التطبيق بعد تثبيت الواجهة.',
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C2018),
          border: Border(top: BorderSide(color: Color(0xFF20392D))),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: selectedIndex,
          backgroundColor: const Color(0xFF0C2018),
          indicatorColor: emerald.withValues(alpha: 0.22),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() => selectedIndex = index),
          destinations: destinations
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon, size: 22),
                    selectedIcon: Icon(item.icon, color: gold, size: 23),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  const _Destination(this.label, this.icon);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          const Text(
            'أهلاً بك',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, height: 1.5),
          ),
          const Text(
            'اجعل لقلبك كل يوم موعداً مع الله',
            style: TextStyle(fontSize: 14, color: muted, height: 1.8),
          ),
          const SizedBox(height: 20),
          const _WelcomeCard(),
          const SizedBox(height: 18),
          const _PrayerTimeCard(),
          const SizedBox(height: 22),
          const _SectionHeading(title: 'مساحة يومك', subtitle: 'نظرة سريعة على رحلتك اليومية'),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _MiniStat(icon: Icons.menu_book_rounded, label: 'القراءة', value: 'ابدأ وردك', tint: emerald)),
              SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Icons.favorite_rounded, label: 'العبادة', value: 'خطوة اليوم', tint: gold)),
              SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Icons.track_changes_rounded, label: 'هدفك', value: 'اصنع عادة', tint: Color(0xFF8DBB78))),
            ],
          ),
          const SizedBox(height: 26),
          const _SectionHeading(title: 'الوصول السريع', subtitle: 'كل ما تحتاجه في مكان واحد'),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.23,
            children: [
              _QuickCard(
                icon: Icons.menu_book_rounded,
                title: 'القرآن الكريم',
                subtitle: 'تصفّح السور',
                color: const Color(0xFF3D9B75),
                onTap: () => _showNotice(context, 'القرآن الكريم', 'نبدأ بتصميم الصفحة بعد تثبيت الواجهة الرئيسية.'),
              ),
              _QuickCard(
                icon: Icons.auto_awesome_rounded,
                title: 'الأدعية والزيارات',
                subtitle: 'مكتبة روحانية',
                color: const Color(0xFFD8B875),
                onTap: () => _showNotice(context, 'الأدعية والزيارات', 'هذه المرحلة مخصصة لتصميم الواجهة فقط.'),
              ),
              _QuickCard(
                icon: Icons.circle_outlined,
                title: 'التسبيح',
                subtitle: 'مساحة للتسبيح',
                color: const Color(0xFF78B9B0),
                onTap: () => _showNotice(context, 'التسبيح', 'سنضيف وظائف التسبيح في مرحلة الميزات.'),
              ),
              _QuickCard(
                icon: Icons.event_note_rounded,
                title: 'التقويم',
                subtitle: 'المناسبات والأيام',
                color: const Color(0xFFB99AE4),
                onTap: () => _showNotice(context, 'التقويم', 'صفحة التقويم تأتي بعد إكمال الواجهة الأساسية.'),
              ),
              _QuickCard(
                icon: Icons.explore_rounded,
                title: 'اتجاه القبلة',
                subtitle: 'الوصول إلى القبلة',
                color: const Color(0xFFE0A16C),
                onTap: () => _showNotice(context, 'اتجاه القبلة', 'سنصمم هذه الصفحة في مرحلة مستقلة.'),
              ),
              _QuickCard(
                icon: Icons.checklist_rounded,
                title: 'متابعة العبادة',
                subtitle: 'تنظيم يومك',
                color: const Color(0xFF8DBB78),
                onTap: () => _showNotice(context, 'متابعة العبادة', 'هذه الفكرة محفوظة لمرحلة لاحقة.'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF254536)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.volunteer_activism_rounded, color: gold, size: 25),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('خطوة بخطوة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      SizedBox(height: 5),
                      Text(
                        'نبني ميثاق المؤمن بهدوء واهتمام، ونكمل كل مرحلة قبل الانتقال إلى التالية.',
                        style: TextStyle(color: muted, height: 1.8, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF225B42), Color(0xFF123326), Color(0xFF10271F)],
        ),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: Icon(Icons.spa_rounded, size: 78, color: Color(0x227FC6A1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('رفيق رحلتك الإيمانية', style: TextStyle(color: gold, fontSize: 12)),
              ),
              const SizedBox(height: 15),
              const Text(
                'طمأنينةٌ للقلب،
ونورٌ للطريق',
                style: TextStyle(fontSize: 25, height: 1.55, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'مساحة تجمع عبادتك وقراءتك اليومية',
                style: TextStyle(color: Color(0xFFD0DED5), fontSize: 13, height: 1.8),
              ),
              const SizedBox(height: 17),
              OutlinedButton.icon(
                onPressed: () => _showNotice(context, 'ابدأ رحلتك', 'سنربط هذا الزر بصفحات التطبيق بعد اعتماد التصميم.'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('اكتشف التطبيق'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: BorderSide(color: gold.withValues(alpha: 0.65)),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeCard extends StatelessWidget {
  const _PrayerTimeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF254536)),
      ),
      child: const Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(color: Color(0xFF1B3D2D), shape: BoxShape.circle),
            child: Icon(Icons.access_time_rounded, color: gold, size: 24),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مواقيت الصلاة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 4),
                Text('ستظهر المواقيت بعد إعداد الموقع', style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: muted),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 14, 11, 13),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF254536)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 19),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFF254536)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PlaceholderPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: muted, height: 1.8, fontSize: 13)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF225B42), Color(0xFF10271F)],
              ),
              border: Border.all(color: gold.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: gold, size: 30),
                ),
                const SizedBox(height: 19),
                const Text('مساحتك الخاصة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(
                  'نرتّب هذه الصفحة بعناية ضمن بناء الواجهة، ثم نضيف محتواها ووظائفها في المرحلة المخصصة.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.9, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          const _SectionHeading(title: 'سيكون هنا', subtitle: 'تصميم مبدئي لترتيب العناصر'),
          const SizedBox(height: 13),
          _PreviewTile(icon: icon, title: 'القسم الرئيسي', subtitle: 'مساحة أساسية لمحتوى الصفحة'),
          const SizedBox(height: 10),
          _PreviewTile(icon: Icons.bookmark_border_rounded, title: 'المحفوظات', subtitle: 'مكان واضح للعناصر التي تريد الرجوع إليها'),
          const SizedBox(height: 10),
          _PreviewTile(icon: Icons.history_rounded, title: 'آخر نشاط', subtitle: 'عرض مرتب للنشاط الأخير بعد تنفيذ الوظائف'),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF254536)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: emerald.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: emerald, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: muted, fontSize: 12, height: 1.6)),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: muted),
        ],
      ),
    );
  }
}

void _showNotice(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: panel,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: muted, height: 1.8)),
          const SizedBox(height: 14),
        ],
      ),
    ),
  );
}
