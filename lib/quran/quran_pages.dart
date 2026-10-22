import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  Future<void> _resumeReading() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surahId = prefs.getInt('last_quran_surah');
      final verseNumber = prefs.getInt('last_quran_verse');
      if (surahId == null || verseNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('بعدك ما حفظت موضع قراءة. افتح سورة واضغط حفظ موضع القراءة عند الآية.')),
          );
        }
        return;
      }
      final chapters = await _readSurahCatalog();
      final matches = chapters.where((chapter) => chapter.id == surahId);
      if (matches.isEmpty || !mounted) {
        return;
      }
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: SurahReaderPage(surah: matches.first, initialVerse: verseNumber),
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر استرجاع موضع القراءة المحفوظ.')),
        );
      }
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
          Row(children: [
            const Expanded(child: Text('فهرس السور', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800))),
            IconButton(
              tooltip: 'متابعة القراءة',
              onPressed: _resumeReading,
              icon: const Icon(Icons.play_circle_outline_rounded, color: _gold),
            ),
            IconButton(
              tooltip: 'البحث داخل الآيات',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: QuranSearchPage()),
              )),
              icon: const Icon(Icons.manage_search_rounded, color: _gold),
            ),
            IconButton(
              tooltip: 'الآيات المحفوظة',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: QuranBookmarksPage()),
              )),
              icon: const Icon(Icons.bookmarks_outlined, color: _gold),
            ),
          ]),
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
        child: Text('فهرس السور محلي. نص الآيات العثماني مضمّن داخل نسخة التطبيق ويعمل دون إنترنت.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 10)),
      ),
    ]);
  }
}


class _QuranVerseMeta {
  const _QuranVerseMeta({required this.juz, required this.hizb, required this.page, this.rub});
  final int juz;
  final int hizb;
  final int page;
  final int? rub;
  factory _QuranVerseMeta.fromJson(Map<String, dynamic> json) => _QuranVerseMeta(
    juz: json['juz'] as int,
    hizb: json['hizb'] as int,
    page: json['page'] as int,
    rub: json['rub'] as int?,
  );
}

Map<String, _QuranVerseMeta>? _quranVerseMetadataCache;

Future<Map<String, _QuranVerseMeta>> _loadQuranVerseMetadata() async {
  final cached = _quranVerseMetadataCache;
  if (cached != null) return cached;
  final data = await rootBundle.load('assets/quran/verse_metadata.json');
  final raw = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final verses = decoded['verses'] as Map<String, dynamic>;
  if (verses.length != 6236) {
    throw FormatException('Expected metadata for 6236 ayahs, got ${verses.length}.');
  }
  final metadata = <String, _QuranVerseMeta>{};
  for (final entry in verses.entries) {
    metadata[entry.key] = _QuranVerseMeta.fromJson(entry.value as Map<String, dynamic>);
  }
  _quranVerseMetadataCache = metadata;
  return metadata;
}

class QuranSearchHit {
  const QuranSearchHit({required this.surah, required this.verseNumber, required this.text});
  final SurahInfo surah;
  final int verseNumber;
  final String text;
}

String _normalizeArabic(String value) {
  // Normalize by Unicode code point: Dart's regex handling of Quranic
  // annotation marks can vary, so remove these marks explicitly.
  final out = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    if ((rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        rune == 0x0640 ||
        (rune >= 0x06D6 && rune <= 0x06ED)) {
      continue;
    }
    switch (rune) {
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0622: // آ
      case 0x0671: // ٱ
        out.write('ا');
      case 0x0649: // ى
        out.write('ي');
      case 0x0624: // ؤ
        out.write('و');
      case 0x0626: // ئ
        out.write('ي');
      default:
        out.write(String.fromCharCode(rune));
    }
  }
  return out.toString();
}

List<SurahInfo>? _surahCatalogCache;

Future<List<SurahInfo>> _readSurahCatalog() async {
  final cached = _surahCatalogCache;
  if (cached != null) return cached;

  final data = await rootBundle.load('assets/quran/chapters.json');
  final raw = utf8.decode(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = (decoded['chapters'] as List<dynamic>)
      .map((e) => SurahInfo.fromJson(e as Map<String, dynamic>)).toList();
  if (list.length != 114) throw const FormatException('Expected 114 surahs.');
  _surahCatalogCache = list;
  return list;
}

class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});
  @override State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final TextEditingController _query = TextEditingController();
  bool _loading = false;
  String? _message;
  List<QuranSearchHit> _hits = const [];

  @override void dispose() { _query.dispose(); super.dispose(); }

  Future<void> _search() async {
    final query = _normalizeArabic(_query.text.trim());
    if (query.length < 2) {
      setState(() { _hits = const []; _message = 'اكتب حرفين على الأقل للبحث.'; });
      return;
    }
    setState(() { _loading = true; _message = null; _hits = const []; });
    try {
      final catalog = await _readSurahCatalog();
      final byId = {for (final s in catalog) s.id: s};
      final chapters = await _loadOfflineQuran();
      final hits = <QuranSearchHit>[];
      for (var surahId = 1; surahId <= 114; surahId++) {
        final surah = byId[surahId]!;
        final verses = chapters[surahId] ?? const <String>[];
        for (var i = 0; i < verses.length; i++) {
          if (_normalizeArabic(verses[i]).contains(query)) {
            hits.add(QuranSearchHit(surah: surah, verseNumber: i + 1, text: verses[i]));
            if (hits.length >= 100) break;
          }
        }
        if (hits.length >= 100) break;
      }
      if (!mounted) return;
      setState(() { _loading = false; _hits = hits; _message = hits.isEmpty ? 'ما لقينا آيات مطابقة.' : 'النتائج الأولى: ${hits.length}'; });
    } catch (error, stackTrace) {
      debugPrint('Quran search failed: $error\\n$stackTrace');
      if (!mounted) return;
      setState(() { _loading = false; _message = 'تعذّر فتح ملف القرآن المحلي. أعد المحاولة.'; });
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البحث في القرآن')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        controller: _query, textInputAction: TextInputAction.search, onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: 'ابحث بكلمة من الآية...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward_rounded)),
          filled: true, fillColor: _panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      )),
      if (_message != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(_message!, style: const TextStyle(color: _muted))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: _gold))
        : _hits.isEmpty
          ? const Center(child: Text('تظهر النتائج هنا', style: TextStyle(color: _muted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: _hits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final hit = _hits[index];
                return Card(color: _panel, child: ListTile(
                  title: Text('${hit.surah.name} • الآية ${hit.verseNumber}', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  subtitle: Text(hit.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, height: 1.8)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: SurahReaderPage(surah: hit.surah, initialVerse: hit.verseNumber),
                  ))),
                ));
              },
            )),
    ]),
  );
}

class QuranBookmarksPage extends StatefulWidget {
  const QuranBookmarksPage({super.key});
  @override State<QuranBookmarksPage> createState() => _QuranBookmarksPageState();
}

class _QuranBookmarksPageState extends State<QuranBookmarksPage> {
  bool _loading = true;
  String? _error;
  List<QuranSearchHit> _items = const [];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refs = prefs.getStringList('quran_bookmarks') ?? const <String>[];
      if (refs.isEmpty) {
        if (!mounted) return;
        setState(() { _items = const []; _loading = false; _error = null; });
        return;
      }
      final catalog = await _readSurahCatalog();
      final byId = {for (final s in catalog) s.id: s};
      final chapters = await _loadOfflineQuran();
      final entries = <QuranSearchHit>[];
      for (final ref in refs) {
        final parts = ref.split(':');
        if (parts.length != 2) continue;
        final id = int.tryParse(parts[0]), verse = int.tryParse(parts[1]);
        if (id == null || verse == null || !byId.containsKey(id)) continue;
        final verses = chapters[id] ?? const <String>[];
        if (verse < 1 || verse > verses.length) continue;
        entries.add(QuranSearchHit(surah: byId[id]!, verseNumber: verse, text: verses[verse - 1]));
      }
      if (!mounted) return;
      setState(() { _items = entries.reversed.toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'تعذّر تحميل الآيات المحفوظة.'; });
    }
  }

  Future<void> _remove(QuranSearchHit hit) async {
    final prefs = await SharedPreferences.getInstance();
    final refs = prefs.getStringList('quran_bookmarks') ?? <String>[];
    refs.remove('${hit.surah.id}:${hit.verseNumber}');
    await prefs.setStringList('quran_bookmarks', refs);
    if (mounted) setState(() => _items.removeWhere((e) => e.surah.id == hit.surah.id && e.verseNumber == hit.verseNumber));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الآيات المحفوظة')),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: _gold))
      : _error != null
        ? _QuranError(message: _error!, onRetry: _load)
        : _items.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('ما عندك آيات محفوظة حالياً. افتح سورة واضغط علامة الحفظ بجانب الآية.', textAlign: TextAlign.center, style: TextStyle(color: _muted, height: 1.6))))
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(color: _panel, child: ListTile(
                  title: Text('${item.surah.name} • الآية ${item.verseNumber}', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  subtitle: Text(item.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, height: 1.7)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: SurahReaderPage(surah: item.surah, initialVerse: item.verseNumber),
                  ))),
                  trailing: IconButton(tooltip: 'إزالة الحفظ', onPressed: () => _remove(item), icon: const Icon(Icons.bookmark_remove_outlined, color: _muted)),
                ));
              },
            ),
  );
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

Map<int, List<String>>? _offlineQuranCache;

/// Cache only completed reads, never the in-flight Future. If an asynchronous
/// read is interrupted or fails, later callers can retry instead of awaiting
/// a permanently pending/failed Future.
Future<Map<int, List<String>>> _loadOfflineQuran() async {
  final cached = _offlineQuranCache;
  if (cached != null) return cached;
  final loaded = await _readBundledQuran();
  _offlineQuranCache = loaded;
  return loaded;
}

Future<Map<int, List<String>>> _readBundledQuran() async {
  // The Quran JSON is larger than 50 KB. AssetBundle.loadString delegates
  // UTF-8 decoding to an isolate for large assets, which can leave widget
  // tests waiting on work started in Flutter's fake-async zone. Load the
  // bytes asynchronously, then decode synchronously; the app's UI already
  // awaits this method, so the file is still read off the build path.
  final data = await rootBundle.load('assets/quran/uthmani_surahs.json');
  final raw = utf8.decode(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final items = decoded['surahs'] as List<dynamic>;
  if (items.length != 114) throw const FormatException('Expected 114 Quran surahs.');
  final chapters = <int, List<String>>{};
  var totalVerses = 0;
  for (var i = 0; i < items.length; i++) {
    final item = items[i] as Map<String, dynamic>;
    final id = item['number'] as int;
    if (id != i + 1) throw const FormatException('Quran surah order is invalid.');
    final rawAyahs = item['ayahs'] as List<dynamic>;
    final verses = <String>[];
    for (var n = 0; n < rawAyahs.length; n++) {
      final ayah = rawAyahs[n] as Map<String, dynamic>;
      if (ayah['number'] != n + 1 || ayah['text'] is! String || (ayah['text'] as String).trim().isEmpty) {
        throw FormatException('Invalid verse in surah $id.');
      }
      verses.add(ayah['text'] as String);
    }
    chapters[id] = verses;
    totalVerses += verses.length;
  }
  if (totalVerses != 6236) throw const FormatException('Quran total ayah count is invalid.');
  return chapters;
}

class SurahReaderPage extends StatefulWidget {
  const SurahReaderPage({
    super.key,
    required this.surah,
    this.initialVerse,
  });
  final SurahInfo surah;
  final int? initialVerse;
  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  bool _loading = true;
  String? _error;
  List<String> _verses = const [];
  Map<String, _QuranVerseMeta> _verseMetadata = const {};
  double _fontSize = 24;
  Set<String> _bookmarks = <String>{};
  bool _keepScreenOn = false;
  final GlobalKey _initialVerseKey = GlobalKey();

  @override
  void initState() { super.initState(); _loadFontSize(); _loadVerses(); }

  @override
  void dispose() {
    if (_keepScreenOn) unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keepOn = prefs.getBool('keep_screen_on_reading') ?? false;
      if (mounted) {
        setState(() {
          _fontSize = (prefs.getDouble('quran_font_size') ?? 24).clamp(16, 34).toDouble();
          _bookmarks = (prefs.getStringList('quran_bookmarks') ?? const <String>[]).toSet();
          _keepScreenOn = keepOn;
        });
      }
      if (keepOn) await WakelockPlus.enable();
    } catch (_) { /* Keep the default text size and reading state. */ }
  }

  Future<void> _setKeepScreenOn(bool value) async {
    setState(() => _keepScreenOn = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('keep_screen_on_reading', value);
      if (value) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تغيير خيار إبقاء الشاشة مفعّلة')),
        );
      }
    }
  }

  Future<void> _showTafsir(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تفسير ${widget.surah.name} — الآية ${index + 1}',
                style: const TextStyle(color: _gold, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SelectableText(_verses[index], textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 22, height: 1.9)),
              const SizedBox(height: 12),
              const Text(
                'هذه نافذة مرجعية للآية. يفتح الزر مكتبة تفسير الميزان على الإنترنت؛ اختر السورة والآية هناك. نص التفسير غير مضمّن دون اتصال في هذه النسخة.',
                style: TextStyle(color: _muted, height: 1.7),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    final opened = await launchUrl(Uri.parse('https://almizan.wilayah.app/'), mode: LaunchMode.externalApplication);
                    if (!opened && sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('تعذّر فتح مكتبة التفسير. تحقق من الإنترنت.')),
                      );
                    }
                  } catch (_) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('تعذّر فتح مكتبة التفسير.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('فتح مكتبة تفسير الميزان'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bookmarkKey(int index) => '${widget.surah.id}:${index + 1}';

  Future<void> _toggleBookmark(int index) async {
    final key = _bookmarkKey(index);
    final next = Set<String>.from(_bookmarks);
    final removed = !next.add(key);
    if (removed) next.remove(key);
    setState(() => _bookmarks = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('quran_bookmarks', next.toList()..sort());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(removed ? 'أُزيلت الآية من المحفوظات' : 'حُفظت الآية للرجوع إليها'),
        duration: const Duration(seconds: 1),
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حفظ الإشارة المرجعية')));
    }
  }

  Future<void> _saveReadingPosition(int verseNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_quran_surah', widget.surah.id);
      await prefs.setInt('last_quran_verse', verseNumber);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حُفظ موضع القراءة: ${widget.surah.name}، الآية $verseNumber'),
        duration: const Duration(seconds: 1),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ موضع القراءة.')),
        );
      }
    }
  }

  Future<void> _loadVerses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final chapters = await _loadOfflineQuran();
      final metadata = await _loadQuranVerseMetadata();
      final verses = chapters[widget.surah.id];
      if (verses == null || verses.length != widget.surah.totalVerses) {
        throw FormatException('Quran asset is missing surah ${widget.surah.id}.');
      }
      if (!mounted) return;
      setState(() { _verses = verses; _verseMetadata = metadata; _loading = false; _error = null; });
      final targetVerse = widget.initialVerse;
      if (targetVerse != null && targetVerse >= 1 && targetVerse <= verses.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetContext = _initialVerseKey.currentContext;
          if (targetContext == null) return;
          unawaited(Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOut,
            alignment: 0.14,
          ));
        });
      }
    } catch (_) {
      _offlineQuranCache = null;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر فتح نص القرآن المرفق. أعد تشغيل التطبيق أو أعد تثبيت نسخة مكتملة البيانات.';
      });
    }
  }

  String _arabicDigits(String value) => value.replaceAllMapped(
    RegExp(r'[0-9]'),
    (match) => '٠١٢٣٤٥٦٧٨٩'[int.parse(match.group(0)!)],
  );

  @override
  Widget build(BuildContext context) {
    final firstMeta = _verseMetadata['${widget.surah.id}:1'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            onPressed: _fontSize <= 16
                ? null
                : () {
                    final next = (_fontSize - 2).clamp(16, 34).toDouble();
                    setState(() => _fontSize = next);
                    unawaited(SharedPreferences.getInstance().then(
                      (prefs) => prefs.setDouble('quran_font_size', next),
                    ));
                  },
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            onPressed: _fontSize >= 34
                ? null
                : () {
                    final next = (_fontSize + 2).clamp(16, 34).toDouble();
                    setState(() => _fontSize = next);
                    unawaited(SharedPreferences.getInstance().then(
                      (prefs) => prefs.setDouble('quran_font_size', next),
                    ));
                  },
            icon: const Icon(Icons.text_increase_rounded),
          ),
          IconButton(
            tooltip: _keepScreenOn
                ? 'إيقاف إبقاء الشاشة مفعّلة'
                : 'إبقاء الشاشة مفعّلة أثناء القراءة',
            onPressed: () => _setKeepScreenOn(!_keepScreenOn),
            icon: Icon(
              _keepScreenOn ? Icons.light_mode_rounded : Icons.light_mode_outlined,
              color: _keepScreenOn ? _gold : _muted,
            ),
          ),
          IconButton(
            tooltip: 'مصدر النص',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'ميثاق المؤمن',
              applicationVersion: '0.1.0',
              children: const [
                Text(
                  'النص العثماني مضمّن داخل التطبيق من مشروع dotquran/corpus الذي ينسب النص إلى Tanzil. لا يغيّر التطبيق كلمات الآيات.',
                ),
              ],
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _gold),
                  SizedBox(height: 16),
                  Text('جارٍ تحميل نص السورة...'),
                ],
              ),
            )
          : _error != null
              ? _QuranError(message: _error!, onRetry: _loadVerses)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                  children: [
                    if (firstMeta != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _panel,
                            border: Border.all(
                              color: _muted.withValues(alpha: .3),
                            ),
                          ),
                          child: Text(
                            'الجزء ${_arabicDigits('${firstMeta.juz}')}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 18, bottom: 28),
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF8E8E8E).withValues(alpha: .7),
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: _muted.withValues(alpha: .75),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'سورة ${widget.surah.name}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: _muted.withValues(alpha: .75),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    if (widget.surah.id != 1 && widget.surah.id != 9)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 22),
                        child: Center(
                          child: Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              color: Colors.white,
                              height: 2,
                            ),
                          ),
                        ),
                      ),
                    ...List.generate(_verses.length, (i) {
                      final isInitialVerse = widget.initialVerse == i + 1;
                      final saved = _bookmarks.contains(
                        '${widget.surah.id}:${i + 1}',
                      );
                      return KeyedSubtree(
                        key: ValueKey('quran-verse-${widget.surah.id}-${i + 1}'),
                        child: Container(
                          key: isInitialVerse ? _initialVerseKey : null,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: isInitialVerse ? 8 : 0,
                          ),
                          decoration: isInitialVerse
                              ? BoxDecoration(
                                  color: _emerald.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _gold.withValues(alpha: .5),
                                  ),
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SelectableText(
                                _verses[i],
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  height: 2.25,
                                  color: Colors.white,
                                  fontFamily: 'AmiriQuran',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '۞ ${_arabicDigits('${i + 1}')} ۞',
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: _gold,
                                      height: 1.5,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'خيارات الآية',
                                    icon: Icon(
                                      saved
                                          ? Icons.bookmark_rounded
                                          : Icons.more_horiz_rounded,
                                      color: saved ? _gold : _muted,
                                      size: 21,
                                    ),
                                    onSelected: (action) async {
                                      switch (action) {
                                        case 'save':
                                          await _saveReadingPosition(i + 1);
                                          break;
                                        case 'bookmark':
                                          await _toggleBookmark(i);
                                          break;
                                        case 'tafsir':
                                          await _showTafsir(i);
                                          break;
                                        case 'copy':
                                          await Clipboard.setData(
                                            ClipboardData(text: _verses[i]),
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('تم نسخ نص الآية'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'save',
                                        child: Row(
                                          children: [
                                            Icon(Icons.bookmark_add_outlined),
                                            SizedBox(width: 10),
                                            Text('حفظ موضع القراءة'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'bookmark',
                                        child: Row(
                                          children: [
                                            Icon(
                                              saved
                                                  ? Icons.bookmark_remove_outlined
                                                  : Icons.bookmark_add_outlined,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              saved
                                                  ? 'إزالة الآية من المحفوظات'
                                                  : 'حفظ الآية في المفضلة',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'tafsir',
                                        child: Row(
                                          children: [
                                            Icon(Icons.menu_book_outlined),
                                            SizedBox(width: 10),
                                            Text('فتح مرجع التفسير'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'copy',
                                        child: Row(
                                          children: [
                                            Icon(Icons.copy_rounded),
                                            SizedBox(width: 10),
                                            Text('نسخ الآية'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'المصدر: مشروع Tanzil عبر dotquran/corpus. نص الآيات لا يتغير. الجزء ظاهر أعلى القراءة فقط؛ أزلنا أرقام الصفحات والتقسيمات من تحت الآيات حتى تبقى القراءة واضحة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
