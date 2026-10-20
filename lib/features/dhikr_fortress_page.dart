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
  });

  final String id;
  final String title;
  final String text;
  final int? target;
  final String source;
}

class DhikrFortressPage extends StatefulWidget {
  const DhikrFortressPage({super.key, this.initialPeriod = 0});

  /// 0 opens morning-only content; 1 opens evening-only content.
  final int initialPeriod;

  @override
  State<DhikrFortressPage> createState() => _DhikrFortressPageState();
}

class _DhikrFortressPageState extends State<DhikrFortressPage> {
  // Separate source-backed lists. No full text is copied between periods.
  static const _morningItems = <_DhikrItem>[
    _DhikrItem(
      id: 'morning-surahs-before-sunrise',
      title: 'سور وآية قبل طلوع الشمس',
      text: 'تُقرأ سورة الإخلاص، وسورة القدر، وآية الكرسي إحدى عشرة مرة لكل واحدة قبل طلوع الشمس.',
      target: 11,
      source: 'مفاتيح الجنان، فصل الدعاء عند طلوع الشمس وعند غروبها؛ ينقل الرواية عن الخصال للشيخ الصدوق.',
    ),
    _DhikrItem(
      id: 'morning-after-fajr',
      title: 'ذكر بعد فريضة الصبح',
      text: 'سُبْحَانَ اللهِ العَظِيمِ وَبِحَمْدِهِ، وَلا حَوْلَ وَلا قُوَّةَ إِلا بِاللهِ العَلِيِّ العَظِيمِ',
      target: 10,
      source: 'مفاتيح الجنان، باب تعقيبات صلاة الصبح؛ ينقله عن كتاب التهذيب.',
    ),
    _DhikrItem(
      id: 'morning-entrusting',
      title: 'تفويض الأمر إلى الله',
      text: 'بِسْمِ اللهِ وَصَلَّى اللهُ عَلَى مُحَمَّدٍ وَآلِهِ، وَأُفَوِّضُ أَمْرِي إِلَى اللهِ، إِنَّ اللهَ بَصِيرٌ بِالْعِبَادِ، فَوَقَاهُ اللهُ سَيِّئَاتِ مَا مَكَرُوا، لا إِلَهَ إِلا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      target: null,
      source: 'مفاتيح الجنان، ما ورد عقيب فريضة الصبح؛ لم يُذكر هنا عدد محدد للتكرار.',
    ),
  ];

  static const _eveningItems = <_DhikrItem>[
    _DhikrItem(
      id: 'evening-tahlil-before-sunset',
      title: 'التهليل قبل غروب الشمس',
      text: 'لا إِلَهَ إِلا اللهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ وَهُوَ حَيٌّ لا يَمُوتُ، بِيَدِهِ الْخَيْرُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      target: 10,
      source: 'مفاتيح الجنان، فصل الدعاء عند طلوع الشمس وعند غروبها؛ ينقله عن الكافي والخصال ومصباح المتهجد.',
    ),
    _DhikrItem(
      id: 'evening-takbir',
      title: 'تكبير المساء',
      text: 'اللهُ أَكْبَرُ',
      target: 100,
      source: 'مفاتيح الجنان، فصل أذكار ودعوات تقرأ صباحاً ومساءً؛ ينقل عن المقنع للشيخ الصدوق ثواب التكبير عند المساء.',
    ),
    _DhikrItem(
      id: 'evening-istiadha',
      title: 'الاستعاذة قبل الغروب',
      text: 'أَعُوذُ بِاللهِ السَّمِيعِ الْعَلِيمِ مِنْ هَمَزَاتِ الشَّيَاطِينِ، وَأَعُوذُ بِاللهِ أَنْ يَحْضُرُونَ، إِنَّ اللهَ هُوَ السَّمِيعُ الْعَلِيمُ',
      target: 10,
      source: 'مفاتيح الجنان، فصل الدعاء عند طلوع الشمس وعند غروبها؛ ورد قبل طلوع الشمس وقبل غروبها.',
    ),
    _DhikrItem(
      id: 'evening-istighfar',
      title: 'الاستغفار في ختام النهار',
      text: 'أَسْتَغْفِرُ اللهَ رَبِّي وَأَتُوبُ إِلَيْهِ',
      target: null,
      source: 'صيغة استغفار عامة؛ لم يُنسب لها هنا عدد مخصوص أو رواية بعينها.',
    ),
  ];

  final Map<String, int> _counts = <String, int>{};
  bool _loading = true;
  int _period = 0;

  String get _periodName => _period == 0 ? 'صباح' : 'مساء';
  List<_DhikrItem> get _visibleItems => _period == 0 ? _morningItems : _eveningItems;

  String _key(String id) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fortress_v3_${_periodName}_${day}_$id';
  }

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod == 1 ? 1 : 0;
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
            _counts[item.id] = _counts[item.id]!.clamp(0, item.target!).toInt();
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
            'قسمان منفصلان للصباح والمساء. الأذكار التي يذكرها المصدر في الوقتين تبقى مشتركة، ويتغيّر اللفظ في النصوص التي لها صيغة صباحية ومسائية. العداد مستقل لكل وقت ولكل يوم.',
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
                  Text(item.text, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, height: 1.9)),
                  if (target != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinearProgressIndicator(value: (count / target).clamp(0, 1).toDouble(), minHeight: 7, backgroundColor: Colors.black26, color: _dhikrGold),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('المصدر: ${item.source}', style: const TextStyle(color: _dhikrMuted, height: 1.5, fontSize: 12)),
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
