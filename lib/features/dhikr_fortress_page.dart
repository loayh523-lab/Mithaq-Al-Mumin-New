import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dhikrPanel = Color(0xFF10251E);
const _dhikrGold = Color(0xFFD9B66D);
const _dhikrMuted = Color(0xFF9EB5A9);
const _dhikrSourceUrl = 'https://tableegh.imamali.net/?id=3117';

class _DhikrItem {
  const _DhikrItem({
    required this.id,
    required this.title,
    required this.text,
    required this.target,
    required this.source,
    this.eveningText,
    this.morning = true,
    this.evening = true,
  });

  final String id;
  final String title;
  final String text;
  final int? target;
  final String source;
  final String? eveningText;
  final bool morning;
  final bool evening;

  String textFor(int period) => period == 1 ? (eveningText ?? text) : text;
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
      source: 'ثلاث مرات صباحاً ومساءً. الكافي، ج 2، ص 534؛ وسائل الشيعة، ج 7، ص 229؛ بحار الأنوار، ج 83، ص 296.',
    ),
    _DhikrItem(
      id: 'salawat-prophetic',
      title: 'الصلاة على النبي وآله',
      text: 'اللهم صل على محمد وآل محمد في الأولين، وصل على محمد وآل محمد في الآخرين، وصل على محمد وآل محمد في الملأ الأعلى، وصل على محمد وآل محمد في المرسلين. اللهم أعط محمداً الوسيلة والشرف والفضيلة والدرجة الكبيرة. اللهم إني آمنت بمحمد ولم أره، فلا تحرمني يوم القيامة رؤيته، وارزقني صحبته وتوفني على ملته، واسقني من حوضه مشرباً روياً سائغاً هنيئاً لا أظمأ بعده أبداً، إنك على كل شيء قدير. اللهم كما آمنت بمحمد ولم أره، فعرفني في الجنان وجهه. اللهم بلغ روح محمد عني تحية كثيرة وسلاماً.',
      target: 3,
      source: 'وردت ثلاث مرات غدوة وعشية. ثواب الأعمال للشيخ الصدوق، ص 157؛ بحار الأنوار، ج 91، ص 59.',
    ),
    _DhikrItem(
      id: 'mutaqallib',
      title: 'دعاء تثبيت القلب',
      text: 'اللهم مقلب القلوب والأبصار، ثبت قلبي على دينك، ولا تزغ قلبي بعد إذ هديتني، وهب لي من لدنك رحمة إنك أنت الوهاب، وأجرني من النار برحمتك. اللهم امدد لي في عمري، وأوسع علي من رزقي، وانشر علي من رحمتك، وإن كنت عندك في أم الكتاب شقياً فاجعلني سعيداً، فإنك تمحو ما تشاء وتثبت وعندك أم الكتاب.',
      target: 3,
      source: 'ورد ثلاث مرات عند الصباح والمساء. الكافي، ج 2، ص 525.',
    ),
    _DhikrItem(
      id: 'allah-allah',
      title: 'ذكر التوحيد',
      text: 'الله الله الله ربي الرحمن الرحيم، لا أشرك به شيئاً',
      target: null,
      source: 'الكافي، ج 2، ص 534. ورد أن يقال صباحاً ومساءً، والنقل المذكور لا يحدد عدداً؛ العداد هنا للتتبع فقط.',
    ),
    _DhikrItem(
      id: 'la-yadurru',
      title: 'بسم الله الذي لا يضر',
      text: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم',
      target: 3,
      source: 'ثلاث مرات صباحاً ومساءً. بحار الأنوار، ج 83، ص 300.',
    ),
    _DhikrItem(
      id: 'la-hawla',
      title: 'لا حول ولا قوة إلا بالله',
      text: 'لا حول ولا قوة إلا بالله العلي العظيم',
      target: 10,
      source: 'عشر مرات صباحاً وعشر مرات مساءً. بحار الأنوار، ج 83، ص 161. وذكر المصدر أيضاً قولها قبل النوم.',
    ),
    _DhikrItem(
      id: 'maqalid',
      title: 'دعاء المقاليد',
      text: 'لا إله إلا الله، والله أكبر، سبحان الله، والحمد لله، أستغفر الله، ولا حول ولا قوة إلا بالله، هو الأول والآخر، والظاهر والباطن، له الملك وله الحمد، يحيي ويميت وهو حي لا يموت، بيده الخير وهو على كل شيء قدير',
      target: 10,
      source: 'عشر مرات صباحاً وعشر مرات مساءً؛ منقول في المصدر عن بحار الأنوار ضمن أذكار الصباح والمساء.',
    ),
    _DhikrItem(
      id: 'nimat',
      title: 'دعاء النعمة والعافية والستر',
      text: 'اللهم إني أصبحت في نعمة منك وعافية وستر، فصل على محمد وآل محمد، وأتمم علي نعمتك وعافيتك وسترك',
      eveningText: 'اللهم إني أمسيت في نعمة منك وعافية وستر، فصل على محمد وآل محمد، وأتمم علي نعمتك وعافيتك وسترك',
      target: 3,
      source: 'ثلاث مرات صباحاً ومساءً. بحار الأنوار، ج 83، ص 283.',
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
    return 'fortress_v3_${_periodName}_${day}_$id';
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
          _counts[item.id] = (prefs.getInt(_key(item.id)) ?? 0);
          if (item.target != null) {
            _counts[item.id] = _counts[item.id]!.clamp(0, item.target!);
          }
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
    if (item.target != null && current >= item.target!) return;
    final next = current + 1;
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
            'نصوص أذكار منقولة مع مراجعها. إذا لم يحدد المصدر عدداً للتكرار، يظهر العداد مفتوحاً ولا يعني الرقم المقترح حكماً شرعياً.',
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
            final target = item.target;
            return Card(
              color: _dhikrPanel,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item.title, style: const TextStyle(color: _dhikrGold, fontWeight: FontWeight.w800, fontSize: 17))),
                    Text(target == null ? '$count' : '$count / $target', style: const TextStyle(color: _dhikrMuted, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Text(item.textFor(_period), textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, height: 1.9)),
                  if (target != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinearProgressIndicator(value: (count / target).clamp(0, 1).toDouble(), minHeight: 7, backgroundColor: Colors.black26, color: _dhikrGold),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('المصدر: ${item.source}', style: const TextStyle(color: _dhikrMuted, height: 1.5, fontSize: 12)),
                  const SizedBox(height: 4),
                  const SelectableText(_dhikrSourceUrl, style: TextStyle(color: _dhikrGold, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (target != null && count >= target) || _loading ? null : () => _increment(item),
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
