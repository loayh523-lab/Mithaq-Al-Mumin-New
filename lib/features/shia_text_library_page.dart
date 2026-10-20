import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mafatih_library_page.dart';

const _shiaPanel = Color(0xFF10251E);
const _shiaGold = Color(0xFFD9B66D);
const _shiaMuted = Color(0xFF9EB5A9);

class ShiaTextLine {
  const ShiaTextLine({required this.index, required this.kind, required this.text});
  final int index;
  final String kind;
  final String text;
  bool get isArabic => kind.toLowerCase() == 'arabic';
  bool get isTranslation => kind.toLowerCase() == 'translation';
  bool get isPersian =>
      RegExp(r'persian|farsi|\bfa\b|فارسي|فارسی', caseSensitive: false).hasMatch(kind) ||
      RegExp(r'[گچپژ]').hasMatch(text);
  bool get isTransliteration => kind.toLowerCase() == 'transliteration';
  factory ShiaTextLine.fromJson(Map<String, dynamic> json) => ShiaTextLine(
    index: json['index'] is int ? json['index'] as int : 0,
    kind: json['kind'] is String ? json['kind'] as String : 'other',
    text: json['text'] is String ? json['text'] as String : '',
  );
}

class ShiaTextEntry {
  const ShiaTextEntry({
    required this.slug,
    required this.title,
    required this.alternateName,
    required this.type,
    required this.sourceUrl,
    required this.lines,
  });
  final String slug;
  final String title;
  final String alternateName;
  final String type;
  final String sourceUrl;
  final List<ShiaTextLine> lines;
  String get displayTitle => alternateName.trim().isNotEmpty ? alternateName : title;
  bool get isSahifa => slug.startsWith('sahifa-sajjadiya-');
  bool get isDayDua =>
      RegExp(r'(sunday|monday|tuesday|wednesday|thursday|friday|saturday)', caseSensitive: false).hasMatch(slug) ||
      title.contains('دعاء يوم') ||
      alternateName.contains('دعاء يوم');
  bool get isZiyara =>
      slug.toLowerCase().contains('ziyarat') ||
      title.contains('زيارة') ||
      alternateName.contains('زيارة');
  bool get isTaqibat =>
      slug.toLowerCase().contains('taqib') ||
      title.contains('تعقيب') ||
      alternateName.contains('تعقيب');
  bool get isMunajat =>
      slug.toLowerCase().contains('munajat') ||
      title.contains('مناجاة') ||
      alternateName.contains('مناجاة');
  bool get isOccasionDua {
    final value = '${slug.toLowerCase()} $title $alternateName';
    return RegExp(r'eid|ramadan|arafah|mubahala|mubahilah|laylat|مناسبة|العيد|رمضان|عرفة|مباهلة').hasMatch(value);
  }
  String get category {
    // Specific text families take priority over broad title heuristics.
    if (isZiyara) return 'الزيارات';
    if (isSahifa) return 'الصحيفة السجادية';
    if (isMunajat) return 'المناجيات الخمس عشرة';
    if (isOccasionDua) return 'أدعية المناسبات';
    if (isTaqibat) return 'تعقيبات';
    if (isDayDua) return 'أدعية الأيام';
    return 'أدعية عامة';
  }
  String get arabicText => lines.where((line) => line.isArabic).map((line) => line.text).join('\n');

  factory ShiaTextEntry.fromJson(Map<String, dynamic> json) => ShiaTextEntry(
    slug: json['slug'] is String ? json['slug'] as String : '',
    title: json['title'] is String ? json['title'] as String : 'دعاء',
    alternateName: json['alternateName'] is String ? json['alternateName'] as String : '',
    type: json['type'] is String ? json['type'] as String : 'dua',
    sourceUrl: json['sourceUrl'] is String ? json['sourceUrl'] as String : '',
    lines: ((json['lines'] as List<dynamic>?) ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>().map(ShiaTextLine.fromJson).toList(),
  );
}

class ShiaTextData {
  const ShiaTextData({required this.entries, required this.sourceProject, required this.license});
  final List<ShiaTextEntry> entries;
  final String sourceProject;
  final String license;
  static Future<ShiaTextData>? _cache;
  static Future<ShiaTextData> load() => _cache ??= _load();

  static Future<ShiaTextData> _load() async {
    final raw = await rootBundle.loadString('assets/shia_duas/shia_duas.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawEntries = decoded['entries'] as List<dynamic>;
    final entries = rawEntries.whereType<Map<String, dynamic>>().map(ShiaTextEntry.fromJson).toList();
    if (entries.isEmpty) throw const FormatException('Shia text collection is empty.');
    final metadata = decoded['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ShiaTextData(
      entries: entries,
      sourceProject: metadata['sourceProject'] is String ? metadata['sourceProject'] as String : 'Shia library JSON',
      license: metadata['license'] is String ? metadata['license'] as String : 'CC0 1.0',
    );
  }
}

class ShiaTextLibraryPage extends StatefulWidget {
  const ShiaTextLibraryPage({super.key, this.initialCategory});
  final String? initialCategory;
  @override State<ShiaTextLibraryPage> createState() => _ShiaTextLibraryPageState();
}

class _ShiaTextLibraryPageState extends State<ShiaTextLibraryPage> {
  final _controller = TextEditingController();
  late Future<ShiaTextData> _future;
  String _query = '';
  String _category = 'أدعية عامة';
  final Set<String> _favoriteSlugs = <String>{};
  static const _favoriteKey = 'shia_favorite_slugs';
  static const _categories = ['أدعية عامة', 'تعقيبات', 'أدعية الأيام', 'أدعية المناسبات', 'الزيارات', 'الصحيفة السجادية', 'المناجيات الخمس عشرة', 'المفضلة'];

  @override void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'أدعية عامة';
    _future = ShiaTextData.load();
    _loadFavorites();
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _favoriteSlugs
          ..clear()
          ..addAll(prefs.getStringList(_favoriteKey) ?? const <String>[]);
      });
    } catch (_) {
      // The library remains usable if local preferences are unavailable.
    }
  }

  Future<void> _toggleFavorite(String slug) async {
    final wasFavorite = _favoriteSlugs.contains(slug);
    setState(() {
      if (wasFavorite) {
        _favoriteSlugs.remove(slug);
      } else {
        _favoriteSlugs.add(slug);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoriteKey, _favoriteSlugs.toList()..sort());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ المفضلة على الجهاز')),
      );
    }
  }

  void _submitSearch() => setState(() => _query = _normalize(_controller.text.trim()));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الأدعية والزيارات')),
    body: FutureBuilder<ShiaTextData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _shiaError(() {
            setState(() { ShiaTextData._cache = null; _future = ShiaTextData.load(); });
          });
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _shiaGold));
        }
        final data = snapshot.data!;
        final filtered = data.entries.where((entry) {
          if (_category == 'المفضلة') {
            if (!_favoriteSlugs.contains(entry.slug)) return false;
          } else if (entry.category != _category) {
            return false;
          }
          if (_query.isEmpty) return true;
          final header = _normalize('${entry.displayTitle} ${entry.title} ${entry.slug}');
          return header.contains(_query) ||
              entry.lines.where((line) => line.isArabic).any((line) => _normalize(line.text).contains(_query));
        }).toList();
        final sahifaCount = data.entries.where((entry) => entry.isSahifa).length;
        return Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _shiaPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _shiaGold.withValues(alpha: .28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('نصوص شيعية للقراءة دون إنترنت', style: TextStyle(color: _shiaGold, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${data.entries.length} نصاً • منها $sahifaCount من الصحيفة السجادية', style: const TextStyle(color: _shiaMuted)),
              const SizedBox(height: 6),
              const Text('النصوص وسطرها العربي مأخوذة من مستودع CC0؛ راجع رابط المصدر لكل نص عند التدقيق.', style: TextStyle(color: _shiaMuted, fontSize: 11, height: 1.5)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
              decoration: InputDecoration(
                hintText: 'ابحث بعنوان أو عبارة عربية...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(onPressed: _submitSearch, icon: const Icon(Icons.arrow_forward_rounded)),
                filled: true, fillColor: _shiaPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(children: [
              ..._categories
            ].map((choice) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(label: Text(choice), selected: _category == choice, onSelected: (_) => setState(() => _category = choice)),
            )).toList()),
          ),
          Expanded(
            child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                        'ماكو نصوص ضمن هذا القسم في مصدر الأدعية الحالي.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _shiaMuted, height: 1.6),
                      ),
                      if (_category == 'تعقيبات') ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: MafatihLibraryPage()),
                          )),
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('افتح مفاتيح الجنان'),
                        ),
                      ],
                    ]),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16), itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final arabicLineCount = entry.lines.where((line) => line.isArabic).length;
                    return Card(
                      color: _shiaPanel,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _shiaGold.withValues(alpha: .15),
                          child: Icon(entry.isSahifa ? Icons.menu_book_rounded : Icons.auto_awesome_rounded, color: _shiaGold),
                        ),
                        title: Text(entry.displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${entry.isSahifa ? 'الصحيفة السجادية' : 'دعاء / زيارة'} • $arabicLineCount أسطر عربية', style: const TextStyle(color: _shiaMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: _favoriteSlugs.contains(entry.slug)
                                  ? 'إزالة من المفضلة'
                                  : 'إضافة للمفضلة',
                              onPressed: () => _toggleFavorite(entry.slug),
                              icon: Icon(
                                _favoriteSlugs.contains(entry.slug)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _favoriteSlugs.contains(entry.slug)
                                    ? _shiaGold
                                    : _shiaMuted,
                              ),
                            ),
                            const Icon(Icons.chevron_left_rounded, color: _shiaGold),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ShiaTextReaderPage(entry: entry)),
                        )),
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text('المصدر: ${data.sourceProject} • ${data.license}', textAlign: TextAlign.center, style: const TextStyle(color: _shiaMuted, fontSize: 10)),
          ),
        ]);
      },
    ),
  );
}

class ShiaTextReaderPage extends StatefulWidget {
  const ShiaTextReaderPage({super.key, required this.entry});
  final ShiaTextEntry entry;
  @override State<ShiaTextReaderPage> createState() => _ShiaTextReaderPageState();
}

class _ShiaTextReaderPageState extends State<ShiaTextReaderPage> {
  String _display = 'العربي';
  double _fontSize = 23;
  bool _focusMode = false;

  Future<void> _toggleFocusMode() async {
    final next = !_focusMode;
    setState(() => _focusMode = next);
    await SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    if (_focusMode) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  List<ShiaTextLine> get _visibleLines {
    final source = widget.entry.lines;
    if (_display == 'العربي') return source.where((line) => line.isArabic).toList();
    if (_display == 'الفارسي') return source.where((line) => line.isPersian && !line.isArabic).toList();
    if (_display == 'العربي والترجمة') {
      return [
        ...source.where((line) => line.isArabic),
        ...source.where((line) => line.isTranslation && !line.isPersian),
      ];
    }
    if (_display == 'العربي والفارسي') {
      return [
        ...source.where((line) => line.isArabic),
        ...source.where((line) => line.isPersian && !line.isArabic),
      ];
    }
    return source.toList();
  }

  @override Widget build(BuildContext context) {
    final lines = _visibleLines;
    final allText = lines.map((line) => line.text).join('\n');
    return Scaffold(
      appBar: _focusMode ? null : AppBar(
        title: Text(widget.entry.displayTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'وضع القراءة الخاشعة',
            onPressed: _toggleFocusMode,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
          IconButton(
          tooltip: 'نسخ النص الظاهر',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: allText));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص الظاهر')));
          },
          icon: const Icon(Icons.copy_rounded),
        )],
      ),
      floatingActionButton: _focusMode
        ? FloatingActionButton.small(onPressed: _toggleFocusMode, tooltip: 'إنهاء وضع القراءة الخاشعة', child: const Icon(Icons.close_rounded))
        : null,
      body: Column(children: [
        if (!_focusMode) Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                'العربي', 'الفارسي', 'العربي والفارسي', 'العربي والترجمة', 'كل الأسطر'
              ].map((choice) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 7),
                child: ChoiceChip(
                  label: Text(choice),
                  selected: _display == choice,
                  onSelected: (_) => setState(() => _display = choice),
                ),
              )).toList()),
            ),
            Row(children: [
              const Icon(Icons.text_fields_rounded, color: _shiaGold),
              Expanded(child: Slider(value: _fontSize, min: 16, max: 34, divisions: 9, label: _fontSize.round().toString(), onChanged: (v) => setState(() => _fontSize = v), activeColor: _shiaGold)),
              Text('${_fontSize.round()}', style: const TextStyle(color: _shiaMuted)),
            ]),
          ]),
        ),
        Expanded(child: lines.isEmpty
          ? const Center(child: Text('لا توجد أسطر ضمن هذا الخيار.', style: TextStyle(color: _shiaMuted)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _shiaPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _shiaGold.withValues(alpha: .28))),
                  child: Text(widget.entry.displayTitle, textAlign: TextAlign.center, style: const TextStyle(color: _shiaGold, fontSize: 22, fontWeight: FontWeight.w800, height: 1.6)),
                ),
                ...lines.map((line) {
                  final arabic = line.isArabic;
                  final persian = line.isPersian;
                  final rtl = arabic || persian;
                  final translation = line.isTranslation;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText(
                      line.text,
                      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: rtl ? TextAlign.justify : TextAlign.start,
                      style: TextStyle(
                        fontSize: rtl ? _fontSize : _fontSize * .75,
                        height: rtl ? 2.0 : 1.6,
                        color: rtl ? Colors.white : (translation ? _shiaMuted : Colors.white70),
                      ),
                    ),
                  );
                }),
                const Divider(color: Color(0x334A7562)),
                const Text('هذا النص منقول من سجلّ البيانات المشار إليه أدناه. قد تختلف الضبطات أو ترتيب الفقرات بين الطبعات.', style: TextStyle(color: _shiaMuted, height: 1.7, fontSize: 11)),
                if (widget.entry.sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SelectableText('المصدر: ${widget.entry.sourceUrl}', textDirection: TextDirection.ltr, style: const TextStyle(color: _shiaMuted, fontSize: 10)),
                ],
              ],
            )),
      ]),
    );
  }
}

String _normalize(String value) => value
  .toLowerCase()
  .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
  .replaceAll(RegExp('[أإآٱ]'), 'ا')
  .replaceAll('ى', 'ي');

Widget _shiaError(VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: _shiaGold, size: 42),
      const SizedBox(height: 12),
      const Text('ما قدرنا نحمّل مكتبة الأدعية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('قد يكون ملف المحتوى غير موجود في هذه النسخة. أعد المحاولة أو ثبّت نسخة مبنية بملفات البيانات.', textAlign: TextAlign.center, style: TextStyle(color: _shiaMuted, height: 1.6)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
    ]),
  ),
);
