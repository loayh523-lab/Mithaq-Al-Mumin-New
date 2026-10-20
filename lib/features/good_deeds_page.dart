import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/prayer_calendar_page.dart' show hijriDateLabel;

const _deedPanel = Color(0xFF10251E);
const _deedGold = Color(0xFFD9B66D);
const _deedMuted = Color(0xFF9EB5A9);

class _Deed {
  const _Deed({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.sourceUrl,
    this.fridayOnly = false,
  });

  final String id;
  final String title;
  final String description;
  final String source;
  final String sourceUrl;
  final bool fridayOnly;
}

class GoodDeedsPage extends StatefulWidget {
  const GoodDeedsPage({super.key});
  @override
  State<GoodDeedsPage> createState() => _GoodDeedsPageState();
}

class _GoodDeedsPageState extends State<GoodDeedsPage> {
  static const _dailyDeeds = <_Deed>[
    _Deed(
      id: 'prayers',
      title: 'المحافظة على الصلوات',
      description: 'حافظ على الصلوات المفروضة في أوقاتها بحسب استطاعتك.',
      source: 'القرآن الكريم، سورة النساء، الآية 103.',
      sourceUrl: 'https://quran.com/4/103',
    ),
    _Deed(
      id: 'quran',
      title: 'ورد من القرآن الكريم',
      description: 'اقرأ ما تيسّر لك من القرآن بتدبّر؛ المقدار هنا اقتراح وليس تكليفاً إضافياً.',
      source: 'القرآن الكريم، سورة المزمل، الآية 20: «فاقرؤوا ما تيسر من القرآن».',
      sourceUrl: 'https://quran.com/73/20',
    ),
    _Deed(
      id: 'salawat',
      title: 'الصلاة على محمد وآل محمد',
      description: 'خصّص وقتاً للصلاة على النبي وآله عليهم الصلاة والسلام.',
      source: 'القرآن الكريم، سورة الأحزاب، الآية 56.',
      sourceUrl: 'https://quran.com/33/56',
    ),
    _Deed(
      id: 'family',
      title: 'صلة الرحم والإحسان إلى الأهل',
      description: 'اطمئن على قريب، أو ساعد أحداً من أهلك، أو أصلح علاقة تستطيع إصلاحها.',
      source: 'القرآن الكريم، سورة النساء، الآية 1، في الوصية بالأرحام.',
      sourceUrl: 'https://quran.com/4/1',
    ),
    _Deed(
      id: 'charity',
      title: 'صدقة أو مساعدة',
      description: 'قدّم ما تستطيع من مساعدة أو صدقة من دون أن تضرّ بحاجاتك الأساسية.',
      source: 'القرآن الكريم، سورة البقرة، الآية 261.',
      sourceUrl: 'https://quran.com/2/261',
    ),
    _Deed(
      id: 'tasbih-zahra',
      title: 'تسبيح الزهراء عليها السلام',
      description: 'اجعله ضمن تعقيب الصلاة كما ورد في كتب الأدعية الإمامية.',
      source: 'مفاتيح الجنان، قسم تعقيبات الصلوات؛ راجع النص في المكتبة المرفقة بالتطبيق.',
      sourceUrl: 'https://ablibrary.net/book_content/b/1228/72?lang=ar',
    ),
    _Deed(
      id: 'daily-dua',
      title: 'دعاء اليوم من مفاتيح الجنان',
      description: 'اقرأ دعاء اليوم الموافق ليوم الأسبوع من غير اعتباره واجباً.',
      source: 'مفاتيح الجنان، فصل دعوات أيام الأسبوع.',
      sourceUrl: 'https://ablibrary.net/book_content/b/1228/72?lang=ar',
    ),
    _Deed(
      id: 'friday-ghusl',
      title: 'غسل يوم الجمعة',
      description: 'عمل مستحب مشهور في الفقه الإمامي؛ راجع فتوى مرجع التقليد لمعرفة التفاصيل.',
      source: 'مفاتيح الجنان، أعمال يوم الجمعة.',
      sourceUrl: 'https://ablibrary.net/book_content/b/1228/72?lang=ar',
      fridayOnly: true,
    ),
    _Deed(
      id: 'nudba',
      title: 'دعاء الندبة',
      description: 'من الأدعية المشهورة التي تُقرأ صباح يوم الجمعة.',
      source: 'مفاتيح الجنان، أعمال يوم الجمعة، دعاء الندبة.',
      sourceUrl: 'https://ablibrary.net/book_content/b/1228/72?lang=ar',
      fridayOnly: true,
    ),
  ];

  final Set<String> _completed = <String>{};
  bool _loading = true;

  List<_Deed> get _deeds {
    final isFriday = DateTime.now().weekday == DateTime.friday;
    return _dailyDeeds.where((deed) => !deed.fridayOnly || isFriday).toList();
  }

  String get _key {
    final now = DateTime.now();
    return 'good_deeds_sources_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_key) ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addAll(values);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String id, bool checked) async {
    setState(() {
      if (checked) {
        _completed.add(id);
      } else {
        _completed.remove(id);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _completed.toList()..sort());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ الأعمال على الجهاز')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deeds = _deeds;
    final completed = deeds.where((deed) => _completed.contains(deed.id)).length;
    final today = DateTime.now();
    const weekdays = <String>[
      'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('صالح الأعمال')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _deedPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _deedGold.withValues(alpha: .3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('أعمال اليوم ومصادرها', style: TextStyle(color: _deedGold, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${weekdays[today.weekday - 1]} • ${hijriDateLabel(today)}', style: const TextStyle(color: _deedMuted)),
              const SizedBox(height: 8),
              const Text(
                'هذه أعمال مستحبة أو اقتراحات عامة وليست واجبات جديدة. أضفنا مرجعاً لكل بند، ويُعرض غسل الجمعة ودعاء الندبة يوم الجمعة فقط.',
                style: TextStyle(color: _deedMuted, height: 1.7),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: deeds.isEmpty ? 0 : completed / deeds.length,
                minHeight: 8,
                backgroundColor: Colors.black26,
                color: _deedGold,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 8),
              Text('$completed من ${deeds.length} أعمال', style: const TextStyle(color: _deedGold, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _deedGold)))
          else
            ...deeds.map((deed) {
              final checked = _completed.contains(deed.id);
              return Card(
                color: _deedPanel,
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checked,
                      activeColor: _deedGold,
                      checkColor: Colors.black,
                      onChanged: (value) => _toggle(deed.id, value ?? false),
                      title: Text(deed.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(deed.description, style: const TextStyle(color: _deedMuted, height: 1.5)),
                      secondary: const Icon(Icons.volunteer_activism_rounded, color: _deedGold),
                    ),
                    const Divider(color: Color(0x223CB58B)),
                    Text('المصدر: ${deed.source}', style: const TextStyle(color: _deedMuted, height: 1.5, fontSize: 12)),
                    const SizedBox(height: 4),
                    SelectableText(deed.sourceUrl, style: const TextStyle(color: _deedGold, fontSize: 11)),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}
