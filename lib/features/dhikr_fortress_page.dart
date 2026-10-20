import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dhikrPanel = Color(0xFF10251E);
const _dhikrGold = Color(0xFFD9B66D);
const _dhikrMuted = Color(0xFF9EB5A9);

class _DhikrItem {
  const _DhikrItem(this.title, this.text, this.target);
  final String title;
  final String text;
  final int target;
}

class DhikrFortressPage extends StatefulWidget {
  const DhikrFortressPage({super.key});
  @override
  State<DhikrFortressPage> createState() => _DhikrFortressPageState();
}

class _DhikrFortressPageState extends State<DhikrFortressPage> {
  static const _items = <_DhikrItem>[
    _DhikrItem('الاستغفار', 'أستغفر الله ربي وأتوب إليه', 100),
    _DhikrItem('الصلاة على محمد وآل محمد', 'اللهم صل على محمد وآل محمد', 100),
    _DhikrItem('الذكر الجامع', 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر', 100),
  ];
  final Map<int, int> _counts = <int, int>{};
  bool _loading = true;
  int _period = 0;

  String get _periodName => _period == 0 ? 'صباح' : 'مساء';
  String _key(int index) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fortress_${_periodName}_${day}_$index';
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
        for (var i = 0; i < _items.length; i++) {
          _counts[i] = (prefs.getInt(_key(i)) ?? 0).clamp(0, _items[i].target);
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

  Future<void> _increment(int index) async {
    final next = ((_counts[index] ?? 0) + 1).clamp(0, _items[index].target);
    if (next == _counts[index]) return;
    HapticFeedback.lightImpact();
    setState(() => _counts[index] = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(index), next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ عدّاد الذكر')),
        );
      }
    }
  }

  Future<void> _reset(int index) async {
    setState(() => _counts[index] = 0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(index), 0);
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
    appBar: AppBar(title: const Text('حصن الأذكار')),
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
            'عدادات لأذكار عامة تختارها أنت. ليست هذه القائمة بديلاً عن النصوص الموثقة لأعمال مخصوصة.',
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
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final count = _counts[index] ?? 0;
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
                  Text(item.text, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 19, height: 1.8)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressIndicator(value: count / item.target, minHeight: 7, backgroundColor: Colors.black26, color: _dhikrGold),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: count >= item.target || _loading ? null : () => _increment(index),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('تسبيح'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'إعادة العداد',
                      onPressed: _loading ? null : () => _reset(index),
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
