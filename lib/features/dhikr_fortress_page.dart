import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dhikrPanel = Color(0xFF10251E);
const _dhikrGold = Color(0xFFD9B66D);
const _dhikrMuted = Color(0xFF9EB5A9);

class _DhikrItem {
  const _DhikrItem({
    required this.id,
    required this.title,
    required this.text,
    required this.target,
    required this.source,
    required this.sourceUrl,
    this.morning = true,
    this.evening = true,
  });

  final String id;
  final String title;
  final String text;
  final int target;
  final String source;
  final String sourceUrl;
  final bool morning;
  final bool evening;
}

class DhikrFortressPage extends StatefulWidget {
  const DhikrFortressPage({super.key});
  @override
  State<DhikrFortressPage> createState() => _DhikrFortressPageState();
}

class _DhikrFortressPageState extends State<DhikrFortressPage> {
  static const _items = <_DhikrItem>[
    _DhikrItem(
      id: 'shield-prayer',
      title: 'دعاء الدرع الحصينة',
      text: 'اللهم اجعلني في درعك الحصينة التي تجعل فيها من تريد',
      target: 3,
      source: 'الكافي، ج 2، ص 534؛ وسائل الشيعة، ج 7، ص 229. ورد ثلاث مرات صباحاً ومساءً.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'protection-trust',
      title: 'دعاء الأمان صباحاً ومساءً',
      text: 'أصبحت بذمة الله وذمم رسله وذمة محمد صلى الله عليه وآله، وذمم الأوصياء عليهم السلام، آمنت بسرهم وعلانيتهم، وشاهدهم وغائبهم، وأشهد أنهم في علم الله وطاعته',
      target: 3,
      source: 'بحار الأنوار، ج 83، ص 338؛ النص والتكرار منقولان عن قسم الشؤون الدينية في العتبة العلوية.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'رضا',
      title: 'الرضا بالله والإسلام والولاية',
      text: 'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وآله نبياً، وبالقرآن بلاغاً، وبعلي عليه السلام إماماً',
      target: 3,
      source: 'الكافي، ج 2، ص 525؛ مذكور ضمن أذكار الصباح والمساء في المصدر.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'istiwdah',
      title: 'دعاء الاستيداع عند المساء',
      text: 'أستودع الله العلي الأعلى الجليل العظيم نفسي ومن يعنيني أمره، أستودع الله نفسي المرهوب المخوف المتضعضع لعظمته كل شيء',
      target: 3,
      source: 'الكافي، ج 2، ص 523؛ بحار الأنوار، ج 83، ص 296. ورد في المصدر عند المساء.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
      morning: false,
    ),
    _DhikrItem(
      id: 'la-hawla',
      title: 'لا حول ولا قوة إلا بالله',
      text: 'بسم الله الرحمن الرحيم، لا حول ولا قوة إلا بالله العلي العظيم',
      target: 3,
      source: 'المحاسن، البرقي، ج 1، ص 41؛ مذكور ثلاث مرات صباحاً ومساءً.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'allah-allah',
      title: 'ذكر التوحيد',
      text: 'الله الله الله ربي الرحمن الرحيم، لا أشرك به شيئاً',
      target: 1,
      source: 'الكافي، ج 2، ص 534؛ ورد أن يقال عند الصباح والمساء، ولم يحدد النص عدداً في النقل المذكور.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'tawheed',
      title: 'التهليل والتوحيد',
      text: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، يحيي ويميت وهو حي لا يموت، بيده الخير وهو على كل شيء قدير',
      target: 10,
      source: 'الكافي، ج 2، ص 534؛ عشر مرات عند طلوع الفجر وعشر مرات في المساء، بحسب النقل في المصدر.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'salawat',
      title: 'الصلاة على محمد وآل محمد',
      text: 'اللهم صل على محمد وآل محمد',
      target: 10,
      source: 'الكافي، ج 2، ص 534؛ ضمن العمل المروي صباحاً ومساءً في المصدر.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'tasbih',
      title: 'التسبيح',
      text: 'سبحان الله',
      target: 35,
      source: 'الكافي، ج 2، ص 534؛ ورد خمساً وثلاثين مرة ضمن العمل المذكور.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'tahlil',
      title: 'التهليل',
      text: 'لا إله إلا الله',
      target: 35,
      source: 'الكافي، ج 2، ص 534؛ ورد خمساً وثلاثين مرة ضمن العمل المذكور.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
    _DhikrItem(
      id: 'hamd',
      title: 'التحميد',
      text: 'الحمد لله',
      target: 35,
      source: 'الكافي، ج 2، ص 534؛ ورد خمساً وثلاثين مرة ضمن العمل المذكور.',
      sourceUrl: 'https://tableegh.imamali.net/?id=3117',
    ),
  ];

  final Map<String, int> _counts = <String, int>{};
  bool _loading = true;
  int _period = 0;

  String get _periodName => _period == 0 ? 'صباح' : 'مساء';
  List<_DhikrItem> get _visibleItems => _items.where((item) => _period == 0 ? item.morning : item.evening).toList();

  String _key(String id) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fortress_v2_${_periodName}_${day}_$id';
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
        for (final item in _visibleItems) {
          _counts[item.id] = (prefs.getInt(_key(item.id)) ?? 0).clamp(0, item.target);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPeriod(int period) async {
    setState(() {
      _period = period;
      _loading = true;
      _counts.clear();
    });
    await _load();
  }

  Future<void> _increment(_DhikrItem item) async {
    final current = _counts[item.id] ?? 0;
    final next = (current + 1).clamp(0, item.target);
    if (next == current) return;
    HapticFeedback.lightImpact();
    setState(() => _counts[item.id] = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(item.id), next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ عدّاد الذكر')),
        );
      }
    }
  }

  Future<void> _reset(_DhikrItem item) async {
    setState(() => _counts[item.id] = 0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(item.id), 0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تصفير عدّاد الذكر')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('أذكار الصباح والمساء')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _dhikrPanel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _dhikrGold.withValues(alpha: .3)),
          ),
          child: const Text(
            'أذكار عربية مع عدد التكرار ومرجع النص. تختلف بعض ألفاظ الأدعية بين المصادر والطبعات؛ راجع المرجع عند التدقيق.',
            style: TextStyle(color: _dhikrMuted, height: 1.7),
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('أذكار الصباح'), icon: Icon(Icons.wb_sunny_outlined)),
            ButtonSegment(value: 1, label: Text('أذكار المساء'), icon: Icon(Icons.nights_stay_outlined)),
          ],
          selected: {_period},
          onSelectionChanged: (selected) => _setPeriod(selected.first),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _dhikrGold)))
        else
          ..._visibleItems.map((item) {
            final count = _counts[item.id] ?? 0;
            return Card(
              color: _dhikrPanel,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item.title, style: const TextStyle(color: _dhikrGold, fontWeight: FontWeight.w800, fontSize: 17))),
                    Text('$count / ${item.target}', style: const TextStyle(color: _dhikrMuted, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Text(item.text, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, height: 1.9)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressIndicator(value: count / item.target, minHeight: 7, backgroundColor: Colors.black26, color: _dhikrGold),
                  ),
                  const SizedBox(height: 8),
                  Text('المصدر: ${item.source}', style: const TextStyle(color: _dhikrMuted, height: 1.5, fontSize: 12)),
                  const SizedBox(height: 4),
                  SelectableText(item.sourceUrl, style: const TextStyle(color: _dhikrGold, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: count >= item.target || _loading ? null : () => _increment(item),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('تسبيح'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'إعادة العداد',
                      onPressed: _loading ? null : () => _reset(item),
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                  ]),
                ]),
              ),
            );
          }),
      ],
    ),
  );
}
