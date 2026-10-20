import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _deedPanel = Color(0xFF10251E);
const _deedGold = Color(0xFFD9B66D);
const _deedMuted = Color(0xFF9EB5A9);

class _Deed {
  const _Deed(this.title, this.description);
  final String title;
  final String description;
}

class GoodDeedsPage extends StatefulWidget {
  const GoodDeedsPage({super.key});
  @override State<GoodDeedsPage> createState() => _GoodDeedsPageState();
}

class _GoodDeedsPageState extends State<GoodDeedsPage> {
  static const _deeds = <_Deed>[
    _Deed('قراءة القرآن الكريم', 'اقرأ ما تيسّر لك من القرآن بتدبّر.'),
    _Deed('الصلاة على محمد وآل محمد', 'اجعل لك ورداً من الصلاة على النبي وآله.'),
    _Deed('الاستغفار', 'خصّص وقتاً للاستغفار والتوبة.'),
    _Deed('تسبيح الزهراء عليها السلام', 'حافظ عليه بعد الصلاة أو في وقت مناسب.'),
    _Deed('الإحسان إلى الأهل', 'ساعد أحداً من أهلك أو أدخل السرور عليه.'),
    _Deed('صلة الرحم', 'اسأل عن قريب أو صِل من انقطعت أخباره.'),
    _Deed('صدقة أو مساعدة', 'قدّم مساعدة بحسب الاستطاعة.'),
    _Deed('قراءة دعاء أو زيارة', 'اختر نصاً مناسباً من المكتبة الدينية.'),
    _Deed('مراجعة النفس', 'راجع يومك واعزم على إصلاح ما تستطيع.'),
    _Deed('دعاء الفرج', 'اقرأ الدعاء بنية القرب إلى الله وتعجيل الفرج.'),
  ];

  final Set<int> _completed = <int>{};
  bool _loading = true;
  String get _key {
    final now = DateTime.now();
    return 'good_deeds_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_key) ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addAll(values.map(int.tryParse).whereType<int>().where((i) => i >= 0 && i < _deeds.length));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int index, bool checked) async {
    setState(() {
      if (checked) {
        _completed.add(index);
      } else {
        _completed.remove(index);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, (_completed.toList()..sort()).map((i) => i.toString()).toList());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ الأعمال على الجهاز')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('صالح الأعمال')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _deedPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _deedGold.withValues(alpha: .3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ورد اليوم', style: TextStyle(color: _deedGold, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('أعمال مقترحة وليست كلها واجبة. اختر ما يناسب وقتك وقدرتك، ويُحفظ إنجازك لهذا اليوم على الجهاز.', style: TextStyle(color: _deedMuted, height: 1.7)),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _completed.length / _deeds.length, minHeight: 8, backgroundColor: Colors.black26, color: _deedGold, borderRadius: BorderRadius.circular(20)),
            const SizedBox(height: 8),
            Text('${_completed.length} من ${_deeds.length} أعمال', style: const TextStyle(color: _deedGold, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _deedGold)))
        else
          ...List.generate(_deeds.length, (index) {
            final deed = _deeds[index];
            return Card(
              color: _deedPanel,
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: _completed.contains(index),
                activeColor: _deedGold,
                checkColor: Colors.black,
                onChanged: (value) => _toggle(index, value ?? false),
                title: Text(deed.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(deed.description, style: const TextStyle(color: _deedMuted, height: 1.5)),
                secondary: const Icon(Icons.volunteer_activism_rounded, color: _deedGold),
              ),
            );
          }),
      ],
    ),
  );
}
