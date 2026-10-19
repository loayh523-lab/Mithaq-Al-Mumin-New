import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const _ink = Color(0xFF071713);
const _panel = Color(0xFF10251E);
const _emerald = Color(0xFF1C8060);
const _gold = Color(0xFFD9B66D);
const _muted = Color(0xFF9EB5A9);

class SurahInfo {
  const SurahInfo({required this.id, required this.name, required this.transliteration, required this.type, required this.totalVerses});
  final int id;
  final String name;
  final String transliteration;
  final String type;
  final int totalVerses;
  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
    id: j['id'] as int,
    name: j['name'] as String,
    transliteration: j['transliteration'] as String,
    type: j['type'] as String,
    totalVerses: j['total_verses'] as int,
  );
}

class QuranIndexPage extends StatefulWidget {
  const QuranIndexPage({super.key});
  @override
  State<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends State<QuranIndexPage> {
  final _search = TextEditingController();
  List<SurahInfo> _chapters = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadCatalog(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadCatalog() async {
    try {
      final source = await rootBundle.loadString('assets/quran/chapters.json');
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      final raw = decoded['chapters'] as List<dynamic>;
      final chapters = raw.map((e) => SurahInfo.fromJson(e as Map<String, dynamic>)).toList();
      if (chapters.length != 114) throw const FormatException('Expected 114 surahs.');
      if (!mounted) return;
      setState(() { _chapters = chapters; _loading = false; _error = null; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذّر تحميل فهرس السور المرفق بالتطبيق.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = _chapters.where((s) => q.isEmpty || s.name.contains(q) || s.transliteration.toLowerCase().contains(q) || s.id.toString() == q).toList();
    final verseCount = _chapters.fold<int>(0, (n, s) => n + s.totalVerses);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('فهرس السور', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(_loading ? 'جارٍ تجهيز فهرس القرآن الكريم...' : '114 سورة • $verseCount آية', style: const TextStyle(color: _muted)),
          const SizedBox(height: 14),
          TextField(
            controller: _search, onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة أو رقمها...', prefixIcon: const Icon(Icons.search_rounded),
              filled: true, fillColor: _panel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ]),
      ),
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
            ? _QuranError(message: _error!, onRetry: _loadCatalog)
            : filtered.isEmpty
              ? const Center(child: Text('ماكو سورة تطابق البحث', style: TextStyle(color: _muted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return Card(
                      margin: EdgeInsets.zero, color: _panel,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _emerald.withValues(alpha: .24), child: Text('${s.id}', style: const TextStyle(color: _gold))),
                        title: Text(s.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                        subtitle: Text('${s.type == 'meccan' ? 'مكية' : 'مدنية'} • ${s.totalVerses} آية', style: const TextStyle(color: _muted, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_left_rounded, color: _gold),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SurahReaderPage(surah: s)),
                        )),
                      ),
                    );
                  },
                ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: Text('فهرس السور من Quran JSON / Tanzil. نص الآيات يحتاج الإنترنت.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 10)),
      ),
    ]);
  }
}

class _QuranError extends StatelessWidget {
  const _QuranError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: _gold, size: 42),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
    ]),
  ));
}

class SurahReaderPage extends StatefulWidget {
  const SurahReaderPage({super.key, required this.surah});
  final SurahInfo surah;
  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  bool _loading = true;
  String? _error;
  List<String> _verses = const [];

  @override
  void initState() { super.initState(); _loadVerses(); }

  Future<void> _loadVerses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.https('quran-json.risanb.com', '/text/uthmani/chapters/${widget.surah.id}.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw FormatException('HTTP ${response.statusCode}');
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final raw = decoded['verses'] as List<dynamic>;
      final verses = raw.map((e) {
        final text = (e as Map<String, dynamic>)['text'];
        if (text is! String || text.trim().isEmpty) throw const FormatException('Missing verse text.');
        return text;
      }).toList();
      if (verses.length != widget.surah.totalVerses) throw const FormatException('Verse count mismatch.');
      if (!mounted) return;
      setState(() { _verses = verses; _loading = false; _error = null; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'ما قدرنا نحمّل نص السورة. تأكد من الإنترنت وحاول مرة ثانية.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.surah.name),
      actions: [IconButton(
        tooltip: 'مصدر النص',
        onPressed: () => showAboutDialog(
          context: context, applicationName: 'ميثاق المؤمن', applicationVersion: '0.1.0',
          children: const [Text('نص القرآن العثماني محمّل من Quran JSON، الذي يذكر Tanzil مصدراً للنصوص العثمانية المنشورة.')],
        ),
        icon: const Icon(Icons.info_outline_rounded),
      )],
    ),
    body: _loading
      ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: _gold), SizedBox(height: 16), Text('جارٍ تحميل نص السورة...'),
        ]))
      : _error != null
        ? _QuranError(message: _error!, onRetry: _loadVerses)
        : ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withValues(alpha: .35))),
              child: Column(children: [
                Text(widget.surah.name, style: const TextStyle(color: _gold, fontSize: 27, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${widget.surah.type == 'meccan' ? 'مكية' : 'مدنية'} • ${_verses.length} آية', style: const TextStyle(color: _muted)),
              ]),
            ),
            if (widget.surah.id != 1 && widget.surah.id != 9)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, color: _gold, height: 2))),
              ),
            ...List.generate(_verses.length, (i) => Container(
              margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .05))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(_verses[i], textAlign: TextAlign.justify, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 24, height: 2.1)),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: _emerald, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                  const Spacer(),
                  IconButton(
                    tooltip: 'نسخ الآية',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _verses[i]));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص الآية')));
                    },
                    icon: const Icon(Icons.copy_rounded, color: _muted, size: 19),
                  ),
                ]),
              ]),
            )),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('المصدر: Quran JSON — النص العثماني المنشور مع إحالة إلى Tanzil. قد لا تعمل القراءة دون الإنترنت.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 11, height: 1.6)),
            ),
          ]),
  );
}
