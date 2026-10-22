import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/prayer_calendar_page.dart' show hijriDateLabel, hijriDateParts;

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
    this.seasonalOnly = false,
  });

  final String id;
  final String title;
  final String description;
  final String source;
  final String sourceUrl;
  final bool fridayOnly;
  final bool seasonalOnly;
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
      source: 'روايات تعقيب الصلاة في المصادر الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
    ),
    _Deed(
      id: 'daily-dua',
      title: 'دعاء اليوم بحسب يوم الأسبوع',
      description: 'اقرأ دعاء اليوم الموافق ليوم الأسبوع من غير اعتباره واجباً.',
      source: 'الأدعية المأثورة لأيام الأسبوع.',
      sourceUrl: 'https://ablibrary.net/',
    ),
    _Deed(
      id: 'rajab-acts',
      title: 'أعمال شهر رجب',
      description: 'تصفّح أعمال شهر رجب في قسم الأعمال والمناسبات واختر ما تستطيع. هذا تذكير بالأعمال المستحبة وليس تكليفاً جديداً.',
      source: 'أعمال شهر رجب في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'shaban-acts',
      title: 'أعمال شهر شعبان',
      description: 'تصفّح أعمال شهر شعبان والصلاة على محمد وآل محمد بحسب وقتك واستطاعتك.',
      source: 'أعمال شهر شعبان في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'ramadan-acts',
      title: 'أعمال شهر رمضان',
      description: 'تصفّح أدعية وأعمال شهر رمضان، واجعل لك ورداً تستطيع الاستمرار عليه.',
      source: 'أعمال شهر رمضان في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'ashura-acts',
      title: 'زيارة عاشوراء وأعمال يوم عاشوراء',
      description: 'تذكير بالمناسبة؛ اقرأ زيارة عاشوراء أو راجع أعمال اليوم في قسم الأعمال والمناسبات إن رغبت.',
      source: 'أعمال شهر محرم وزيارة عاشوراء في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'arbaeen-ziyara',
      title: 'زيارة الأربعين',
      description: 'تذكير بزيارة الأربعين للإمام الحسين عليه السلام؛ اعرض نص الزيارة من المكتبة الموثوقة داخل التطبيق.',
      source: 'زيارة الأربعين ضمن قسم الزيارات الشريفة.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'eid-fitr-acts',
      title: 'أعمال عيد الفطر',
      description: 'تذكير بأعمال يوم العيد في قسم الأعمال والمناسبات، مع مراعاة ثبوت العيد لدى مرجع تقليدك.',
      source: 'أعمال عيد الفطر في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'arafah-acts',
      title: 'أعمال يوم عرفة',
      description: 'راجع أعمال يوم عرفة ودعاء عرفة للإمام الحسين عليه السلام بحسب وقتك واستطاعتك.',
      source: 'أعمال يوم عرفة ودعاء عرفة في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'eid-adha-acts',
      title: 'أعمال عيد الأضحى',
      description: 'تذكير بأعمال عيد الأضحى في قسم الأعمال والمناسبات، مع مراعاة التقويم الشرعي المحلي.',
      source: 'أعمال عيد الأضحى في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'ghadir-acts',
      title: 'أعمال عيد الغدير',
      description: 'تذكير بأعمال عيد الغدير في اليوم الثامن عشر من ذي الحجة، بحسب التقويم الشرعي المتّبع.',
      source: 'أعمال عيد الغدير في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      seasonalOnly: true,
    ),
    _Deed(
      id: 'friday-ghusl',
      title: 'غسل يوم الجمعة',
      description: 'عمل مستحب مشهور في الفقه الإمامي؛ راجع فتوى مرجع التقليد لمعرفة التفاصيل.',
      source: 'أعمال يوم الجمعة في كتب الدعاء الإمامية.',
      sourceUrl: 'https://ablibrary.net/',
      fridayOnly: true,
    ),
    _Deed(
      id: 'nudba',
      title: 'دعاء الندبة',
      description: 'من الأدعية المشهورة التي تُقرأ صباح يوم الجمعة.',
      source: 'دعاء الندبة ضمن الأدعية العامة وأدعية الفرج وصاحب الزمان.',
      sourceUrl: 'https://ablibrary.net/',
      fridayOnly: true,
    ),
  ];

  final Set<String> _completed = <String>{};
  bool _loading = true;
  int _hijriCorrection = 0;

  List<_Deed> get _deeds {
    final today = DateTime.now();
    final isFriday = today.weekday == DateTime.friday;
    final hijri = hijriDateParts(today, correction: _hijriCorrection);
    final seasonalIds = seasonalDeedIdsForHijriDate(
      month: hijri.month,
      day: hijri.day,
    ).toSet();
    return _dailyDeeds.where((deed) {
      if (deed.fridayOnly && !isFriday) return false;
      if (deed.seasonalOnly && !seasonalIds.contains(deed.id)) return false;
      return true;
    }).toList();
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
      final correction = prefs.getInt('hijri_correction') ?? 0;
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addAll(values);
        _hijriCorrection = correction.clamp(-3, 3).toInt();
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
              Text('${weekdays[today.weekday - 1]} • ${hijriDateLabel(today, correction: _hijriCorrection)}', style: const TextStyle(color: _deedMuted)),
              const SizedBox(height: 8),
              const Text(
                'هذه أعمال مستحبة أو اقتراحات عامة وليست واجبات جديدة. أعمال رجب وشعبان ورمضان والمناسبات المعروفة تظهر بحسب التاريخ الهجري التقديري وتصحيحك المحفوظ. ثبوت الهلال قد يغيّر اليوم.',
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

/// IDs of seasonal deeds for the tabular Hijri date. Calendar dates are
/// estimates, so follow the local religious authority for moon-sighting dates.
List<String> seasonalDeedIdsForHijriDate({
  required int month,
  required int day,
}) {
  final ids = <String>[];
  if (month == 7) ids.add('rajab-acts');
  if (month == 8) ids.add('shaban-acts');
  if (month == 9) ids.add('ramadan-acts');
  if (month == 1 && day == 10) ids.add('ashura-acts');
  if (month == 2 && day == 20) ids.add('arbaeen-ziyara');
  if (month == 10 && day == 1) ids.add('eid-fitr-acts');
  if (month == 12 && day == 9) ids.add('arafah-acts');
  if (month == 12 && day == 10) ids.add('eid-adha-acts');
  if (month == 12 && day == 18) ids.add('ghadir-acts');
  return ids;
}
