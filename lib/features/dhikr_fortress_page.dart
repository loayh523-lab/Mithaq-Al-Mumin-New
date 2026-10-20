import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mafatih_library_page.dart';

const _dhikrPanel = Color(0xFF10251E);
const _dhikrGold = Color(0xFFD9B66D);
const _dhikrMuted = Color(0xFF9EB5A9);

class _DhikrItem {
  const _DhikrItem({
    required this.id,
    required this.title,
    required this.text,
    required this.source,
  });

  final String id;
  final String title;
  final String text;
  final String source;
}

class DhikrFortressPage extends StatefulWidget {
  const DhikrFortressPage({super.key, this.initialPeriod = 0});

  /// 0 opens morning-only entries; 1 opens evening-only entries.
  final int initialPeriod;

  @override
  State<DhikrFortressPage> createState() => _DhikrFortressPageState();
}

class _DhikrFortressPageState extends State<DhikrFortressPage> {
  final Map<String, int> _counts = <String, int>{};
  List<_DhikrItem> _items = const <_DhikrItem>[];
  bool _loading = true;
  String? _error;
  int _period = 0;

  String get _periodName => _period == 0 ? 'صباح' : 'مساء';
  String get _periodTitle => _period == 0 ? 'أذكار الصباح' : 'أذكار المساء';
  String get _sourceCategory => _period == 0 ? 'أدعية الصباح' : 'أدعية المساء';

  String _key(String id) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fortress_v4_${_periodName}_${day}_$id';
  }

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod == 1 ? 1 : 0;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _items = const <_DhikrItem>[];
      _counts.clear();
    });

    try {
      final data = await MafatihData.load();
      final items = <_DhikrItem>[];

      for (final chapter in data.chapters) {
        for (final section in chapter.sections) {
          for (final article in section.articles) {
            final contentHead = article.items
                .map((item) => plainMafatihText(item.content))
                .where((value) => value.isNotEmpty)
                .take(3)
                .join(' ');
            final searchable = '${chapter.title} ${section.title} ${article.title} $contentHead';

            // Morning-only and evening-only are separate categories. Entries marked
            // by the source for both periods are kept in the dedicated shared section
            // in the dua library, never duplicated into these two lists.
            if (mafatihCategoryFor(searchable) != _sourceCategory) continue;

            final text = article.items
                .map((item) => plainMafatihText(item.content))
                .where((value) => value.isNotEmpty)
                .join('\n\n')
                .trim();
            if (text.isEmpty) continue;

            items.add(_DhikrItem(
              id: '${chapter.id}_${section.id}_${article.id}',
              title: article.title.trim().isEmpty ? '$_periodTitle ${article.id}' : article.title,
              text: text,
              source: 'مفاتيح الجنان — ${chapter.title} — ${section.title}',
            ));
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final counts = <String, int>{
        for (final item in items) item.id: (prefs.getInt(_key(item.id)) ?? 0),
      };

      if (!mounted) return;
      setState(() {
        _items = items;
        _counts.addAll(counts);
        _loading = false;
        if (items.isEmpty) {
          _error = 'ما لقينا نصوصاً مصنّفة لهذا الوقت في المصدر المحلي. افتح مكتبة مفاتيح الجنان للتحقق من الفهرس.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل النصوص العربية. تحقق من اكتمال ملف مكتبة مفاتيح الجنان ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _setPeriod(int period) async {
    if (period == _period) return;
    setState(() => _period = period == 1 ? 1 : 0);
    await _load();
  }

  Future<void> _increment(_DhikrItem item) async {
    final next = (_counts[item.id] ?? 0) + 1;
    HapticFeedback.lightImpact();
    setState(() => _counts[item.id] = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(item.id), next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ عدّاد الذكر على الجهاز')),
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
          const SnackBar(content: Text('تعذّر إعادة العداد إلى الصفر')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_periodTitle)),
    body: Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _dhikrPanel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _dhikrGold.withValues(alpha: .3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _periodTitle,
                style: const TextStyle(color: _dhikrGold, fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 6),
              const Text(
                'النصوص مأخوذة من المكتبة العربية المرفقة. تُعرض أذكار الصباح والمساء في قائمتين منفصلتين؛ والعداد للمتابعة فقط ما لم يذكر المصدر عدداً صريحاً.',
                style: TextStyle(color: _dhikrMuted, height: 1.65),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('أذكار الصباح'), icon: Icon(Icons.wb_sunny_outlined)),
              ButtonSegment(value: 1, label: Text('أذكار المساء'), icon: Icon(Icons.nights_stay_outlined)),
            ],
            selected: {_period},
            onSelectionChanged: (selection) => _setPeriod(selection.first),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: _dhikrGold)))
        else if (_items.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, color: _dhikrGold, size: 42),
                    const SizedBox(height: 12),
                    Text(_error ?? 'لا توجد نصوص في هذا القسم.', textAlign: TextAlign.center, style: const TextStyle(color: _dhikrMuted, height: 1.7)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: MafatihCategoryPage(initialCategory: _sourceCategory),
                        ),
                      )),
                      child: const Text('فتح الفهرس العربي'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                final count = _counts[item.id] ?? 0;
                return Card(
                  color: _dhikrPanel,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(color: _dhikrGold, fontWeight: FontWeight.w800, fontSize: 17, height: 1.6)),
                        const SizedBox(height: 10),
                        SelectableText(
                          item.text,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 19, height: 1.9),
                        ),
                        const SizedBox(height: 10),
                        Text('المصدر: ${item.source}', style: const TextStyle(color: _dhikrMuted, height: 1.5, fontSize: 11)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _increment(item),
                                icon: const Icon(Icons.fingerprint_rounded),
                                label: Text('تسبيح • $count'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'إعادة العداد',
                              onPressed: () => _reset(item),
                              icon: const Icon(Icons.restart_alt_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}
