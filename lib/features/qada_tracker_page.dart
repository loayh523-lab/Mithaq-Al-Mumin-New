import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _qadaGold = Color(0xFFD9B66D);
const _qadaMuted = Color(0xFF697A70);

class _QadaItem {
  const _QadaItem(this.keyName, this.title, this.unit, this.description);
  final String keyName;
  final String title;
  final String unit;
  final String description;
}

class QadaTrackerPage extends StatefulWidget {
  const QadaTrackerPage({super.key});
  @override
  State<QadaTrackerPage> createState() => _QadaTrackerPageState();
}

class _QadaTrackerPageState extends State<QadaTrackerPage> {
  static const _items = <_QadaItem>[
    _QadaItem('fajr', 'صلاة الصبح', 'صلاة', 'عدد الصلوات التي سجّلتها للقضاء'),
    _QadaItem('dhuhr', 'صلاة الظهر', 'صلاة', 'عدد الصلوات التي سجّلتها للقضاء'),
    _QadaItem('asr', 'صلاة العصر', 'صلاة', 'عدد الصلوات التي سجّلتها للقضاء'),
    _QadaItem('maghrib', 'صلاة المغرب', 'صلاة', 'عدد الصلوات التي سجّلتها للقضاء'),
    _QadaItem('isha', 'صلاة العشاء', 'صلاة', 'عدد الصلوات التي سجّلتها للقضاء'),
    _QadaItem('fasting', 'صيام القضاء', 'يوم', 'عدد أيام الصيام التي سجّلتها للقضاء'),
  ];

  final Map<String, int> _counts = <String, int>{};
  bool _loading = true;

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
        for (final item in _items) {
          _counts[item.keyName] = (prefs.getInt('qada_${item.keyName}') ?? 0).clamp(0, 100000);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(_QadaItem item, int change) async {
    final next = ((_counts[item.keyName] ?? 0) + change).clamp(0, 100000);
    setState(() => _counts[item.keyName] = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('qada_${item.keyName}', next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ سجل القضاء على الجهاز')),
        );
      }
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط سجل القضاء؟'),
        content: const Text('سيُصفّر هذا السجل المحلي. تأكد من تدوين أرقامك قبل المتابعة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تصفير السجل')),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    for (final item in _items) {
      await prefs.remove('qada_${item.keyName}');
    }
    if (!mounted) return;
    setState(() {
      for (final item in _items) {
        _counts[item.keyName] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPrayers = _items.take(5).fold<int>(0, (total, item) => total + (_counts[item.keyName] ?? 0));
    final fastingDays = _counts['fasting'] ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل القضاء'),
        actions: [
          IconButton(
            tooltip: 'تصفير السجل',
            onPressed: _loading ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _qadaGold.withValues(alpha: .3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('متابعة ما في الذمّة', style: TextStyle(color: _qadaGold, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('هذا سجلّ شخصي للأعداد التي تدخلها بنفسك، ولا يحسب الواجب الشرعي أو مدته تلقائياً.', style: TextStyle(color: _qadaMuted, height: 1.7)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _summary('الصلوات', '$totalPrayers')),
                const SizedBox(width: 10),
                Expanded(child: _summary('أيام الصيام', '$fastingDays')),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _qadaGold)))
          else
            ..._items.map((item) => Card(
              color: Theme.of(context).colorScheme.surface,
              margin: const EdgeInsets.only(bottom: 9),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(color: _qadaMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    IconButton.filledTonal(
                      onPressed: (_counts[item.keyName] ?? 0) > 0 ? () => _change(item, -1) : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_counts[item.keyName] ?? 0} ${item.unit}',
                          style: const TextStyle(color: _qadaGold, fontWeight: FontWeight.w800, fontSize: 21),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: (_counts[item.keyName] ?? 0) < 100000 ? () => _change(item, 1) : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ]),
                ]),
              ),
            )),
          const SizedBox(height: 8),
          const Text('في تقدير ما يجب قضاؤه وتفاصيله، راجع فتوى مكتب مرجع تقليدك؛ هذه الشاشة لا تصدر حكماً فقهياً.', style: TextStyle(color: _qadaMuted, height: 1.7, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summary(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _qadaMuted, fontSize: 12)),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(color: _qadaGold, fontSize: 23, fontWeight: FontWeight.w800)),
    ]),
  );
}
