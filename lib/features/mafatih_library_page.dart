import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _mfPanel = Color(0xFF10251E);
const _mfGold = Color(0xFFD9B66D);
const _mfMuted = Color(0xFF9EB5A9);

String _arabicOnlyTitle(Object? value, String fallback) {
  final title = value is String ? value : '';
  return RegExp(r'[پچژگکی]').hasMatch(title) ? fallback : title;
}

class MafatihItem {
  const MafatihItem({required this.type, required this.content});
  final String type;
  final String content;
  factory MafatihItem.fromJson(Map<String, dynamic> json) => MafatihItem(
    type: json['type'] is String ? json['type'] as String : 'text',
    content: json['content'] is String ? json['content'] as String : '',
  );
}

class MafatihArticle {
  const MafatihArticle({required this.id, required this.title, required this.items, this.href = ''});
  final int id;
  final String title;
  final String href;
  final List<MafatihItem> items;
  factory MafatihArticle.fromJson(Map<String, dynamic> json) => MafatihArticle(
    id: json['id'] is int ? json['id'] as int : 0,
    title: _arabicOnlyTitle(json['title'], 'نص عربي'),
    href: json['href'] is String ? json['href'] as String : '',
    items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>().map(MafatihItem.fromJson).toList(),
  );
}

class MafatihSection {
  const MafatihSection({required this.id, required this.title, required this.articles});
  final int id;
  final String title;
  final List<MafatihArticle> articles;
  factory MafatihSection.fromJson(Map<String, dynamic> json) => MafatihSection(
    id: json['id'] is int ? json['id'] as int : 0,
    title: _arabicOnlyTitle(json['title'], 'قسم عربي'),
    articles: ((json['articles'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>().map(MafatihArticle.fromJson).toList(),
  );
}

class MafatihChapter {
  const MafatihChapter({required this.id, required this.title, required this.sections});
  final int id;
  final String title;
  final List<MafatihSection> sections;
  factory MafatihChapter.fromJson(Map<String, dynamic> json) => MafatihChapter(
    id: json['id'] is int ? json['id'] as int : 0,
    title: _arabicOnlyTitle(json['title'], 'باب من مفاتيح الجنان'),
    sections: ((json['sections'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>().map(MafatihSection.fromJson).toList(),
  );
}

class MafatihData {
  const MafatihData({required this.chapters, required this.source});
  final List<MafatihChapter> chapters;
  final String source;
  static Future<MafatihData>? _cache;

  static Future<MafatihData> load() => _cache ??= _load();
  static Future<MafatihData> _load() async {
    final raw = await rootBundle.loadString('assets/mafatih/mafatih.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawChapters = decoded['chapters'] as List<dynamic>;
    final chapters = rawChapters.whereType<Map<String, dynamic>>().map(MafatihChapter.fromJson).toList();
    if (chapters.isEmpty) throw const FormatException('Mafatih library is empty.');
    final metadata = decoded['metadata'] as Map<String, dynamic>? ?? const {};
    final source = metadata['upstream_project'] is String
        ? metadata['upstream_project'] as String
        : 'aminpaydar/Mafatih';
    return MafatihData(chapters: chapters, source: source);
  }
}

class MafatihLibraryPage extends StatefulWidget {
  const MafatihLibraryPage({super.key});
  @override State<MafatihLibraryPage> createState() => _MafatihLibraryPageState();
}

class _MafatihLibraryPageState extends State<MafatihLibraryPage> {
  final _search = TextEditingController();
  late Future<MafatihData> _dataFuture;
  @override void initState() { super.initState(); _dataFuture = MafatihData.load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مفاتيح الجنان'),
      actions: [
        IconButton(
          tooltip: 'البحث في المكتبة',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: MafatihSearchPage()),
          )),
          icon: const Icon(Icons.search_rounded, color: _mfGold),
        ),
      ],
    ),
    body: FutureBuilder<MafatihData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _error('تعذّر قراءة ملف النصوص المرفق.', () {
            setState(() { MafatihData._cache = null; _dataFuture = MafatihData.load(); });
          });
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _mfGold));
        }
        final data = snapshot.data!;
        final query = _normalizeTitle(_search.text.trim());
        final filtered = data.chapters.where((c) => query.isEmpty || _normalizeTitle(c.title).contains(query)).toList();
        return Column(children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _mfPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _mfGold.withValues(alpha: .3)),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مكتبة أدعية وزيارات', style: TextStyle(color: _mfGold, fontSize: 21, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('نصوص مفاتيح الجنان مضمّنة في نسخة التطبيق؛ تقدر تتصفحها دون إنترنت.', style: TextStyle(color: _mfMuted, height: 1.6)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث عن باب...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true, fillColor: _mfPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: filtered.isEmpty
            ? const Center(child: Text('ماكو أبواب مطابقة', style: TextStyle(color: _mfMuted)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final chapter = filtered[index];
                  final articles = chapter.sections.fold<int>(0, (sum, section) => sum + section.articles.length);
                  return Card(
                    color: _mfPanel,
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: _mfGold.withValues(alpha: .15), child: const Icon(Icons.auto_stories_rounded, color: _mfGold)),
                      title: Text(_arabicOnlyTitle(chapter.title, 'باب ${chapter.id} من مفاتيح الجنان'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${chapter.sections.length} أقسام • $articles نصوص', style: const TextStyle(color: _mfMuted)),
                      trailing: const Icon(Icons.chevron_left_rounded, color: _mfGold),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => Directionality(textDirection: TextDirection.rtl, child: MafatihSectionsPage(chapter: chapter)),
                      )),
                    ),
                  );
                },
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Text('المصدر: ${data.source} • الترخيص والإسناد في صفحة المصادر.', textAlign: TextAlign.center, style: const TextStyle(color: _mfMuted, fontSize: 10)),
          ),
        ]);
      },
    ),
  );
}

class MafatihSectionsPage extends StatelessWidget {
  const MafatihSectionsPage({super.key, required this.chapter});
  final MafatihChapter chapter;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_arabicOnlyTitle(chapter.title, 'باب ${chapter.id} من مفاتيح الجنان'))),
    body: ListView.separated(
      padding: const EdgeInsets.all(16), itemCount: chapter.sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final section = chapter.sections[index];
        return Card(color: _mfPanel, child: ListTile(
          leading: const Icon(Icons.folder_open_rounded, color: _mfGold),
          title: Text(_arabicOnlyTitle(section.title, 'قسم ${section.id}'), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${section.articles.length} نصوص', style: const TextStyle(color: _mfMuted)),
          trailing: const Icon(Icons.chevron_left_rounded, color: _mfGold),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Directionality(textDirection: TextDirection.rtl, child: MafatihArticlesPage(section: section)),
          )),
        ));
      },
    ),
  );
}

class MafatihArticlesPage extends StatelessWidget {
  const MafatihArticlesPage({super.key, required this.section});
  final MafatihSection section;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_arabicOnlyTitle(section.title, 'قسم ${section.id}'))),
    body: ListView.separated(
      padding: const EdgeInsets.all(16), itemCount: section.articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final article = section.articles[index];
        final preview = article.items.map((item) => _plainText(item.content)).where((s) => s.isNotEmpty).take(2).join(' ');
        return Card(color: _mfPanel, child: ListTile(
          title: Text(_arabicOnlyTitle(article.title, 'نص عربي ${article.id}'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: preview.isEmpty ? null : Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mfMuted)),
          trailing: const Icon(Icons.chevron_left_rounded, color: _mfGold),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Directionality(textDirection: TextDirection.rtl, child: MafatihArticlePage(article: article)),
          )),
        ));
      },
    ),
  );
}

class MafatihArticlePage extends StatefulWidget {
  const MafatihArticlePage({super.key, required this.article});
  final MafatihArticle article;
  @override State<MafatihArticlePage> createState() => _MafatihArticlePageState();
}

class _MafatihArticlePageState extends State<MafatihArticlePage> {
  double _fontSize = 22;
  bool _focusMode = false;

  Future<void> _toggleFocusMode() async {
    final next = !_focusMode;
    setState(() => _focusMode = next);
    await SystemChrome.setEnabledSystemUIMode(next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    if (_focusMode) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool _looksPersian(String text) => RegExp(r'[پچژگکی]').hasMatch(text);

  bool _isArabicRecitationType(String type) {
    final normalized = type.trim().toLowerCase();
    return normalized == 'text' || normalized == 'arabic' || normalized == 'arabictext' || normalized == 'arabic_text';
  }

  @override Widget build(BuildContext context) {
    final chunks = widget.article.items
        .where((item) => _isArabicRecitationType(item.type))
        .map((item) => (type: item.type, text: _plainText(item.content)))
        .where((item) => item.text.trim().isNotEmpty && !_looksPersian(item.text))
        .toList();
    final wholeText = chunks.map((item) => item.text).join('\n\n');
    return Scaffold(
      appBar: _focusMode ? null : AppBar(
        title: Text(_arabicOnlyTitle(widget.article.title, 'نص عربي من مفاتيح الجنان'), maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'وضع القراءة الخاشعة',
            onPressed: _toggleFocusMode,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
          IconButton(
          tooltip: 'نسخ النص',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: wholeText));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
          },
          icon: const Icon(Icons.copy_rounded),
        )],
      ),
      floatingActionButton: _focusMode
        ? FloatingActionButton.small(onPressed: _toggleFocusMode, tooltip: 'إنهاء وضع القراءة الخاشعة', child: const Icon(Icons.close_rounded))
        : null,
      body: Column(children: [
        if (!_focusMode) Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(children: [
            Row(children: [
            const Icon(Icons.text_fields_rounded, color: _mfGold),
            Expanded(child: Slider(value: _fontSize, min: 16, max: 34, divisions: 9, label: _fontSize.round().toString(), onChanged: (value) => setState(() => _fontSize = value), activeColor: _mfGold)),
            Text('${_fontSize.round()}', style: const TextStyle(color: _mfMuted)),
            ]),
          ]),
        ),
        Expanded(child: chunks.isEmpty
          ? const Center(child: Text('هذا العنوان ما يحتوي نصاً قابلاً للعرض.', style: TextStyle(color: _mfMuted)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _mfPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _mfGold.withValues(alpha: .3))),
                  child: Text(_arabicOnlyTitle(widget.article.title, 'نص عربي من مفاتيح الجنان'), textAlign: TextAlign.center, style: const TextStyle(color: _mfGold, fontSize: 23, fontWeight: FontWeight.w800, height: 1.7)),
                ),
                ...chunks.map((chunk) {
                  final label = chunk.type.toLowerCase();
                  final isHeading = label.contains('title') || label.contains('header') || label.contains('heading');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: SelectableText(
                      chunk.text,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: isHeading ? _fontSize + 2 : _fontSize, height: 2.0, fontWeight: isHeading ? FontWeight.bold : FontWeight.normal, color: isHeading ? _mfGold : Colors.white),
                    ),
                  );
                }),
                const Divider(color: Color(0x334A7562)),
                const Text('المصدر: مكتبة مفاتيح الجنان المنشورة في مشروع aminpaydar/Mafatih. قد تختلف الترقيمات والاختيارات بين الطبعات؛ راجع الأصل عند الحاجة إلى توثيق دقيق.', style: TextStyle(color: _mfMuted, height: 1.7, fontSize: 11)),
              ],
            )),
      ]),
    );
  }
}

class MafatihSearchPage extends StatefulWidget {
  const MafatihSearchPage({super.key});
  @override State<MafatihSearchPage> createState() => _MafatihSearchPageState();
}

class _MafatihSearchPageState extends State<MafatihSearchPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;
  List<_MafatihSearchHit> _hits = const [];
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _runSearch() async {
    final query = _normalizeTitle(_controller.text.trim());
    if (query.length < 2) {
      setState(() { _hits = const []; _message = 'اكتب حرفين على الأقل.'; });
      return;
    }
    setState(() { _loading = true; _message = null; _hits = const []; });
    try {
      final data = await MafatihData.load();
      final hits = <_MafatihSearchHit>[];
      for (final chapter in data.chapters) {
        for (final section in chapter.sections) {
          for (final article in section.articles) {
            final titleMatches = _normalizeTitle(article.title).contains(query) || _normalizeTitle(section.title).contains(query);
            final textMatches = !titleMatches && article.items.any((item) => _normalizeTitle(_plainText(item.content)).contains(query));
            if (titleMatches || textMatches) {
              hits.add(_MafatihSearchHit(chapter: chapter, section: section, article: article));
              if (hits.length >= 100) break;
            }
          }
          if (hits.length >= 100) break;
        }
        if (hits.length >= 100) break;
      }
      if (!mounted) return;
      setState(() { _loading = false; _hits = hits; _message = hits.isEmpty ? 'ما لقينا نتائج مطابقة.' : 'أول ${hits.length} نتيجة مطابقة'; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _message = 'تعذّر فتح المكتبة المحلية. أعد المحاولة.'; });
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البحث في مفاتيح الجنان')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _runSearch(),
        decoration: InputDecoration(
          hintText: 'ابحث بعنوان أو عبارة من النص...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(onPressed: _runSearch, icon: const Icon(Icons.arrow_forward_rounded)),
          filled: true, fillColor: _mfPanel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      )),
      if (_message != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_message!, style: const TextStyle(color: _mfMuted))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: _mfGold))
        : _hits.isEmpty
          ? const Center(child: Text('تظهر نتائج البحث هنا', style: TextStyle(color: _mfMuted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: _hits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final hit = _hits[index];
                return Card(color: _mfPanel, child: ListTile(
                  title: Text(hit.article.title, style: const TextStyle(color: _mfGold, fontWeight: FontWeight.bold)),
                  subtitle: Text('${hit.chapter.title} • ${hit.section.title}', style: const TextStyle(color: _mfMuted)),
                  trailing: const Icon(Icons.chevron_left_rounded, color: _mfGold),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => Directionality(textDirection: TextDirection.rtl, child: MafatihArticlePage(article: hit.article)),
                  )),
                ));
              },
            )),
    ]),
  );
}

class _MafatihSearchHit {
  const _MafatihSearchHit({required this.chapter, required this.section, required this.article});
  final MafatihChapter chapter;
  final MafatihSection section;
  final MafatihArticle article;
}

String _normalizeTitle(String value) => value
  .toLowerCase()
  .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
  .replaceAll(RegExp('[أإآٱ]'), 'ا')
  .replaceAll('ى', 'ي');

String _plainText(String value) => value
  .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
  .replaceAll(RegExp(r'</(p|div|li|h[1-6])\s*>', caseSensitive: false), '\n\n')
  .replaceAll(RegExp(r'<[^>]*>'), '')
  .replaceAll('&nbsp;', ' ')
  .replaceAll('&amp;', '&')
  .replaceAll('&quot;', '"')
  .replaceAll('&#39;', "'")
  .replaceAll('&lt;', '<')
  .replaceAll('&gt;', '>')
  .trim();

Widget _error(String message, VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: _mfGold, size: 44),
      const SizedBox(height: 12),
      const Text('ما قدرنا نحمّل مكتبة مفاتيح الجنان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _mfMuted, fontSize: 11)),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
    ]),
  ),
);
