import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../quran/quran_pages.dart';
import 'mafatih_library_page.dart';
import 'shia_text_library_page.dart';

const _searchPanel = Color(0xFF10251E);
const _searchGold = Color(0xFFD9B66D);
const _searchMuted = Color(0xFF9EB5A9);

class SmartSearchPage extends StatefulWidget {
  const SmartSearchPage({super.key});
  @override
  State<SmartSearchPage> createState() => _SmartSearchPageState();
}

class _SmartSearchHit {
  const _SmartSearchHit({
    required this.title,
    required this.category,
    required this.preview,
    required this.openPage,
  });
  final String title;
  final String category;
  final String preview;
  final Widget Function() openPage;
}

class _SmartSearchPageState extends State<SmartSearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _message;
  List<_SmartSearchHit> _hits = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\\u064B-\\u065F\\u0670\\u0640\\u06D6-\\u06ED]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');

  String _plainText(String value) => value
      .replaceAll(RegExp(r'<br\\s*/?>', caseSensitive: false), '\\n')
      .replaceAll(RegExp(r'</(p|div|li|h[1-6])\\s*>', caseSensitive: false), '\\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();

  Future<void> _search() async {
    final query = _normalize(_controller.text.trim());
    if (query.length < 2) {
      setState(() {
        _hits = const [];
        _message = 'اكتب حرفين على الأقل للبحث في المصادر المحلية.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _hits = const [];
    });
    final results = <_SmartSearchHit>[];

    // Search the bundled Quran text, preserving verse text as stored by its source.
    try {
      final catalogSource = await rootBundle.loadString('assets/quran/chapters.json');
      final catalogJson = jsonDecode(catalogSource) as Map<String, dynamic>;
      final catalog = (catalogJson['chapters'] as List<dynamic>)
          .map((entry) => SurahInfo.fromJson(entry as Map<String, dynamic>))
          .toList();
      final byId = {for (final surah in catalog) surah.id: surah};
      final data = await rootBundle.load('assets/quran/uthmani_surahs.json');
      final raw = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      final quranJson = jsonDecode(raw) as Map<String, dynamic>;
      for (final rawSurah in quranJson['surahs'] as List<dynamic>) {
        final surahJson = rawSurah as Map<String, dynamic>;
        final id = (surahJson['number'] ?? surahJson['numberInQuran']) as int;
        final surah = byId[id];
        if (surah == null) continue;
        for (final rawAyah in surahJson['ayahs'] as List<dynamic>) {
          final ayah = rawAyah as Map<String, dynamic>;
          final text = ayah['text'] as String? ?? '';
          if (!_normalize(text).contains(query)) continue;
          final verse = (ayah['number'] ?? ayah['numberInSurah'] ?? 0) as int;
          results.add(_SmartSearchHit(
            title: '${surah.name} — الآية $verse',
            category: 'القرآن الكريم',
            preview: text,
            openPage: () => Directionality(
              textDirection: TextDirection.rtl,
              child: SurahReaderPage(surah: surah, initialVerse: verse),
            ),
          ));
          if (results.length >= 35) break;
        }
        if (results.length >= 35) break;
      }
    } catch (_) {
      // Other text libraries remain searchable if the Quran asset is unavailable.
    }

    // Search all cached Mafatih chapters, sections, article titles and content.
    try {
      final data = await MafatihData.load();
      for (final chapter in data.chapters) {
        for (final section in chapter.sections) {
          for (final article in section.articles) {
            final text = article.items.map((item) => _plainText(item.content)).join(' ');
            final searchable = _normalize('${chapter.title} ${section.title} ${article.title} $text');
            if (!searchable.contains(query)) continue;
            results.add(_SmartSearchHit(
              title: article.title,
              category: 'مفاتيح الجنان • ${section.title}',
              preview: text,
              openPage: () => Directionality(
                textDirection: TextDirection.rtl,
                child: MafatihArticlePage(article: article),
              ),
            ));
            if (results.length >= 75) break;
          }
          if (results.length >= 75) break;
        }
        if (results.length >= 75) break;
      }
    } catch (_) {
      // Keep results from sources that did load.
    }

    // Search Arabic dua/ziyara and Sahifa text supplied with the app.
    try {
      final data = await ShiaTextData.load();
      for (final entry in data.entries) {
        final searchable = _normalize('${entry.displayTitle} ${entry.title} ${entry.slug} ${entry.arabicText}');
        if (!searchable.contains(query)) continue;
        results.add(_SmartSearchHit(
          title: entry.displayTitle,
          category: entry.isSahifa ? 'الصحيفة السجادية' : (entry.isZiyara ? 'الزيارات' : 'الأدعية'),
          preview: entry.arabicText,
          openPage: () => Directionality(
            textDirection: TextDirection.rtl,
            child: ShiaTextReaderPage(entry: entry),
          ),
        ));
        if (results.length >= 100) break;
      }
    } catch (_) {
      // Results from the other libraries remain useful.
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _hits = results;
      _message = results.isEmpty
          ? 'لم نجد نتيجة مطابقة في النصوص المرفقة. جرّب عبارة أقصر.'
          : 'عدد النتائج: ${results.length} — البحث يعمل دون إنترنت.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الباحث الذكي')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'ابحث في القرآن والأدعية والزيارات...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            filled: true,
            fillColor: _searchPanel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(_message!, style: const TextStyle(color: _searchMuted, height: 1.5)),
        ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _searchGold))
            : _hits.isEmpty
                ? const Center(child: Text('اكتب عبارة ثم اضغط البحث', style: TextStyle(color: _searchMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _hits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final hit = _hits[index];
                      return Card(
                        color: _searchPanel,
                        child: ListTile(
                          title: Text(hit.title, style: const TextStyle(color: _searchGold, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hit.category, style: const TextStyle(color: _searchMuted, fontSize: 11)),
                              const SizedBox(height: 6),
                              Text(hit.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.6)),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_left_rounded, color: _searchGold),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => hit.openPage()),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]),
  );
}
